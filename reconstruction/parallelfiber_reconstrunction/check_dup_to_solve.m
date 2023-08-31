function [dcell_id, dtask_id] = check_dup_to_solve(task_id)
    global h_sql
    connsql();

    query = sprintf(['select r.*,c.task_id as task_id_2,t.cell_id as cell_id_2 ' ...
        'from(select d.consensus_id_1,d.consensus_id_2,duplicated_segments,d.status,c.task_id as task_id_1,t.cell_id as cell_id_1 ' ...
        'from duplications as d join consensuses as c join tasks as t on d.consensus_id_1=c.id && c.task_id=t.id) ' ...
        ' as r join consensuses as c join tasks as t on r.consensus_id_2=c.id && c.task_id=t.id ' ...
        'where task_id_1=%d || t.id=%d;'],task_id,task_id);
    [~,~,~,~,task1,cell1,task2,cell2]= mysql(h_sql,query);
    mysql(h_sql, 'close'); 

    %integrate all task id
    all_tasks = [task1; task2];   
    all_cells = [cell1; cell2];

    dtask_id = unique(all_tasks);
    dtask_id(dtask_id==task_id) = [];
    dcell_id = [];
    for iter=1:numel(dtask_id)
        idx = find(all_tasks==dtask_id(iter), 1);
        dcell_id = [dcell_id; all_cells(idx)];
    end    
end

%%

































































