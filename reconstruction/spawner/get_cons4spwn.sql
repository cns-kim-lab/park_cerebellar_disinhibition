delimiter //
drop procedure if exists get_cons4spwn //
drop temporary table if exists results //
drop temporary table if exists candidates //

create procedure get_cons4spwn()
begin

create temporary table if not exists task_mxv
(task_id int not null, mxv int not null);

insert into task_mxv select task_id, max(version) from consensuses group by task_id;

select consensuses.id,consensuses.task_id, consensuses.version, task_mxv.mxv
from consensuses join task_mxv on consensuses.task_id=task_mxv.task_id
where consensuses.version=task_mxv.mxv && inspected=0 limit 1;

drop temporary table if exists task_mxv;
end
//
delimiter ;
call get_cons4spwn();

