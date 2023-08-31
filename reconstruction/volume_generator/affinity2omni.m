if exist('jobconfig_path', 'var') < 1
    disp('@jobconfig_path needed');
    return
end

if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/');
    addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
    addpath('/data/research/jwgim/matlab_code/watershed_new/');
end

%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);
[omni_create_path,~] = get_cfg(jobcfg, 'omni_create_path');
[omni_prefix,~] = get_cfg(jobcfg, 'omni_net_prefix');

%chan: cubeidx, start, end (global), cube_size
%fwd : cubeidx, global st-en, global valid st-en, local valid st-en, cube size
[chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(jobcfg); 

[row,~] = size(chan_coordinate_tbl);
% wshigh = 0.850; %for old unet
wshigh = 0.999; %for RS unet
wslow = 0.01;
wsdust = 500;  
wsdustlow = 0.001;
wswidth = 256;
wsthread = 4;
ws_param_set = struct('high', wshigh, 'low', wslow, 'dust', wsdust, ...
    'dust_low', wsdustlow, 'threads', wsthread, 'width', wswidth);
seg_save = 1;

idx_list = 1:row;
for ridx = idx_list
    time_ = sprintf('%s', datetime('now'));
    disp([time_ ' job ' num2str(ridx) '/' num2str(row)]);
    prj_exist = check_omni_prj_exist(omni_create_path, omni_prefix, chan_coordinate_tbl, ridx);  
    if prj_exist == 1
        chan_coordinate_tbl{ridx,5} = 'DONE'; 
        disp(['this job already done (' num2str(ridx) ')']);
        continue
    end    
    
    %get assembled cube
    [cube, valid] = get_affinity_cube(jobcfg, ridx, chan_coordinate_tbl, fwd_coordinate_tbl);    
    if valid ~= 1
        return
    end
    %normalization (histogram flaten)
%     cube = affinityNorm(cube, 'matrix'); %for old unet

    %affinity to segment
    cubeidx = chan_coordinate_tbl{ridx,1};
    fname = sprintf('%sseg_x%dy%dz%d.h5', omni_create_path, cubeidx);
    [~,~,~] = aff2seg_detail(cube, 'matrix', fname, seg_save, ws_param_set);   %change function

    %make omni project
    create_omni_script(jobcfg, fname, chan_coordinate_tbl, ridx);
end
create_batch_script(jobcfg, 64, chan_coordinate_tbl, jobconfig_path);
% create_serial_execute_script(jobcfg, [64], idx_list, [omni_create_path 'ctl_make_']);
% create_serial_execute_script(jobcfg, [64, 24], idx_list, [omni_create_path 'ctl_make_']);

