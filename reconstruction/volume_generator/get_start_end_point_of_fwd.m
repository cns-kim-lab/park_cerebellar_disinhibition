%compute start and end point for fwd cube
function [startp, endp] = get_start_end_point_of_fwd(cubeidx, start_cubeidx, cube_size, fov, h5_size)
    overhead = int32( (fov-1)/2 +1);
    overhead = double(overhead);  
    %right equation
    minp = [1,1,1];
    startp = max(cube_size .* (cubeidx-start_cubeidx) -overhead +cube_size.*(start_cubeidx-1) +[1,1,1], minp);
    endp = min(cube_size .* (cubeidx-start_cubeidx) +overhead +cube_size.*start_cubeidx, h5_size);
  