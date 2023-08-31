function rsl = replace_merged_tasks(cell_ids)
    rsl = true;
    if isempty(cell_ids)
        rsl = false;
        return
    end
        
    db_info = get_dbinfo();
    
    cell_id_str = sprintf('%d,', cell_ids);
    cell_id_str(end) = [];
    
    target_net_list = ["B2b"; "B2c"; "C1a"; "C1b"; "C1c"];
    
    for iter_net=1:numel(target_net_list)
        h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
        rtn = mysql(h_sql, ['use ' db_info.db_name]);
        if rtn <= 0 
            write_log(sprintf('@ERROR: replace_merged_tasks: DB open failed (host:%s, id:%s)', ...
                db_info.host, db_info.user), 1);
            rsl = false;
            return
        end
        
        query = sprintf('SELECT id FROM tasks WHERE cell_id IN (%s) AND status NOT IN (1,4) AND notes LIKE ''%%target_%s%%'';', cell_id_str, target_net_list{iter_net});
        tids = mysql(h_sql, query);
        mysql(h_sql, 'close');
        
        if ~isempty(tids)
            for iter=1:numel(tids)
                if task_replacer_for_pf(target_net_list{iter_net}, tids(iter)) == false
                    write_log(sprintf('  Please generate new %s volumes to replace merged volumes(task_id=%d).', target_net_list{iter_net}, tids(iter)), 1);
                    rsl = false;
                end
            end
        end        
    end
end
