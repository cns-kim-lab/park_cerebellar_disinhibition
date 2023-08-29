%crop and save channel cube (from input tile)
% job_ridx : row index of chan_joblist
function chan_joblist = cropNsave_chan_cube(cfg, chan_joblist, job_ridx)
    if ~isdeployed
        addpath('/volume_1/research/jwgim/matlab_code/hdf5_ref/');
    end
    
    if strcmpi(chan_joblist{job_ridx,4}, 'READY') == 0
        disp('@this job already done');
        return
    end
    
    chan_joblist{job_ridx,4} = 'ING';
    chan_joblist{job_ridx,5} = datetime('now');
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [chan_path,~] = get_cfg(cfg, 'channel_cube_save_path');
    [chan_naming,~] = get_cfg(cfg, 'channel_cube_naming');
    [chan_tile,~] = get_cfg(cfg, 'chan_tile');
    
    startp = chan_joblist{job_ridx,2};
    endp = chan_joblist{job_ridx,3};
    savename = sprintf([default_path chan_path chan_naming '.h5'], chan_joblist{job_ridx,1});
    num_elem = endp - startp + 1;
    cube = h5read(chan_tile, '/main', startp, num_elem);
    hdf5write(savename, '/main', cube);
    chan_joblist{job_ridx,4} = 'DONE';
    chan_joblist{job_ridx,6} = datetime('now');
    