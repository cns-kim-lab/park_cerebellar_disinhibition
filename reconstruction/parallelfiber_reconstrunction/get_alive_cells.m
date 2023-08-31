function alive_cells = get_alive_cells(user)
    db_info = get_dbinfo();
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: get_alive_cells: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user), 1);
        return
    end
    
    query = sprintf('SELECT c.id FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=0 AND m.notes LIKE %s%s%s;', ...
        '"%', user, '%"');    
    alive_cells = mysql(h_sql, query);
    mysql(h_sql, 'close');    
end
