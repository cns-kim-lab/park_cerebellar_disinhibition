function completed = is_complete_job(job_list)
    fwd_cnt = 1;
    [row,~] = size(job_list);
    for iter=1:row
        if strcmpi( job_list{iter,4}, 'READY' )
            completed = 'PROCESSING';
            return
        elseif strcmpi( job_list{iter,4}, 'ING' )
            completed = 'PROCESSING';
            return
        end
        if strcmpi( job_list{iter,4}, 'FWD' )
            fwd_cnt = fwd_cnt+1;
        end
    end
    
    %only fwd left
    if fwd_cnt-1 > 0
        completed = 'FORWARDING';
        return
    end
     
    completed = 'COMPLETED';
