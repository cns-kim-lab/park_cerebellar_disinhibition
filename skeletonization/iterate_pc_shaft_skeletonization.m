
target_cell_id_list = [7800 17500 1800 1100 1300 2100 2000 8100 4900 8200 5000 8300 4800 400 402 1802];

for target_cell_ind = 2:numel(target_cell_id_list)
    target_cell_id = target_cell_id_list(target_cell_ind);
    skeletonize_pc_shaft_components_recursively (target_cell_id, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
end
