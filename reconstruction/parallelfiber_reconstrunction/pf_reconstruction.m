function pf_reconstruction()
    addpaths();
    
    close all hidden;
    close all force;
    
    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        return
    end
    
    write_log('[PF_RECONSTRUCTION] -----------------------------------------------------------');
   
    %get target cell_ids
    target_cell_ids = get_alive_cells(user);
    if isempty(target_cell_ids)
        write_log('  alive cell not exists. generate new cells.');
        new_cells = initiate_cells(user);
        return
    end
    
    %change cell status
    [success, target_cell_ids] = pf_cell_review_manager(target_cell_ids, 0, 1);    
    if success ~= 1  %if error has occurred, quit process
        write_log('  quit pf_reconstruction.');
        return
    end    
    if isempty(target_cell_ids)
        write_log('  all cells are droped or done. generate new cells.');
        new_cells = initiate_cells(user);
        return
    end
    
    %replace merged volume 
    if replace_merged_tasks(target_cell_ids) == false
        return
    end    
    
    %melt & spawn (frozen tasks)
    melt_tasks_in_cells(target_cell_ids);
    %spawn (duplicated tasks)
    spawn_tasks_in_cells(target_cell_ids);    
    
    %agglomeration
    pf_agglomerator(target_cell_ids);
    
    %make review volume
    pf_cell_review_manager(target_cell_ids);
    
    msgbox('Now you can use omni for reviewing cells.', 'Info', 'help');
end

%%
function spawn_tasks_in_cells(cell_ids)
    if isempty(cell_ids)
        return
    end
    
    db_info = get_dbinfo();
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: spawn_tasks_in_cells: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    cell_id_str = sprintf('%d,', cell_ids);
    cell_id_str(end) = [];
    
    %duplicated tasks
    query = sprintf('SELECT cell_id,id FROM tasks WHERE cell_id IN (%s) AND status=2;', cell_id_str);
    [cid, tid] = mysql(h_sql, query);            
    mysql(h_sql, 'close');         
    if ~isempty(cid)        
        for iter=1:numel(cid)            
            if check_consensus_updated(db_info, tid(iter))
                force_flag = 0;                
            else
                force_flag = 1;
            end
            
            write_log(sprintf('  spawn to solve duplication: task %d (cell %d), force_field=%d', tid(iter), cid(iter), force_flag));            
            [~,~,~,stitched_tasks] = spawn_for_agglomerator(cid(iter), 0.993, 6, tid(iter), force_flag);            
            reset_notes_field(stitched_tasks);
            
            [engaged_cell, engaged_task] = check_dup_to_solve(tid(iter));
            if ~isempty(engaged_cell)
                write_log(sprintf('   task %d is related to %d tasks, spawn them all.', tid(iter), numel(engaged_cell)));
                for iter_=1:numel(engaged_cell)
                    if ~isempty(find(cell_ids==engaged_cell(iter_), 1))
                        write_log(sprintf('   duplicated with my cell(%d). skip spawn.', engaged_cell(iter_)));
                        continue
                    end
                    if is_anyones_property(db_info, engaged_cell(iter_))
                        continue
                    end
                    if is_working_cell(db_info, engaged_cell(iter_))
                        continue
                    end
                    
                    [~,~,~,~] = spawn_for_agglomerator(engaged_cell(iter_), 0.999, 6, engaged_task(iter_), ~check_consensus_updated(db_info, engaged_task(iter_)));
                end
            end 
        end
    end    

    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: spawn_tasks_in_cells: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    %normal tasks
    query = sprintf('%s %s WHERE c.id IN (%s) AND t.status=0 AND cons.status=2 AND cons.inspected=0 AND cons.version>1;', ...
        'SELECT c.id AS cid, t.id AS tid FROM tasks t', ...
        'INNER JOIN cells c ON c.id=t.cell_id INNER JOIN consensuses cons ON cons.task_id=t.id AND cons.version=t.latest_consensus_version', ...
        cell_id_str);   
    [cid, tid] = mysql(h_sql, query);
    mysql(h_sql, 'close');         
    if isempty(cid)
        return
    end
        
    for iter=1:numel(cid)
        write_log(sprintf('  spawn updated tasks: task %d (cell %d)', tid(iter), cid(iter)));
        [~,~,~,stitched_tasks] = spawn_for_agglomerator(cid(iter), 0.993, 6, tid(iter));
        reset_notes_field(stitched_tasks);
    end
