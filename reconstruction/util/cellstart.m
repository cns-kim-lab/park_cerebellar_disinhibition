function cellstart(coord)
    addpath /data/lrrtm3_wt_code/matlab/
    find_rsl = lrrtm3_find_vol_seg_at_coord(coord, '');

    if isempty(find_rsl) 
        fprintf('no segments at this coordinates\n');
        return
    end

    vol_name = [];
    segment = [];
    for idx=1:size(find_rsl, 2)
        net_prefix = strtok(find_rsl(idx).vol_id, '_');
        if strcmpi(net_prefix, 'C1a')
            vol_name = find_rsl(idx).vol_id;
            segment = find_rsl(idx).segment;
        end
    end

    if isempty(vol_name)    %C1a not found, put something else
        vol_name = find_rsl(1).vol_id;
        segment = find_rsl(1).segment;
    end

    process_path = '/data/lrrtm3_wt_code/process/cellstart';
    log_path = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_acc_process/';
    

    cmd = sprintf('%s %s "%s" "%s" "%d"', process_path, get_endpoint(), 'jwshin', vol_name, segment);
    output = execute_with_logging(log_path, 'cellstart', cmd);
    fprintf('%s', output);
end
