%compute start and end point for chan cube
function [startp, endp] = get_start_end_point_of_chan(cubeidx, start_cubeidx, cube_size, overlap, h5_size)
    minp = [1,1,1];
    startp = max( cube_size .*(cubeidx -start_cubeidx) -(overlap .* (cubeidx-1)) +cube_size.*(start_cubeidx-1) +[1,1,1], minp );
    endp = min( startp+cube_size-1, h5_size );
