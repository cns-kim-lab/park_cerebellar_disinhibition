function pf_cell_report(cell_id_list)    
    if isempty(cell_id_list)        
        fprintf('##usage: pf_cell_report(cell_id_list); ex: pf_cell_report([100 101]);');  
        return
    end
    
    target_cell_id_str = sprintf('%d,', cell_id_list);
    target_cell_id_str(end) = [];
        
    db_info = get_dbinfo();
    
    addpaths();    

    for idx=1:numel(cell_id_list)
        cell_id = cell_id_list(idx);
        
        handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
        rtn = mysql(handle_sql, ['use ' db_info.db_name]);
        if rtn <= 0
            fprintf('@ERROR:DB open failed (host:%s, id:%s)\n', db_info.host, db_info.user);
            return
        end
        query = sprintf('SELECT status FROM cells WHERE id=%d;', cell_id);
        cell_sts = mysql(handle_sql, query);
        mysql(handle_sql, 'close');
        
        fprintf('==================================\n');
        fprintf('\tCELL %d REPORT \n', cell_id);
        fprintf('==================================\n');
        fprintf(' STATUS\t\t| VOL.Z RANGE\n');
        fprintf('---------------------------------\n');
        
        trace_data = get_cell_trace_data_include_notes(cell_id, [0 2 3]);
        fprintf(' %s\t| %02d ~ %02d\n\n', sts_str(cell_sts), min(trace_data.vz), max(trace_data.vz));
        
        print_format3(trace_data);
        fprintf('==================================\n\n'); 
    end    
end

%%
function print_the_other_cell(task_id)
    db_info = get_dbinfo();
    handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(handle_sql, ['use ' db_info.db_name]);
    if rtn <= 0
        fprintf('@ERROR:DB open failed (host:%s, id:%s)\n', db_info.host, db_info.user);
        return
    end
    
    %get consensus_id (my cell)
    query = sprintf('SELECT cons.id FROM tasks t INNER JOIN consensuses cons ON cons.task_id=t.id AND cons.version=t.latest_consensus_version AND cons.status=2 WHERE t.id=%d;', ...
        task_id);
    cons_id = mysql(handle_sql, query);
    if isempty(cons_id)
        fprintf('@ERROR: can''t find latest consensus for task %d.\n', task_id);
        mysql(handle_sql, 'close');
        return
    end
    
    %get duplicated consensus info (the other cell)
    query = sprintf('SELECT consensus_id_1,consensus_id_2 FROM duplications WHERE consensus_id_1=%d OR consensus_id_2=%d AND status=0;', ...
        cons_id, cons_id);
    [other_cons_id1, other_cons_id2] = mysql(handle_sql, query);    
    other_cons_ids = unique([other_cons_id1; other_cons_id2]);
    other_cons_ids(other_cons_ids==cons_id) = [];
    
    if isempty(other_cons_ids) % to prevent error when duplication already solved (becuz spawn timing is different when somebody owned the other cell)
        mysql(handle_sql, 'close');
        return
    end
    
    %get duplicated cell info (pf, ongoing cell only)
    other_cons_ids_str = sprintf('%d,', other_cons_ids);
    other_cons_ids_str(end) = [];
    query = sprintf('SELECT t.id,c.id,m.notes FROM tasks t INNER JOIN cells c ON c.id=t.cell_id INNER JOIN cell_metadata m ON m.id=c.meta_id LEFT JOIN consensuses cons ON cons.task_id=t.id WHERE cons.id IN (%s) AND c.status=0 AND m.notes LIKE ''%%,C1a%%'';', ...
        other_cons_ids_str);
%     query = sprintf('SELECT t.id,c.id,m.notes FROM tasks t INNER JOIN cells c ON c.id=t.cell_id INNER JOIN cell_metadata m ON m.id=c.meta_id LEFT JOIN consensuses cons ON cons.task_id=t.id WHERE cons.id IN (%s) AND m.notes LIKE ''%%,C1a%%'';', ...
%         other_cons_ids_str);
    [other_cell_task_ids, other_cell_ids, other_cell_notes] = mysql(handle_sql, query);    
    
    mysql(handle_sql, 'close');
    
    if isempty(other_cell_task_ids)
        return
    end
    
    print_msg = ' (';
    for iter=1:numel(other_cell_task_ids)
        notes_ = cell2mat(other_cell_notes(iter));
        pos = strfind(notes_, ',');
        other_cell_owner = notes_(1:pos-1);
        print_msg = sprintf('%s%s:%d,', print_msg, other_cell_owner, other_cell_ids(iter));
    end    
    print_msg(end) = [];
    fprintf('%s)', print_msg);
end

%%
function print_format3(trace_data)
    fprintf('    [[ CHECK THESE TASKS ]]\n');
    fprintf(' LV | TASK ID\t | DESCRIPTION\n');
    fprintf('---------------------------------\n');
    exist_flag = 0;
    
    %duplications and frozens
    idx = [find(trace_data.task_status==2)' find(trace_data.task_status==3)'];      
    if ~isempty(idx)
        db_info = get_dbinfo();
        handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
        rtn = mysql(handle_sql, ['use ' db_info.db_name]);
        if rtn <= 0
            fprintf('@ERROR:DB open failed (host:%s, id:%s)\n', db_info.host, db_info.user);
            return
        end
        id_str = sprintf('%d,', trace_data.task_id(idx));
        id_str(end) = [];
        query = sprintf('SELECT id,status FROM (SELECT id,status,depth FROM tasks WHERE id IN (%s)) t ORDER BY depth;', id_str);
        [task_ids, status_] = mysql(handle_sql, query);        
        mysql(handle_sql, 'close');
        
        for iter=1:numel(task_ids)
            if status_(iter) == 2 
%                 fprintf(' !  | %d\t | DUPLICATED\n', task_ids(iter));       
                fprintf(' !  | %d\t | DUPLICATED', task_ids(iter));       
                print_the_other_cell(task_ids(iter));
                fprintf('\n');
            else
                fprintf(' !  | %d\t | FROZEN\n', task_ids(iter));        
            end
        end        
        exist_flag = 1;
    end
    
    if exist_flag
        fprintf('---------------------------------\n');
    end
    
    %merge    
    idx = get_idx_error_task_by_keyword(trace_data, 'check merge');
    if ~isempty(idx)
        fprintf(' ?  | %d\t | MERGED\n', trace_data.task_id(idx));        
        exist_flag = 1;
    end
    %missing parts
    idx = get_idx_error_task_by_keyword(trace_data, 'check missing parts');
    if ~isempty(idx)
        fprintf(' ?  | %d\t | MISSING PARTS\n', trace_data.task_id(idx));            
        exist_flag = 1;
    end
    
    if ~exist_flag 
        fprintf(' -  | NONE\t | -\n');
    end
end


%%
function rsl = get_idx_error_task_by_keyword(trace_data, keyword)
    match_ = strfind(trace_data.notes, keyword);
    rsl = find(~cellfun(@isempty, match_));
    
    invalid_task_idx = find(trace_data.task_status==1);
    invalid_task_idx = [invalid_task_idx; find(trace_data.task_status==4)];
    
    %remove 'stashed' or 'buried' task
    common_ = intersect(rsl, invalid_task_idx);
    rsl = setxor(rsl, common_);
end

%%
function str_ = sts_str(cell_sts)
    switch(cell_sts)
        case 0 
            str_ = "NORMAL  ";
        case 1 
            str_ = "COMPLETED";
        case 2 
            str_ = "STASHED";
        otherwise
            str_ = "UNKNOWN";
    end
end
