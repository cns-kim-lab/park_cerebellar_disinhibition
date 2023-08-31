function idx = get_fwd_ridx_by_startpoint(fwd_tbl, startp)
    [row,~] = size(fwd_tbl);
    for i=1:row
        rsl = int32( (fwd_tbl{i,4} <= startp) & (fwd_tbl{i,5} >= startp) );
        if nnz(rsl) == 3
            idx = i;
            return
        end
    end
    idx = 0;