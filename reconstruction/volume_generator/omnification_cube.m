if exist('jobconfig_path', 'var') < 1
    disp('@jobconfig_path needed');
    return
end

if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/');
    addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
    addpath('/data/research/jwgim/matlab_code/watershed_new/');
end

if ~isdeployed
    joblist_chan_path = '/job_table_chan.txt';
else
    joblist_chan_path = ['/job_table_chan_' phase '.txt'];
end

%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);
[omni_create_path,~] = get_cfg(jobcfg, 'omni_create_path');
[job_default_path,~] = get_cfg(jobcfg, 'job_default_path');
[netname,~] = get_cfg(jobcfg, 'netname');
[net_prefix,~] = get_cfg(jobcfg, 'omni_net_prefix');

%chan: cubeidx, start, end (global), cube_size
%fwd : cubeidx, global st-en, global valid st-en, local valid st-en, cube size
[chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(jobcfg); 
job_list_fullpath_chan = [job_default_path netname joblist_chan_path];
%save joblist as file
format = 'id: %5d %5d %5d, start: %5d %5d %5d, end: %5d %5d %5d, size: %5d %5d %5d, sts: %s\n';
save_joblist_as_file(job_list_fullpath_chan, format, chan_coordinate_tbl);

[ws_high,valid] = get_cfg(jobcfg, 'watershed_high');
if valid == 1
    ws_param_set = struct('high', str2num(ws_high), 'low', 0.01, 'dust', 500, ...
        'dust_low', 0.001, 'threads', 4, 'width', 256); 
else
    ws_param_set = struct('high', 0.999, 'low', 0.01, 'dust', 500, ...
        'dust_low', 0.001, 'threads', 4, 'width', 256); 
end
norm_flag = 0;
[normval,valid] = get_cfg(jobcfg, 'affinity_normalization');
if valid == 1 && strcmpi(normval, 'sort')
    norm_flag = 1;  
    disp('affinity normalization: SORT');
elseif valid==1 && strcmpi(normval, 'shift')
    norm_flag = 2;
    disp('affinity normalization: SHIFT');
else
    disp('affinity normalization: OFF');
end

[row,~] = size(chan_coordinate_tbl);
idx_list = 1:row;
for ridx = idx_list
    time_ = sprintf('%s', datetime('now'));
    disp([time_ ' job ' num2str(ridx) '/' num2str(row)]);
    prj_exist = check_omni_prj_exist(omni_create_path, net_prefix, chan_coordinate_tbl, ridx);  
    if prj_exist == 1
        chan_coordinate_tbl{ridx,5} = 'DONE'; 
        disp(['this job already done (' num2str(ridx) ')']);
        save_tbl_as_file(job_list_fullpath_chan, format, chan_coordinate_tbl);
        continue
    end    
    
    cubeidx = chan_coordinate_tbl{ridx,1};
    seg_fname = sprintf('%sseg_x%dy%dz%d.h5', omni_create_path, cubeidx);
    %check existence of seg file
    if exist(seg_fname, 'file') < 1    
        %get assembled cube
        [cube, valid] = get_affinity_cube(jobcfg, ridx, chan_coordinate_tbl, fwd_coordinate_tbl);   
        if valid ~= 1
            disp(['can not find needed cube (' num2str(ridx) '), pass']);
            chan_coordinate_tbl{ridx,5} = 'PASS';
            save_tbl_as_file(job_list_fullpath_chan, format, chan_coordinate_tbl);
            continue
        end
        if norm_flag == 1   %normalization (histogram flaten)             
            cube = affinityNorm(cube, 'matrix'); %for old unet
        elseif norm_flag == 2   %histogram shift 
            cube = max(0.0, (cube - 0.001));    
        end
        %affinity to segment (WS)
        [~,~,~] = aff2seg_detail(cube, 'matrix', seg_fname, 1, ws_param_set);   %change function
    end
    
    %make omni project script
    create_omni_script(jobcfg, seg_fname, chan_coordinate_tbl, ridx);    
       
    %watershed to omnivolume (omni project)
    syscmd = sprintf('%smake_x%dy%dz%d.sh', omni_create_path, cubeidx);
    disp(syscmd);
    system(syscmd);
    syscmd = sprintf('rm -rf %smake_x%dy%dz%d.sh', omni_create_path, cubeidx);
    disp(syscmd);
    system(syscmd);
                          
    ret = omni_postprocess_cube(chan_coordinate_tbl, ridx, omni_create_path, net_prefix);  %merge yaml file 
    if ret ~= 1 
        chan_coordinate_tbl{ridx,5} = 'DONE';
    end
    save_tbl_as_file(job_list_fullpath_chan, format, chan_coordinate_tbl);
end

%%
function failed = omni_postprocess_cube(chan_tbl, ridx, omni_root, net_prefix)
    failed = 0;
    meta_filename = 'projectMetadata.yaml';
    metao_filename = 'projectMetadata.yaml.old';
    meta_temp_filename = 'projectMetadata.yaml.temp';

    prj_exist = check_omni_prj_exist(omni_root, net_prefix, chan_tbl, ridx);  
    if prj_exist ~= 1
        disp(['@omni project not exist (rid=' num2str(ridx) ')']);
        chan_tbl{ridx,5} = 'MISSING';
        failed = 1;
        return
    end
        
    cube_idx = chan_tbl{ridx, 1};
    startp = chan_tbl{ridx, 2} .* [1,1,4];
    cube_size = chan_tbl{ridx, 4};
    
    omni_prj_path = sprintf('%sz%02d/y%02d/Net_%s_x%02d_y%02d_z%02d_st_%04d_%04d_%04d_sz_%d_%d_%d.omni.files', ...
        omni_root, cube_idx(3), cube_idx(2), net_prefix, cube_idx, startp, cube_size);
    
    fname = meta_filename;
    for iter=1:2    %1=.yaml, 2=.yaml.old
        chan_meta_path = sprintf('%sz%02d/y%02d/channel_info/x%02d_y%02d_z%02d/%s', '/data/lrrtm3_wt_omnivol/', ...
            cube_idx(3), cube_idx(2), cube_idx, fname); 
        seg_meta_path = [omni_prj_path '/' fname];
        save_meta_path = [omni_prj_path '/' meta_temp_filename];    
        merge_metadatafile(chan_meta_path, seg_meta_path, save_meta_path);

        syscmd = ['mv ' save_meta_path ' -f ' seg_meta_path];   %add -force option to prevent asking chmod overwrite
        disp(syscmd);
        system(syscmd);        
        syscmd = ['chmod 660 ' seg_meta_path]; %%chmod before mv to prevent asking chmod overwrite
        disp(syscmd);
        system(syscmd);
 
        fname = metao_filename; %chg file name (.yaml to .yaml.old)
    end
    syscmd = ['chown :kimlab_tracer ' omni_prj_path '/*yaml*'];
    disp(syscmd);
    system(syscmd);
end

%%
function save_tbl_as_file(filename, format, cellarray)
    fid = fopen(filename, 'w'); %overwirte
    [row, ~] = size(cellarray);
    for iter=1:row
        fprintf(fid, format, cellarray{iter,:});
    end
    fclose(fid);
end
