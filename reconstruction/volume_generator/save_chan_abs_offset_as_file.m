function save_chan_abs_offset_as_file(cfg, chan_joblist)
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [chan_path,~] = get_cfg(cfg, 'channel_cube_save_path');
    [chan_abs_filename,~] = get_cfg(cfg, 'channel_cube_absinfo');
    
    fid = fopen([default_path chan_path chan_abs_filename], 'w');
    [row, ~] = size(chan_joblist);
    for iter=1:row
        fprintf(fid, 'cubeid %3d %3d %3d absoffset %5d %5d %5d\n', chan_joblist{iter,1}, chan_joblist{iter,2});
    end
    
    fclose(fid);
