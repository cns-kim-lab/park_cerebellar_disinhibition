function volume_info = find_volume_info_from_task_id (task_id, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

global h_sql
try
    h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
catch    
    fprintf('stat - already db open, close and reopen\n');    
    mysql(h_sql, 'close');
    h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
end

r = mysql(h_sql, sprintf('use %s',mysql_db_name));
if r <= 0
    fprintf('db connection fail\n');
    return;
end

query = sprintf(['select v.net_id, v.vx, v.vy, v.vz, s.segments ' ...
                     'from tasks t ' ... 
                     'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version '...
                     'inner join volumes v on t.volume_id = v.id '...           
                     'where v.dataset_id = 1 '...
                     'and t.id = %d'], task_id);                     

[net_id,vx,vy,vz,segment_list_string] = mysql(h_sql, query);
segment_list = str2double(split(strtrim(segment_list_string),' '))';

volume_info{1} = net_id;
volume_info{2} = [vx vy vz];
volume_info{3} = segment_list;
                
mysql(h_sql, 'close');

end
