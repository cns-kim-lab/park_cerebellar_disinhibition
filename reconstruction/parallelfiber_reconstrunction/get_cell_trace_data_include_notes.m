function trace_data = get_cell_trace_data_include_notes(cell_id, allow_status)
    if isempty(allow_status)
        allow_status = [0 3];
    end
    status_str = [];
    for iter=1:numel(allow_status)
        status_str = sprintf('%s,%d',status_str, allow_status(iter));
    end
    status_str(1) = [];
    
    con_info = get_dbinfo();
    h_sql = mysql('open', con_info.host, con_info.user, con_info.passwd);
    rtn = mysql(h_sql, ['use ' con_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: get_cell_trace_data: DB open failed (host:%s, id:%s)', ...
            con_info.host, con_info.user), 1);
        return
    end
    
    query = ['SELECT t.id, t.status, v.id AS volid, v.vx, v.vy, v.vz, ' ... 
        'concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name, c.segments, ' ...
        't.notes ' ...
        'FROM tasks t ' ...
        'INNER JOIN volumes v ON v.id=t.volume_id ' ...
        'INNER JOIN consensuses c ON c.task_id=t.id AND c.version=t.latest_consensus_version ' ...
        'WHERE t.cell_id=' num2str(cell_id) ' AND t.status IN (' status_str ');'];
    [task_id, task_status, volume_id, vx, vy, vz, volume_name, segments, notes] = mysql(h_sql, query);
    
    trace_data.task_id = task_id;
    trace_data.volume_id = volume_id;
    trace_data.vx = vx;
    trace_data.vy = vy;
    trace_data.vz = vz;
    trace_data.volume_name = volume_name;
    trace_data.segments = segments;
    trace_data.task_status = task_status;    
    trace_data.notes = notes;
    
    mysql(h_sql, 'close');
end
