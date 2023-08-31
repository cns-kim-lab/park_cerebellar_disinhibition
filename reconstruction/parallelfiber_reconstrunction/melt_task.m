function melt_task(cell_id, task_id, optional)
    if nargin < 2 || isempty(task_id) || isempty(cell_id)
        fprintf('##usage: melt_task(cell_id, task_id, option);\n');
        fprintf('     ex: melt_task(40, 159800); \t=> melt designated task\n');
        fprintf('     ex: melt_task(40, 159800, ''all''); \t=> melt designated task and its children\n');
        return
    end
    
    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        return
    end
    
    write_log('[MELT_TASK] ----------------------------------------------------------------------------');    
    db_info = get_dbinfo();
    
    MELT_ONLY_THIS = 1;   %melt only this task
    MELT_ALL = 2;         %melt tasks including children
    
    melt_type = MELT_ONLY_THIS;
    if nargin >= 3 && ~isempty(optional) && strcmpi(optional, 'all')
        melt_type = MELT_ALL;
    end
    
    addpaths();

    handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(handle_sql, ['use ' db_info.db_name]);
    if rtn <= 0
        write_log(sprintf('@ERROR: DB open failed (host:%s, id:%s)', db_info.host, db_info.user),1);
        return
    end
    
    query = sprintf('SELECT cell_id,status,depth,left_edge,right_edge FROM tasks WHERE id=%d;', task_id);
    [cid,sts,depth,ledge,redge] = mysql(handle_sql, query);

    if cid ~= cell_id 
        write_log(sprintf('@ERROR: cell id mismatch, input:%d, in db: %d. quit.', cell_id, cid), 1);
        mysql(handle_sql, 'close');
        return
    end
    if sts ~= 3 
        write_log(sprintf('  this task is not in frozen status(%d), skip.', sts));
        mysql(handle_sql, 'close');
        return
    end

    if melt_type == MELT_ALL
        write_log(sprintf('  melt task %d and its children.', task_id));
        
        query = sprintf('SELECT GROUP_CONCAT(id) FROM tasks WHERE cell_id=%d AND depth>=%d AND left_edge>=%d AND right_edge<=%d AND status=3;', ...
            cid, depth, ledge, redge);
        all_tasks = mysql(handle_sql, query);
        all_tasks = cell2mat(all_tasks);               
    else
        write_log(sprintf('  melt task %d.', task_id));        
        all_tasks = sprintf('%d', task_id);        
    end
    
    write_log(sprintf('  melt target tasks: %s', all_tasks));
    
    query = sprintf('UPDATE tasks SET status=0 WHERE id IN (%s);', all_tasks);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('@ERROR: query failed(%s).', query), 1);
    else
        write_log('  melt done');
    end
    mysql(handle_sql, 'close');
end
