function [reference_task_list,depth] = fill_gap_tasks_between_two_tasks (parent_task_id,offspring_task_id,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

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

query2 = sprintf(['select c.id, t.depth, t.left_edge, t.right_edge ' ...
                     'from tasks t ' ... 
                     'inner join cells c on t.cell_id = c.id ' ...
                     'where t.id = %d'], offspring_task_id);                     

[c_id_2, depth_2, left_edge_2, right_edge_2] = mysql(h_sql, query2);

if parent_task_id ~= 0
    query1 = sprintf(['select t.id, c.id, t.depth, t.left_edge, t.right_edge, t.latest_consensus_version ' ...
                     'from tasks t ' ... 
                     'inner join cells c on t.cell_id = c.id ' ...
                     'where t.id = %d'], parent_task_id);                     
else
    query1 = sprintf(['select t.id, c.id, t.depth, t.left_edge, t.right_edge, t.latest_consensus_version ' ...
                     'from tasks t ' ... 
                     'inner join cells c on t.cell_id = c.id ' ...
                     'where t.cell_id = %d and t.depth = 0'], c_id_2);                     
end

[t_id_1, c_id_1, depth_1, left_edge_1, right_edge_1, consensus_version] = mysql(h_sql, query1);
[consensus_version_sorted,sort_ind] = sort(consensus_version,'descend');
t_id_1_sorted = t_id_1(sort_ind);
c_id_1_sorted = c_id_1(sort_ind);
depth_1_sorted = depth_1(sort_ind);
left_edge_1_sorted = left_edge_1(sort_ind);
right_edge_1_sorted = right_edge_1(sort_ind);
depth_and_edges_sorted = [depth_1_sorted left_edge_1_sorted right_edge_1_sorted];
[depth_and_edges_sorted_unique,unique_ind] = unique(depth_and_edges_sorted,'rows','stable');

t_id_1 = t_id_1_sorted(unique_ind);
left_edge_1 = left_edge_1_sorted(unique_ind);
right_edge_1 = right_edge_1_sorted(unique_ind);


parent_task_id = t_id_1;

query3 = sprintf(['select t.id, t.depth ' ...
                    'from tasks t ' ...
                    'inner join cells c on t.cell_id = c.id ' ...                                         
                    'where t.cell_id = %d ' ...
                    'and t.left_edge>%d ' ...
                    'and t.left_edge<%d ' ...
                    'and t.right_edge<%d ' ...
                    'and t.right_edge>%d ' ...                    
                    'and t.status not in (1, 4)'],c_id_2,left_edge_1,left_edge_2,right_edge_1,right_edge_2);                     

[reference_task_list,depth] = mysql(h_sql, query3);

[reference_task_list,ir,~] = unique([parent_task_id; reference_task_list; offspring_task_id],'stable');
depth = [depth_1; depth; depth_2];
depth = depth(ir);
    
mysql(h_sql, 'close');

end
