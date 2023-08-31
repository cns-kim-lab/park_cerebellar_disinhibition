function [fwd_cnt, chan_cnt] = get_cnt_remain_job(fwdlist, chanlist)
    [row,~] = size(fwdlist);    
    fwd_cnt = 0;
    for iter=1:row    % count not finished job
        if strcmpi( fwdlist{iter,4}, 'DONE' ) ~= 1
            fwd_cnt = fwd_cnt +1;
        end
    end
    
    [row,~] = size(chanlist);
    chan_cnt = 0;
    for iter=1:row
        if strcmpi( chanlist{iter,4}, 'DONE' ) ~= 1
            chan_cnt = chan_cnt +1;
        end
    end
    