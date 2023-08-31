delimiter //
drop procedure if exists spwn_get_new_child //
create procedure spwn_get_new_child (IN y_task_id int, IN n_task_id int)

begin

declare y_depth int;
declare y_left int;
declare y_right int;
declare y_cell bigint(20) unsigned;
declare n_depth int;
declare n_left int;
declare n_right int;
declare n_cell bigint(20) unsigned;

declare space int;
declare n_child_min_left int;
declare offset int;
declare ddth int;

create temporary table if not exists nchildlist (id int);



select depth, left_edge, right_edge, cell_id into y_depth, y_left, y_right, y_cell  
from tasks where id=y_task_id;
select depth, left_edge, right_edge, cell_id into n_depth, n_left, n_right, n_cell  
from tasks where id=n_task_id;

insert into nchildlist select id from tasks
where left_edge >= n_left && right_edge <= n_right 
order by left_edge;

set space = n_right - n_left +1;

update tasks set right_edge = right_edge + space where cell_id=y_cell && right_edge >= y_right;
update tasks set left_edge = left_edge + space where cell_id=y_cell && left_edge > y_right;

select t.left_edge into n_child_min_left from nchildlist as n left join tasks as t 
on n.id=t.id limit 1;

set offset = y_right - n_child_min_left;
set ddth = y_depth - n_depth + 1;

update tasks as t right join nchildlist as n on t.id=n.id set t.right_edge = t.right_edge + offset;
update tasks as t right join nchildlist as n on t.id=n.id set t.left_edge = t.left_edge + offset;
update tasks as t right join nchildlist as n on t.id=n.id set t.depth = t.depth + ddth;
update tasks as t right join nchildlist as n on t.id=n.id set t.cell_id = y_cell; 

drop temporary table if exists nchildlist;
end
//
delimiter ;


