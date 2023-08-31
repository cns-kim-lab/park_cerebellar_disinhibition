if exist('jobconfig_path', 'var') < 1
    disp('@jobconfig_path needed');
    return
end

if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
end

%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);
%chan: cubeidx, start, end (global), cube_size, sts
[chan_coordinate_tbl, ~] = create_coordinate_table(jobcfg); 

%get config info
[omni_root,~] = get_cfg(jobcfg, 'omni_create_path');
[net_prefix,~] = get_cfg(jobcfg, 'omni_net_prefix');

meta_filename = 'projectMetadata.yaml';
metao_filename = 'projectMetadata.yaml.old';
meta_temp_filename = 'projectMetadata.yaml.temp';

[row,~] = size(chan_coordinate_tbl);
idx_list = 1:row;
for ridx = idx_list
    disp([char(datetime('now')) ' job ' num2str(ridx) '/' num2str(row)]);

    prj_exist = check_omni_prj_exist(jobcfg, chan_coordinate_tbl, ridx);  
    if prj_exist ~= 1
        disp(['@omni project not exist (rid=' num2str(ridx) ')']);
        chan_coordinate_tbl{ridx,5} = 'MISSING';
        continue
    end
        
    cube_idx = chan_coordinate_tbl{ridx, 1};
    startp = chan_coordinate_tbl{ridx, 2} .* [1,1,4];
    cube_size = chan_coordinate_tbl{ridx, 4};
    
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
