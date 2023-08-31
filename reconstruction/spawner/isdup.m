function did = isdup(task_id)

did = [];
if isempty(task_id)
   return 
end

addpath /data/research/bahn/code/mysql/
global h_sql
%{
mysql('close'); 
h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
%h_sql = mysql('open','10.1.26.181','root','1234');
%mysql(h_sql, 'use omni0721');
mysql(h_sql, 'use omni');
%}

[did, cons1,cons2,dup_seg,status,task1,cell1,task2,cell2]= ...
mysql(h_sql,sprintf(['select r.*,c.task_id as task_id_2,t.cell_id as cell_id_2 ' ...
    'from(select d.id, d.consensus_id_1,d.consensus_id_2,duplicated_segments,d.status,c.task_id as task_id_1,t.cell_id as cell_id_1 ' ...
    'from duplications as d join consensuses as c join tasks as t on d.consensus_id_1=c.id && c.task_id=t.id) ' ...
    ' as r join consensuses as c join tasks as t on r.consensus_id_2=c.id && c.task_id=t.id ' ...
    'where task_id_1=%d || t.id=%d;'],task_id,task_id));


end


































