end

%%
function isworking = is_working_cell(db_info, cell_id)
    isworking = false;       
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: is_working_cell: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    query = sprintf('SELECT id FROM cells WHERE id=%d AND status=0 AND display=1;', cell_id);
    cid = mysql(h_sql, query);
    mysql(h_sql, 'close');
    
    if ~isempty(cid)
        isworking = true;        
        write_log(sprintf('   duplicated with working cell(%d). skip spawn.', cell_id));
    end
end

%%
function reset_notes_field(task_ids)
    if isempty(task_ids)
        return
    end
    write_log('   update notes for stitched tasks.');
    
    db_info = get_dbinfo();

    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: reset_notes_field: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user),1);
        return
    end    
    
    for iter=1:numel(task_ids)
        task_id = task_ids(iter);
        query = sprintf('UPDATE tasks SET notes='' '' WHERE id=%d;', task_id);
        rtn = mysql(h_sql, query);
        if rtn < 0 
            write_log(sprintf('@ERROR: reset_notes_field: query failed(%s)', query),1);            
        end 
    end
    
    mysql(h_sql, 'close');
end



%%
function exist_new_cons = check_consensus_updated(db_info, task_id)
    exist_new_cons = 1;
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: check_consensus_updated: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    query = sprintf('SELECT t.cell_id, t.id FROM tasks t LEFT JOIN consensuses c ON c.task_id=t.id AND c.version=t.latest_consensus_version WHERE t.id=%d AND c.status=2 AND c.inspected=0;', ...
        task_id);
    [cid, tid] = mysql(h_sql, query);
    mysql(h_sql, 'close');    
    
    if isempty(cid) || isempty(tid) 
        exist_new_cons = 0;
    end
end

%%
function belong_to_someone = is_anyones_property(db_info, cell_id)
    belong_to_someone = false;
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: is_anyones_property: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    query = sprintf('SELECT c.id, m.notes FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.id=%d AND c.status=0 AND m.notes LIKE ''%%,C1%%'';', cell_id);
    [cid, meta_notes] = mysql(h_sql, query);
    if ~isempty(cid)
        belong_to_someone = true;
        
        notes = cell2mat(meta_notes);
        owner = notes(1:strfind(notes, ',')-1);
        write_log(sprintf('   duplicated with %s owned cell(%d). skip spawn.', owner, cell_id));
    end
    
    mysql(h_sql, 'close');
end

%%
function melt_tasks_in_cells(cell_ids)
    if isempty(cell_ids)
        return
    end
    
    db_info = get_dbinfo();
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: melt_tasks_in_cells: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    cell_id_str = sprintf('%d,', cell_ids);
    cell_id_str(end) = [];
    
    query = sprintf('%s %s WHERE c.id IN (%s) AND t.status=3 AND cons.status=2 AND cons.inspected=0 AND cons.version>1;', ...
        'SELECT c.id AS cid, t.id AS tid FROM tasks t', ...
        'INNER JOIN cells c ON c.id=t.cell_id INNER JOIN consensuses cons ON cons.task_id=t.id AND cons.version=t.latest_consensus_version', ...
        cell_id_str);    
    [cid, tid] = mysql(h_sql, query);
    mysql(h_sql, 'close');    
    
    if isempty(cid)
        return
    end
    
    for iter=1:numel(cid)
        write_log(sprintf('  melt & spawn: task %d (cell %d)', tid(iter), cid(iter)));
        melt_task(cid(iter), tid(iter), 'all');
        [~,~,~,stitched_tasks] = spawn_for_agglomerator(cid(iter), 0.993, 6, tid(iter));
        reset_notes_field(stitched_tasks);
    end
end

