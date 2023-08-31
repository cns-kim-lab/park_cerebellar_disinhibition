function insert_into_dup(cons_id1,cons_id2,dup_segs)

global h_sql

[did, cons1,cons2,~,d_status,~,~,~,~]= ...
mysql(h_sql,sprintf(['select r.*,c.task_id as task_id_2,t.cell_id as cell_id_2 ' ...
    'from(select d.id, d.consensus_id_1,d.consensus_id_2,duplicated_segments,d.status,c.task_id as task_id_1,t.cell_id as cell_id_1 ' ...
    'from duplications as d join consensuses as c join tasks as t on d.consensus_id_1=c.id && c.task_id=t.id) ' ...
    ' as r join consensuses as c join tasks as t on r.consensus_id_2=c.id && c.task_id=t.id ' ...
    'where r.consensus_id_1=%d && r.consensus_id_2=%d;'],cons_id1,cons_id2));

if ~isempty(did)
    for i=length(cons1)
        if cons1(i)==cons_id1 && cons2(i)==cons_id2
            mysql(h_sql,sprintf('update duplications set status=0 where id=%d',did(i)));
            return
        end
    end
end

rtn_step = mysql(h_sql,sprintf(['insert into duplications (consensus_id_1, ' ...
    'consensus_id_2, duplicated_segments) ' ...
    'values(%d,%d,"%s")'],cons_id1,cons_id2,dup_segs));


end
