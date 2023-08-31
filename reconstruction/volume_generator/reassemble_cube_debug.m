function [cube, valid] = reassemble_cube_debug(cube, fwd_tbl, fwd_ridx, chan_fr, chan_to, startp, fwd_outname)
    valid = 1;
    
    crop_fr = fwd_tbl{fwd_ridx,6} + (startp -fwd_tbl{fwd_ridx,4});
    crop_to = min(chan_to, fwd_tbl{fwd_ridx,5}) -fwd_tbl{fwd_ridx,4} +fwd_tbl{fwd_ridx,6};
    
    append_fr = startp -chan_fr +1;
    append_to = min(chan_to, fwd_tbl{fwd_ridx,5}) -chan_fr +1;
    
    append_fr = [append_fr 1];
    append_to = [append_to 3];
    
    [~,dims,~] = get_hdf5_size(fwd_outname, '/main');

    if sum([1 1 1 1] > [crop_fr 1]) > 0 || sum(dims < [crop_to 3]) > 0
        fprintf('@reassemble source coordinate invalid\n');
        fprintf('@from %s, %d,%d,%d~%d,%d,%d but size is %d,%d,%d\n', ...
            fwd_outname, crop_fr, crop_to, dims(1:3));
        valid = 0;
    end
    csize = size(cube);
    if sum([1 1 1 1] > append_fr) > 0 || sum(csize < append_to) > 0
        fprintf('@reassemble target coordinate invalid\n');
        fprintf('@(%d,%d,%d~%d,%d,%d but size is %d,%d,%d)\n', ...
            append_fr(1:3), append_to(1:3), csize(1:3));        
        valid = 0;
    end
