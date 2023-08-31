delimiter //
drop procedure if exists get_vals4cmp2 //
drop temporary table if exists results //
drop temporary table if exists candidates //

create procedure get_vals4cmp2()
begin

declare target_task int;
create temporary table if not exists instable
(task_id int not null, ins0st2 int not null, ins1st2 int not null);
insert into instable select task_id, 
count(if(inspected=0&&status=2,1,null)) as ins0st2, count(if(inspected=1&&status=2,1,null)) as ins0st2 
from validations group by task_id;

select task_id into target_task from instable
where ins0st2>=2 || (ins0st2=1&&ins1st2>0) limit 1;

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
drop temporary table if exists instable;
end
//
delimiter ;
call get_vals4cmp2();

