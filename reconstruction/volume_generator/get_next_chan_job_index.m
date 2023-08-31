function idx = get_next_chan_job_index(chanlist)
    [row,~] = size(chanlist);
    for iter=1:row
        if strcmpi(chanlist{iter,4}, 'READY')
            idx = iter;
            return
        end
    end
    idx = row+1;