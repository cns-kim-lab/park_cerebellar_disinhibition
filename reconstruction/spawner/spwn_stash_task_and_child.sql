delimiter //
drop procedure if exists spwn_stash_task_and_child //
create procedure spwn_stash_task_and_child (IN n_task_id int)

begin

declare n_depth int;
declare n_left int;
declare n_right int;
declare n_cell bigint(20) unsigned;

select depth, left_edge, right_edge, cell_id into n_depth, n_left, n_right, n_cell  
from tasks where id=n_task_id;

update tasks set status=1 
where cell_id=n_cell && right_edge <= n_right && left_edge >= n_left && depth >= n_depth;

end
//
delimiter ;


