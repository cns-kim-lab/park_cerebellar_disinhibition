delimiter //
drop procedure if exists spwn_get_vals4cmp //
drop temporary table if exists results //
drop temporary table if exists candidates //

create procedure spwn_get_vals4cmp()
begin

declare target_task int;
select id into target_task from tasks where progress=2 && status=0 limit 1;

create temporary table if not exists results
(val_id int not null, task_id int not null, user_id int not null, segments mediumtext not null);

create temporary table if not exists candidates
(val_id int not null, task_id int not null, user_id int not null, 
version int not null, segments mediumtext not null, inspected int not null, status int not null);

insert into candidates select id,task_id,user_id,version,segments,inspected,status 
from(select * from validations where task_id=target_task && status=2) as cdd  
order by inspected asc, user_id desc, version desc;

insert into results select val_id, task_id, @user1:=user_id, segments from candidates limit 1;
insert into results select val_id, task_id, user_id, segments from candidates where user_id!=@user1 limit 1;

select results.task_id, volumes.path, results.val_id, results.user_id, results.segments 
from results join tasks join volumes on results.task_id=tasks.id && tasks.volume_id=volumes.id;

drop temporary table if exists results;
drop temporary table if exists candidates;

end
//
delimiter ;


