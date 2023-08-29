function ncube = compute_number_of_output_cube(cfg, job_type)
    if ~isdeployed
        addpath('/volume_1/research/jwgim/matlab_code/hdf5_ref/');
    end
    
    [input_tile_path,~] = get_cfg(cfg, 'input_tile');
    [~,tile_size,~] = get_hdf5_size(input_tile_path, '/main');  %end point
    
    [set_idx,valid] = get_cfg(cfg, 'start_cube_idx');
    set_idx = str2num(set_idx);
    if valid == 1
        [cube_size,~] = get_cfg(cfg, 'size_of_output_cube');
        [overlap,~] = get_cfg(cfg, 'channel_cube_overlap_pixel');
        cube_size = str2num(cube_size);
        overlap = str2num(overlap);
        minp = [1,1,1];
        crop_fr = max( -(overlap .* (set_idx-1)) +cube_size.*(set_idx-1) +[1,1,1], minp );
    else
        [crop_fr,~] = get_cfg(cfg, 'crop_tile_from');   %start point    
        crop_fr = str2num(crop_fr);
    end
    
    if strcmpi(job_type, 'channel')
        [ncube, ~] = compute_number_of_chan_output_cube(cfg, crop_fr, tile_size);
    else
        ncube = compute_number_of_fwd_output_cube(cfg, crop_fr, tile_size);
    end
