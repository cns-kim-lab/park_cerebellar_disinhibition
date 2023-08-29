function [fwdlist, chanlist] = check_previous_job_by_file_exist(cfg, fwdlist, chanlist)
    %get cfg
    [fwd_output_path,~] = get_cfg(cfg, 'fwd_result_path');
    [fwd_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [chan_path,~] = get_cfg(cfg, 'channel_cube_save_path');
    [chan_naming,~] = get_cfg(cfg, 'channel_cube_naming');
    
    [rfwd,~] = size(fwdlist);
    for iter=1:rfwd
        fullpath = sprintf([fwd_output_path fwd_naming '_prob.h5'], fwdlist{iter,1});
        if exist(fullpath, 'file')  %if exist fwd output, pass this job
            fwdlist{iter,4} = 'DONE';
        end
    end
    
    [rchan,~] = size(chanlist);
    for iter=1:rchan
        fullpath = sprintf([default_path chan_path chan_naming '.h5'], chanlist{iter,1});
        if exist(fullpath, 'file')  %if exist chan h5 file, pass this job
            chanlist{iter,4} = 'DONE';
        end
    end

