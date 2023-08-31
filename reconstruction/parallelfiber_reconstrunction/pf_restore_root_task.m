function pf_restore_root_task(cell_id)
    addpaths();
    
    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        return
    end
    
    write_log('[RESTORE_ROOT_TASK] -----------------------------------------------------------');
    
    if isempty(cell_id)
        write_log('cell_id is empty. quit.', 1);
        return
    end
    
    msg = sprintf('restore of cell %d root task. ', cell_id);
    
    db_info = get_dbinfo();
    handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(handle_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: restore_root_task: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    query = sprintf('SELECT id FROM tasks WHERE cell_id=%d AND depth=0 AND length(seeds)<1;', cell_id);
    root_tid = mysql(handle_sql, query);
    if isempty(root_tid)
        write_log(sprintf('@ERROR: can''t find empty root task of cell %d.', cell_id), 1);
        mysql(handle_sql, 'close');
        msg = sprintf('%s >> failed', msg);
        write_log(msg, 1);
        return
    end
    
    query = sprintf('SELECT segments FROM (SELECT version,segments FROM consensuses WHERE task_id=%d AND status=2 AND length(segments)>0) t ORDER BY version DESC LIMIT 1;', ...
        root_tid);
    segments = mysql(handle_sql, query);
    segments = cell2mat(segments);
    if isempty(segments)
        write_log(sprintf('@ERROR: can''t get final valid seeds of task %d.', root_tid), 1);
        mysql(handle_sql, 'close');
        msg = sprintf('%s >> failed', msg);
        write_log(msg, 1);
        return
    end
    
    query = sprintf('CALL omni_submit_editing_task(%d,5,''%s'',99999);', root_tid, segments);
    try 
        rtn = mysql(handle_sql, query);
    catch err
        write_log(sprintf('@ERROR: calling procedure failed. (%s)', query), 1);
        mysql(handle_sql, 'close');
        msg = sprintf('%s >> failed', msg);
        write_log(msg, 1);
        return        
    end
    if rtn < 0
        write_log(sprintf('@ERROR: query failed(%s)', query));
        mysql(handle_sql, 'close');
        msg = sprintf('%s >> failed', msg);
        write_log(msg, 1);
        return
    end 

    msg = sprintf('%s >> done', msg);
    write_log(msg, 1);
    
    mysql(handle_sql, 'close');
end