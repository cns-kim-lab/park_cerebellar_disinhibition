function find_neighbor_tasks(target_task_id)
    if isempty(target_task_id)
        return
    end
    
    addpaths();    
    
    db_info = get_dbinfo();
        h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        fprintf('@ERROR: find_neighbor_tasks: DB open failed (host:%s, id:%s)\n', db_info.host, db_info.user);
        return
    end
    
    query = sprintf('SELECT t.cell_id,t.status,v.vx,v.vy,v.vz FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.id=%d;', ...
        target_task_id);
    [cid, task_sts, vx, vy, vz] = mysql(h_sql, query);
    if isempty(cid)
        fprintf('can''t find task %d.\n', target_task_id);
    elseif task_sts == 1 || task_sts == 4
        fprintf('task %d is in invalid status(stashed or buried).\n', target_task_id);
    else
        fprintf('  Neighbors of task %d (cell %d)\n', target_task_id, cid);
        
        %(x-)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx-1, vy, vz);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(x-) ');
            print_task_ids(task_ids);
        end
        
        %(x+)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx+1, vy, vz);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(x+) ');
            print_task_ids(task_ids);
        end
        
        %(y-)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx, vy-1, vz);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(y-) ');
            print_task_ids(task_ids);
        end
        
        %(y+)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx, vy+1, vz);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(y+) ');
            print_task_ids(task_ids);
        end
        
        %(z-)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx, vy, vz-1);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(z-) ');
            print_task_ids(task_ids);
        end
        
        %(z+)
        query = sprintf('SELECT t.id FROM tasks t INNER JOIN volumes v ON v.id=t.volume_id WHERE t.cell_id=%d AND v.vx=%d AND v.vy=%d AND v.vz=%d AND t.status NOT IN (1,4);', ...
            cid, vx, vy, vz+1);
        task_ids = mysql(h_sql, query);
        if ~isempty(task_ids)
            fprintf('\t(z+) ');
            print_task_ids(task_ids);
        end
    end    
    
    mysql(h_sql, 'close'); 
end

%%
function print_task_ids(task_ids)
    for iter=1:numel(task_ids)
        fprintf('%d ', task_ids(iter));
    end
    fprintf('\n');
end