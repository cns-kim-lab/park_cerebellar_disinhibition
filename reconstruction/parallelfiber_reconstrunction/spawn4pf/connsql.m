function connsql()
addpaths();
global h_sql
db_info = get_dbinfo();
h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
rtn_step = mysql(h_sql, ['use ' db_info.db_name]);
end




