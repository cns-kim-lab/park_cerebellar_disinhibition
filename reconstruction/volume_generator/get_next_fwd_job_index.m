function idx = get_next_fwd_job_index(fwdlist)
    [row,~] = size(fwdlist);
    for iter=1:row
        if strcmpi(fwdlist{iter,4}, 'READY')
            idx = iter;
            return
        end
    end
    idx = row+1;
    