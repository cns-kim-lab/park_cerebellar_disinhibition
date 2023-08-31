function cube = reassemble_cube(cube, fwd_tbl, fwd_ridx, chan_fr, chan_to, startp, fwd_outname)
    crop_fr = fwd_tbl{fwd_ridx,6} + (startp -fwd_tbl{fwd_ridx,4});
    crop_to = min(chan_to, fwd_tbl{fwd_ridx,5}) -fwd_tbl{fwd_ridx,4} +fwd_tbl{fwd_ridx,6};
    
    append_fr = startp -chan_fr +1;
    append_to = min(chan_to, fwd_tbl{fwd_ridx,5}) -chan_fr +1;
    
    append_fr = [append_fr 1];
    append_to = [append_to 3];
    
    partial_data = get_hdf5_file(fwd_outname, '/main', [crop_fr 1], [crop_to 3]);
    cube(append_fr(1):append_to(1),append_fr(2):append_to(2),append_fr(3):append_to(3),:) = partial_data;
