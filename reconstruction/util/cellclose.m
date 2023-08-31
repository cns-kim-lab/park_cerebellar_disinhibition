function cellclose(cell_ids)
     process_path = '/data/lrrtm3_wt_code/process/cellclose';
     log_path = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_acc_process/';

    for cell_id=cell_ids
        cmd = sprintf('%s %s %d', process_path, get_endpoint(), cell_id);
        output = execute_with_logging(log_path, 'cellclose', cmd);
        fprintf('%s', output);    
    end
end
