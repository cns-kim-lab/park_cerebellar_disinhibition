delimiter //
drop procedure if exists spwn_add_from_stashed_task //
create procedure spwn_add_from_stashed_task
(IN parent_task_id int, IN stashed_child_task_id int)

begin

declare new_left int;
declare parent_depth int;
declare cell bigint(20) unsigned;
declare new_task_id int;

select right_edge,cell_id,depth into new_left, cell,parent_depth 
from tasks where id = parent_task_id;

update tasks set right_edge = right_edge + 2 where cell_id=cell && right_edge >= new_left;
update tasks set left_edge = left_edge + 2 where cell_id=cell && left_edge > new_left;

update tasks as t join consensuses as c 
on t.id=c.task_id && t.latest_consensus_version=c.version 
set t.cell_id=cell, t.depth=parent_depth+1, t.left_edge=new_left, t.right_edge=new_left+1,t.status=0,
c.inspected=0 where t.id=stashed_child_task_id;

end
//
delimiter ;


