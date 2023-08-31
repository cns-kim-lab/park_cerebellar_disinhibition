function [ncube, nfullcube] = compute_number_of_chan_output_cube(cfg, startp, endp)
    [cube_size,~] = get_cfg(cfg, 'size_of_output_cube');
    [overlap,~] = get_cfg(cfg, 'channel_cube_overlap_pixel');
    
    cube_size = str2num(cube_size);
    overlap = str2num(overlap);
        
    area = endp-startp+1;   
    cube_exist = min(cube_size, area) >= cube_size;
    
    ncube = single(uint32(area-cube_size)) ./ single(cube_size-overlap);
    mod_rsl = mod( area, cube_size-overlap );
    mod_rsl(mod_rsl>0) = 1;
    nfullcube = floor(ncube) + cube_exist;
    ncube = floor(ncube) + mod_rsl + cube_exist;
