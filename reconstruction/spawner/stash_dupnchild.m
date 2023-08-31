function stash_dupnchild(y_task,n_task)

addpath /data/research/bahn/code/mysql/
%{
mysql('close'); 
h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
%h_sql = mysql('open','10.1.26.181','root','1234');
%mysql(h_sql, 'use omni0714');
mysql(h_sql, 'use omni');
%}
global h_sql
connsql();

system_user_id = mysql(h_sql, sprintf('select id from users where name="%s";', 'system'));

%rtn = mysql(h_sql, sprintf(['call spwn_stash_task_and_child(%d)'],n_task));

rtn = mysql(h_sql, sprintf('start transaction;'));

[y_cell, y_depth, y_left, y_right, y_vx, y_vy, y_vz, y_seg, y_status] = mysql(h_sql, ...
    sprintf(['select t.cell_id, t.depth, t.left_edge, t.right_edge, v.vx, v.vy, v.vz, c.segments, t.status ' ...
    'from tasks as t join volumes as v join consensuses as c ' ...
    'on t.volume_id=v.id && c.task_id=t.id && t.latest_consensus_version=c.version where t.id=%d && c.status=2;'],y_task));

[n_cell, n_depth, n_left, n_right, n_vx, n_vy, n_vz, n_seg] = mysql(h_sql, ...
    sprintf(['select t.cell_id, t.depth, t.left_edge, t.right_edge, v.vx, v.vy, v.vz, c.segments ' ...
    'from tasks as t join volumes as v join consensuses as c ' ...
    'on t.volume_id=v.id && c.task_id=t.id && t.latest_consensus_version=c.version where t.id=%d && c.status=2;'],n_task));

if ~all([y_vx, y_vy, y_vz]==[n_vx, n_vy, n_vz])
    fprintf('\nDiffernt location\n');
    return
end

if y_status==1
    fprintf(['Status of task %d is "stashed"\n'],y_task);
    return
end



y_seg{1} = regexp(y_seg{1}, '\d*', 'Match');
y_seg{1} = cellfun(@str2num,y_seg{1});
y_seg = y_seg{1};
n_seg{1} = regexp(n_seg{1}, '\d*', 'Match');
n_seg{1} = cellfun(@str2num,n_seg{1});
n_seg = n_seg{1};

if isempty( intersect(y_seg, n_seg) )
    fprintf('\nno same segments\n');
    return
end

selected = 'y';

if (y_cell==n_cell) && ( y_depth > n_depth) && (y_left > n_left) && (y_right < n_right)
    fprintf('task %d is a child of task %d\n',y_task,n_task);
    
    y_seg = mysql(h_sql, ... 
        sprintf(['select c.segments from consensuses as c join tasks as t ' ...
        'on t.id=c.task_id && t.latest_consensus_version=c.version where t.id=%d && c.status=2'],y_task));
    n_latest = mysql(h_sql, sprintf(['select latest_consensus_version from tasks where id=%d'], n_task));
    rtn = mysql(h_sql, ...
        sprintf(['insert into consensuses (task_id, user_id, comparison_group_id, version, segments, status) ' ...
        'values(%d,%d, %d, %d,"%s",2);'], n_task, system_user_id, 0, n_latest+1, char(y_seg)));
    rtn = mysql(h_sql, ...
        sprintf(['update tasks set comparison_group_id=0, latest_consensus_version=%d where id=%d;'],n_latest+1,n_task));
    
    fprintf('copy segments from task %d to task %d\n',y_task,n_task);
    fprintf('and select task %d\n',n_task);
    selected = 'n';
end

if selected == 'y'
   rtn = mysql(h_sql, sprintf(['update tasks set status=1 ' ...
       'where cell_id=%d && depth>=%d && left_edge >= %d && right_edge <= %d'] ...
       ,n_cell,n_depth,n_left,n_right));
   fprintf('stash duplicated task_id %d and its child\n',n_task);
   rtn = mysql(h_sql, sprintf(['update consensuses as c join tasks as t ' ...
   'on t.id=c.task_id && t.latest_consensus_version=c.version ' ...
   'set c.inspected=0 where t.id=%d'],y_task));
   
elseif selected == 'n'
   rtn = mysql(h_sql, sprintf(['update tasks set status=1 ' ...
       'where cell_id=%d && depth>=%d && left_edge >= %d && right_edge <= %d'] ...
       ,y_cell,y_depth,y_left,y_right));
   fprintf('stash duplicated task_id %d and its child\n',y_task);
   rtn = mysql(h_sql, sprintf(['update consensuses as c join tasks as t ' ...
   'on t.id=c.task_id && t.latest_consensus_version=c.version ' ...
   'set c.inspected=0 where t.id=%d'],n_task));
   
end
rtn = mysql(h_sql, sprintf('commit;'));
mysql('close');

end


























































