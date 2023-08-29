function idx = get_start_cube_idx(cfg, job_type, startp, endp)
    [set_idx,valid] = get_cfg(cfg, 'start_cube_idx');
    set_idx = str2num(set_idx);
    %if start_cube_idx exist, don't compute start cube idx
    if strcmpi(job_type, 'channel') && valid == 1   
        idx = set_idx;
        return
    end
    
    %need to compute start cube idx 
    if valid == 1 %invalidate crop_tile_from field if start_cube_idx  exist
        [cube_size,~] = get_cfg(cfg, 'size_of_output_cube');
        [overlap,~] = get_cfg(cfg, 'channel_cube_overlap_pixel');
        cube_size = str2num(cube_size);
        overlap = str2num(overlap);
        minp = [1,1,1];
        crop_fr = max( -(overlap .* (set_idx-1)) +cube_size.*(set_idx-1) +[1,1,1], minp );    
    else
        [crop_fr,~] = get_cfg(cfg, 'crop_tile_from');    
        crop_fr = str2num(crop_fr);
    end
        
    if isempty(startp)
        startp = [1,1,1];
    end
    if isempty(endp)
        endp = max(crop_fr-1, [1,1,1]);
    end   
    
    if strcmpi(job_type, 'channel')        
        [lack_cube,ncube] = compute_number_of_chan_output_cube(cfg, startp, endp);    
        idx = double(ncube+1);
        idx(lack_cube==ncube) = idx(lack_cube==ncube) +1;
    else
        ncube = compute_number_of_fwd_output_cube(cfg, startp, endp);        
        ncube(ncube<1) = 1;
        idx = double(ncube);
    end
