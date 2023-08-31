function [did, d_status, task1, task2, cons1, cons2, dup_seg] = isdup(task_id)

did = [];
d_status = [];
task1 = [];
task2 = [];
if isempty(task_id)
   return 
end

global h_sql

[did, cons1,cons2,dup_seg,d_status,task1,cell1,task2,cell2]= ...
mysql(h_sql,sprintf(['select r.*,c.task_id as task_id_2,t.cell_id as cell_id_2 ' ...
    'from(select d.id, d.consensus_id_1,d.consensus_id_2,duplicated_segments,d.status,c.task_id as task_id_1,t.cell_id as cell_id_1 ' ...
    'from duplications as d join consensuses as c join tasks as t on d.consensus_id_1=c.id && c.task_id=t.id) ' ...
    ' as r join consensuses as c join tasks as t on r.consensus_id_2=c.id && c.task_id=t.id ' ...
    'where task_id_1=%d || t.id=%d;'],task_id,task_id));
end
