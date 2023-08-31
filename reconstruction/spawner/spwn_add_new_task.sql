delimiter //
drop procedure if exists spwn_add_new_task //
create procedure spwn_add_new_task
(IN parent_task_id int, IN vol_id int, IN seeds mediumtext, IN new_task_status int,
IN system_user_id int, IN excoord mediumtext)

begin

declare new_left int;
declare parent_depth int;
declare cell bigint(20) unsigned;
declare new_task_id int;

select right_edge,cell_id,depth into new_left, cell,parent_depth 
from tasks where id = parent_task_id;

update tasks set right_edge = right_edge + 2 where cell_id=cell && right_edge >= new_left;
update tasks set left_edge = left_edge + 2 where cell_id=cell && left_edge > new_left;

insert into tasks (cell_id,volume_id,seeds,depth,left_edge,right_edge,
created,validation_active_count,comparison_group_id,status,spawning_coordinate) 
values(cell,vol_id,seeds,parent_depth+1,new_left,new_left+1,current_timestamp,
0,0,new_task_status,excoord);

select last_insert_id() into new_task_id;

insert into consensuses (task_id,user_id,comparison_group_id,segments,finish,status) 
values(new_task_id,system_user_id,0,seeds,current_timestamp,2);

end
//
delimiter ;


