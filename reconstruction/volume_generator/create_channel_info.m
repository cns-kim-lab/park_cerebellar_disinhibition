if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/');
    addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
end

% jobconfig_path = '/data/research/jwgim/cnn_pkg/kaffe/test/14_registered_lrrtm3_parallel/chan_cfg.txt'; 

%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);
[omni_create_path,~] = get_cfg(jobcfg, 'omni_create_path');

%chan: cubeidx, start, end (global), cube_size
[chan_coordinate_tbl, ~] = create_coordinate_table(jobcfg); 
[row,~] = size(chan_coordinate_tbl);

script_fname = [omni_create_path 'makechan.sh'];
idx_list = 1:row;
for ridx = idx_list
    time_ = sprintf('%s', datetime('now'));
    disp([time_ ' job ' num2str(ridx) '/' num2str(row)]);      
    
    %make channel_info directory
    cube_idx = chan_coordinate_tbl{ridx,1};
    channel_ppath = sprintf('%sz%02d/y%02d/channel_info', omni_create_path, cube_idx(3), cube_idx(2));
    channel_cpath = sprintf('%s/x%02d_y%02d_z%02d', channel_ppath, cube_idx);
    create_directory_recursively(channel_cpath);
        
    %check channel info exist
    job_idx = chan_coordinate_tbl{ridx,1};
    channel_info_path = sprintf('%sz%02d/y%02d/channel_info/x%02d_y%02d_z%02d/channels', omni_create_path, job_idx(3),job_idx(2),job_idx);
    if exist(channel_info_path, 'dir') == 7     %already exist
        continue
    end    
    
    disp(['make prj: ' channel_info_path]);
    %make script
    create_omni_script_for_channelprj(jobcfg, chan_coordinate_tbl, ridx, script_fname);

    %execute script  
    cmd = ['chmod ug+wx ' script_fname];
    disp(cmd);
    system(cmd); 
    cmd = script_fname;
    disp(cmd);
    system(cmd);

    %rm script
    cmd = ['rm ' script_fname];
    disp(cmd);
    system(cmd);

end
