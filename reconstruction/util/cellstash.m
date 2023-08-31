function cellstash(survive_this, stash_this)
    process_path = '/data/lrrtm3_wt_code/process/cellstash';
    log_path = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_acc_process/';
    
    cmd = sprintf('%s %s %d %d', process_path, get_endpoint(), stash_this, survive_this);
    output = execute_with_logging(log_path, 'cellstash', cmd);
    fprintf('%s', output);
end
