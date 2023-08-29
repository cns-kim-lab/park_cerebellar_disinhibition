function ridx = get_idle_gpu_in_sts_table(sts_table)
    [row,~] = size(sts_table);
    for iter=1:row
        if strcmpi( sts_table{iter,5}, 'IDLE' )
            ridx = iter;
            return
        end    
    end
    ridx = 0;
    