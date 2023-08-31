function compare_recover(task_id)
    process_path = '/data/lrrtm3_wt_code/process/compare_recover';
    log_path = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_acc_process/';
    
    cmd = sprintf('%s %s %d', process_path, get_endpoint(), task_id);
    [~,output] = system(cmd);
    fprintf('%s', output);
    
    [year,month,day] = ymd(datetime());
    fname = sprintf('%scompare_recover_log_%04d_%02d_%02d', log_path, year, month, day);
    fid = fopen(fname, 'a');    
    fprintf(fid, '%s\n', datetime());    
    fprintf(fid, '%s\n', output);    
    fclose(fid);
end
