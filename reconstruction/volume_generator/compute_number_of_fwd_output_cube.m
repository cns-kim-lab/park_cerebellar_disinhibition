function ncube = compute_number_of_fwd_output_cube(cfg, startp, endp)
    [cube_size,~] = get_cfg(cfg, 'size_of_output_cube');
    cube_size = str2num(cube_size);
    
    area = endp-startp+1;         
    
    if prod(area(:)) < 2
        ncube = [0,0,0];
        return
    end
    
    %compute number of output cube 
    ncube = single(area) ./ single(cube_size);
    mod_rsl = mod( area, cube_size );
    mod_rsl = mod_rsl ./ mod_rsl;
    mod_rsl(isnan(mod_rsl)>0) = 0;
    ncube = floor(ncube) + mod_rsl;
    ncube = uint32(ncube);
