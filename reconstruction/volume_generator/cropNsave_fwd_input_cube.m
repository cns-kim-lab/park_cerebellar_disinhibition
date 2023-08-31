%crop and save fwd input cube (from input tile)
% job_ridx : row index of chan_joblist
function fwd_joblist = cropNsave_fwd_input_cube(cfg, fwd_joblist, job_ridx)
    if ~isdeployed
        addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
    end
    
    if strcmpi(fwd_joblist{job_ridx,4}, 'READY') == 0
        disp('@this job already done');
        return
    end
    
    fwd_joblist{job_ridx,4} = 'ING';
    fwd_joblist{job_ridx,5} = datetime('now');
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [fwd_path,~] = get_cfg(cfg, 'fwd_input_cube_save_path');
    [fwd_input_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    [input_tile,~] = get_cfg(cfg, 'input_tile');
    
    startp = fwd_joblist{job_ridx,2};
    endp = fwd_joblist{job_ridx,3};
    savename = sprintf([default_path fwd_path fwd_input_naming '.h5'], fwd_joblist{job_ridx,1});
    
    %170111 add
    if exist(savename, 'file')
        disp(['fwd_input exist, skip cropping(cubeidx=', num2str(fwd_joblist{job_ridx,1}), ')']);
        return
    end
    
    cube = get_hdf5_file(input_tile, '/main', startp, endp);
    hdf5write(savename, '/main', cube);
    
    system(['chmod g+w ' savename]);
    