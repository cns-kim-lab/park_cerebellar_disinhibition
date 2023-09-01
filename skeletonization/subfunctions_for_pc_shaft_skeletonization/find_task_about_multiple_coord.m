function [task_info, volume_info] = find_task_about_multiple_coord(coord, target_omni_id, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)
    
    addpath ./mysql/

    [~,dataset] = lrrtm3_get_global_param(1);

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

    vol_seg_list = find_vol_seg_about_multiple_coord (coord);

    task_info = [];
    num_data = 0;

    % query = sprintf('select description from enumerations where table_name=''tasks'' and field_name=''progress'' order by enum');
    % task_progress_strings = mysql(h_sql, query);
    % 
    % query = sprintf('select description from enumerations where table_name=''tasks'' and field_name=''status'' order by enum');
    % task_status_strings = mysql(h_sql, query);

    for i = 1:numel(vol_seg_list)
        
        vol_id = vol_seg_list(i).vol_id;
        nxyz = textscan(vol_id, '%s x%02d y%02d z%02d','delimiter','_');
        segment = vol_seg_list(i).segment; 

    % % %     06.11 - modified code , including 'cell_metadata' table
        query = sprintf(['select t.id, c.id, cm.omni_id, t.volume_id, v.net_id, v.vx, v.vy, v.vz, t.depth, t.left_edge, t.right_edge, t.status, t.progress, s.segments ' ...
                        'from tasks t ' ... 
                        'inner join cells c on t.cell_id = c.id ' ...
                        'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version '...
                        'inner join volumes v on t.volume_id = v.id '...           
                        'inner join cell_metadata cm on cm.id = c.meta_id '...
                        'where v.dataset_id = 1 and v.net_id = ''%s'' and v.vx = %d and v.vy = %d and v.vz = %d '...
                            'and c.id in (select c.id from cells c inner join cell_metadata cm on cm.id = c.meta_id where c.status<>2 and cm.omni_id = %d) '...
                            'and t.status not in (1, 4)'],nxyz{1}{1},nxyz{2},nxyz{3},nxyz{4},target_omni_id);                     

        [task_id, ~, ~, ~, net_id, vx, vy, vz, depth, left_edge, right_edge, ~, ~, segment_list_string] = mysql(h_sql, query);
        
        for j = 1:numel(task_id) 
            segment_list = str2double(split(strtrim(segment_list_string{j}),' '))';
            if ~any(ismember(segment_list,segment))
                continue;
            end
            
            num_data = num_data + 1;
            task_info(num_data,1) = task_id(j);
    %        task_info(num_data,2) = cell_id(j);
    %        task_info(num_data,3) = omni_id(j);
            task_info(num_data,2) = depth(j);
            task_info(num_data,3) = left_edge(j);
            task_info(num_data,4) = right_edge(j);

            volume_info{num_data,1} = net_id{j};
            volume_info{num_data,2} = [vx(j) vy(j) vz(j)];
            volume_info{num_data,3} = segment_list;

        end
        
    end

    mysql(h_sql, 'close');


end