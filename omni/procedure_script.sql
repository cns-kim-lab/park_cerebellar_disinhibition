DROP PROCEDURE IF EXISTS omni_get_trace_task_list_normal;
delimiter //
CREATE PROCEDURE omni_get_trace_task_list_normal 
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS candidate_a;
DROP TEMPORARY TABLE IF EXISTS val_mine;
DROP TEMPORARY TABLE IF EXISTS val_done;
CREATE TEMPORARY TABLE candidate_a (
	SELECT id FROM tasks 
	WHERE cell_id=cid AND validation_active_count<2 AND status=0 AND progress IN (0,1) LIMIT 50);
CREATE TEMPORARY TABLE val_mine (
	SELECT DISTINCT val.task_id FROM validations val 
	INNER JOIN candidate_a can ON can.id=val.task_id WHERE val.user_id=uid);
CREATE TEMPORARY TABLE val_done (
	SELECT id,COUNT(*) AS cnt FROM (SELECT * FROM (SELECT * FROM 
	(SELECT can.id,val.user_id,val.version,val.status FROM candidate_a can LEFT JOIN validations val ON val.task_id=can.id WHERE val.status IN (1,2)) 
	AS tbl ORDER BY id ASC,user_id ASC,version DESC) AS tbl2 GROUP BY id,user_id) AS tbl3 WHERE status=2 GROUP BY id);
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id INNER JOIN candidate_a can ON can.id=t.id 
	LEFT JOIN val_mine mine ON mine.task_id=t.id LEFT JOIN val_done d ON d.id=t.id 
	WHERE mine.task_id IS NULL AND t.cell_id=cid AND t.progress IN (0,1) AND t.status=0
	AND ((d.cnt IS NULL AND t.validation_active_count<2) OR (d.cnt IS NOT NULL AND d.cnt+t.validation_active_count<2)) LIMIT 20);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_list_completed;
delimiter //
CREATE PROCEDURE omni_get_trace_task_list_completed 
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS candidate_a;
CREATE TEMPORARY TABLE candidate_a ( 
	SELECT * FROM ( SELECT * FROM (
	SELECT v.task_id,v.version,v.status FROM validations v INNER JOIN tasks t ON v.task_id=t.id 
	WHERE v.user_id=uid AND t.cell_id=cid AND t.progress IN (1,2,3,5,6) AND t.status=0
	) AS tbl ORDER BY task_id ASC, version DESC
	) AS tbl2 GROUP BY task_id LIMIT 30);
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN candidate_a can ON can.task_id=t.id INNER JOIN volumes vol ON vol.id=t.volume_id 
	WHERE can.status=2 LIMIT 20);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_list_ongoing;
delimiter //
CREATE PROCEDURE omni_get_trace_task_list_ongoing 
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id 
	INNER JOIN validations val ON val.task_id=t.id 
	WHERE t.cell_id=cid AND t.status=0 AND t.progress=1 AND val.user_id=uid AND val.status=1);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_list_skipped;
delimiter // 
CREATE PROCEDURE omni_get_trace_task_list_skipped 
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id 
	INNER JOIN validations val ON val.task_id=t.id 
	WHERE t.cell_id=cid AND t.status=0 AND t.progress=1 AND val.user_id=uid AND val.status=3);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_last_version_record_validations;
delimiter //
CREATE PROCEDURE omni_get_last_version_record_validations 
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED,
OUT val_id BIGINT UNSIGNED, OUT vers SMALLINT UNSIGNED, OUT sts TINYINT UNSIGNED)
BEGIN
SELECT id,version,status INTO val_id,vers,sts FROM (
	SELECT id,version,status FROM validations 
	WHERE task_id=tid AND user_id=uid
) AS tbl ORDER BY version DESC LIMIT 1; 
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_info_ongoing;
delimiter //
CREATE PROCEDURE omni_get_trace_task_info_ongoing
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
SELECT id INTO val_id FROM (
	SELECT val.id,val.version FROM validations val INNER JOIN tasks t ON t.id=val.task_id 
	WHERE t.id=tid AND t.progress=1 AND t.status=0 AND val.user_id=uid
) AS tbl ORDER BY version DESC LIMIT 1;
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,val.segments FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN validations val ON val.task_id=t.id
WHERE t.id=tid AND val.id=val_id AND val.status=1;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_info_skipped;
delimiter //
CREATE PROCEDURE omni_get_trace_task_info_skipped 
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
SELECT id INTO val_id FROM (
	SELECT val.id,val.version FROM validations val INNER JOIN tasks t ON t.id=val.task_id 
	WHERE t.id=tid AND t.progress=1 AND t.status=0 AND val.user_id=uid
) AS tbl ORDER BY version DESC LIMIT 1;
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,val.segments FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN validations val ON val.task_id=t.id
WHERE t.id=tid AND val.id=val_id AND val.status=3;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_info_normal;
delimiter //
CREATE PROCEDURE omni_get_trace_task_info_normal 
(IN tid BIGINT UNSIGNED)
BEGIN
DECLARE cnt_ INT UNSIGNED;
SELECT COUNT(*) INTO cnt_ FROM (
	SELECT DISTINCT user_id FROM validations WHERE task_id=tid AND status=2) AS tbl;
IF cnt_<2 THEN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
WHERE t.id=tid AND t.progress IN (0,1) AND t.status=0 AND t.validation_active_count<2;
END IF;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_info_completed;
delimiter //
CREATE PROCEDURE omni_get_trace_task_info_completed
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
SELECT id INTO val_id FROM (
	SELECT val.id,val.version FROM validations val INNER JOIN tasks t ON t.id=val.task_id 
	WHERE t.id=tid AND t.progress IN (1,2,3,5,6) AND t.status=0 AND val.user_id=uid
) AS tbl ORDER BY version DESC LIMIT 1;
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,val.segments FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN validations val ON val.task_id=t.id
WHERE t.id=tid AND val.id=val_id AND val.status=2;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_trace_task_info_anyway;
delimiter //
CREATE PROCEDURE omni_get_trace_task_info_anyway
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
SELECT id INTO val_id FROM (
	SELECT val.id,val.version FROM validations val INNER JOIN tasks t ON t.id=val.task_id 
	WHERE t.id=tid AND t.progress IN (0,1,2,3,5,6) AND t.status IN (0,2) AND val.user_id=uid
) AS tbl ORDER BY version DESC LIMIT 1;
IF val_id IS NULL THEN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
WHERE t.id=tid AND t.status IN (0,2);
ELSE
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,val.segments FROM tasks t
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN validations val ON val.task_id=t.id
WHERE t.id=tid AND val.id=val_id;
END IF;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_trace_task_ongoing;
delimiter //
CREATE PROCEDURE omni_update_trace_task_ongoing
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET progress=1 WHERE id=tid;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
UPDATE validations SET segments=seglist,status=1,inspected=1 WHERE id=val_id;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_trace_task_skipped;
delimiter //
CREATE PROCEDURE omni_update_trace_task_skipped
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET progress=1,validation_active_count=validation_active_count+1 WHERE id=tid;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
UPDATE validations SET segments=seglist,status=1,inspected=1 WHERE id=val_id;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_trace_task_completed;
delimiter //
CREATE PROCEDURE omni_update_trace_task_completed
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET progress=1,validation_active_count=validation_active_count+1 WHERE id=tid;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
INSERT INTO validations (task_id,user_id,version,segments,status,duration,inspected) 
values (tid,uid,val_ver+1,seglist,1,0,1);
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_trace_task_normal;
delimiter //
CREATE PROCEDURE omni_update_trace_task_normal
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT)
BEGIN
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET progress=1,validation_active_count=validation_active_count+1 WHERE id=tid;
INSERT INTO validations (task_id,user_id,segments,status,duration,inspected) 
values (tid,uid,seglist,1,0,1);
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_trace_task_auto;
delimiter //
CREATE PROCEDURE omni_update_trace_task_auto
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE seglist MEDIUMTEXT;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
DECLARE CONTINUE HANDLER FOR NOT FOUND
START TRANSACTION;
UPDATE tasks SET progress=1 WHERE id=tid;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
SELECT seeds INTO seglist FROM tasks WHERE id=tid;
IF val_id IS NULL THEN
	INSERT INTO validations (task_id,user_id,segments,status,duration,inspected) 
	values (tid,uid,seglist,1,0,1);
	UPDATE tasks SET validation_active_count=validation_active_count+1 WHERE id=tid;
ELSEIF val_sts=1 THEN
	UPDATE validations SET status=1,inspected=1 WHERE id=val_id;
ELSEIF val_sts=2 THEN
	SELECT segments INTO seglist FROM validations WHERE id=val_id;
	INSERT INTO validations (task_id,user_id,version,segments,status,duration,inspected) 
	values (tid,uid,val_ver+1,seglist,1,0,1);
	UPDATE tasks SET validation_active_count=validation_active_count+1 WHERE id=tid;
ELSE 
	UPDATE validations SET status=1,inspected=1 WHERE id=val_id;
	UPDATE tasks SET validation_active_count=validation_active_count+1 WHERE id=tid;
END IF;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_submit_trace_task;
delimiter //
CREATE PROCEDURE omni_submit_trace_task
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED) 
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE cnt INT UNSIGNED;
DECLARE cnt_trace_done INT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
DECLARE CONTINUE HANDLER FOR NOT FOUND
START TRANSACTION;
DROP TEMPORARY TABLE IF EXISTS my_records;
CREATE TEMPORARY TABLE my_records (
	SELECT id FROM (
	SELECT id,version FROM validations 
	WHERE task_id=tid AND user_id=uid
	) AS tbl ORDER BY version DESC LIMIT 2);
SELECT id INTO val_id FROM my_records LIMIT 1,1;
IF val_id IS NOT NULL THEN
UPDATE validations SET inspected=1 WHERE id=val_id;
END IF;
SELECT id INTO val_id FROM my_records LIMIT 0,1;
UPDATE validations SET status=2,inspected=0 WHERE id=val_id;
UPDATE tasks SET validation_active_count=validation_active_count-1 WHERE id=tid;
SELECT COUNT(*) INTO cnt_trace_done FROM (
	SELECT DISTINCT user_id FROM validations WHERE task_id=tid AND status=2) AS tbl;
IF cnt_trace_done>1 THEN
UPDATE tasks SET progress=IF(validation_active_count=0,2,progress) WHERE id=tid;
END IF;
COMMIT;
END; //
delimiter ;


DROP PROCEDURE IF EXISTS omni_save_trace_task;
delimiter //
CREATE PROCEDURE omni_save_trace_task
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT, IN ptime INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
UPDATE validations SET segments=seglist,duration=duration+ptime WHERE id=val_id;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_skip_trace_task;
delimiter //
CREATE PROCEDURE omni_skip_trace_task
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE val_id BIGINT UNSIGNED;
DECLARE val_ver SMALLINT UNSIGNED;
DECLARE val_sts TINYINT UNSIGNED;
DECLARE cnt_trace_done INT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
CALL omni_get_last_version_record_validations(tid, uid, val_id, val_ver, val_sts);
UPDATE validations SET status=3,inspected=1 WHERE id=val_id;
UPDATE tasks SET validation_active_count=validation_active_count-1 WHERE id=tid;
SELECT COUNT(*) INTO cnt_trace_done FROM (
	SELECT DISTINCT user_id FROM validations WHERE task_id=tid AND status=2) AS tbl;
IF cnt_trace_done>1 THEN
UPDATE tasks SET progress=IF(validation_active_count=0,2,progress) WHERE id=tid;
END IF;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_dataset_ids;
delimiter //
CREATE PROCEDURE omni_get_dataset_ids()
BEGIN
SELECT id,name FROM datasets;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_cell_ids;
delimiter //
CREATE PROCEDURE omni_get_cell_ids
(IN ds_id INT UNSIGNED, IN cnt INT UNSIGNED)
BEGIN
IF cnt<1 THEN
	SELECT id,name FROM 
	(SELECT c.id,m.name,c.priority_weight FROM cells c LEFT JOIN cell_metadata m on m.id=c.meta_id WHERE c.dataset_id=ds_id AND c.status=0 AND display=1) t 
	ORDER BY priority_weight,id;
ELSE	
	SELECT id,name FROM 
	(SELECT c.id,m.name,c.priority_weight FROM cells c LEFT JOIN cell_metadata m on m.id=c.meta_id WHERE c.dataset_id=ds_id AND c.status=0 AND c.display=1 LIMIT cnt) t 
	ORDER BY priority_weight,id;
END IF;
END; //
delimiter ;



DROP PROCEDURE IF EXISTS omni_login;
delimiter //
CREATE PROCEDURE omni_login
(IN user_name CHAR(32))
BEGIN 
SELECT id,level FROM users WHERE name=user_name;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_make_parent_id_tbl;
delimiter //
CREATE PROCEDURE omni_make_parent_id_tbl()
thisproc:BEGIN
DECLARE cnt INT UNSIGNED DEFAULT 0;
DECLARE nrow INT UNSIGNED;
DECLARE depth_ INT UNSIGNED;
DECLARE ledge_ BIGINT UNSIGNED;
DECLARE redge_ BIGINT UNSIGNED;
DECLARE cid_ BIGINT UNSIGNED;
DECLARE pid_ BIGINT UNSIGNED;
DECLARE cellid_ BIGINT UNSIGNED;
DROP TEMPORARY TABLE IF EXISTS tasklist_pid;
CREATE TEMPORARY TABLE tasklist_pid (
	child_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, parent_id BIGINT UNSIGNED NOT NULL);
SELECT COUNT(*) INTO nrow FROM tasklist;
IF nrow<1 THEN
LEAVE thisproc;
END IF;
REPEAT
SELECT id,cell_id,depth,left_edge,right_edge INTO cid_,cellid_,depth_,ledge_,redge_ FROM tasklist LIMIT cnt,1;
IF depth_<1 THEN
	INSERT INTO tasklist_pid (child_id,parent_id) values (cid_,0);
ELSE
	SELECT id INTO pid_ FROM tasks WHERE cell_id=cellid_ AND status IN (0,2,3) 
	AND depth=(depth_-1) AND left_edge<ledge_ AND right_edge>redge_ LIMIT 1;
	INSERT INTO tasklist_pid (child_id,parent_id) values (cid_,pid_);
END IF;
SET cnt=cnt+1;
UNTIL cnt>=nrow
END REPEAT;
END thisproc; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_compare_task_list_normal;
delimiter //
CREATE PROCEDURE omni_get_compare_task_list_normal 
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS candidate_a;
DROP TEMPORARY TABLE IF EXISTS cons_mine;
CREATE TEMPORARY TABLE candidate_a (
	SELECT id,comparison_group_id AS gid,latest_consensus_version AS max_ver FROM tasks t 
	WHERE cell_id=cid AND status=0 AND progress=3 LIMIT 50);
CREATE TEMPORARY TABLE cons_mine (
	SELECT cons.task_id FROM consensuses cons INNER JOIN candidate_a can 
	ON can.id=cons.task_id AND can.gid=cons.comparison_group_id AND can.max_ver=cons.version 
	WHERE cons.user_id=uid AND cons.status=3);
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id INNER JOIN candidate_a can ON can.id=t.id 
	LEFT JOIN cons_mine mine ON mine.task_id=t.id 
	WHERE mine.task_id IS NULL AND t.cell_id=cid AND t.progress=3 AND t.status=0 LIMIT 20);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_compare_task_list_completed;
delimiter //
CREATE PROCEDURE omni_get_compare_task_list_completed
(IN cid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DROP TEMPORARY TABLE IF EXISTS candidate_a;
DROP TEMPORARY TABLE IF EXISTS cons_mine;
CREATE TEMPORARY TABLE candidate_a (
	SELECT id,comparison_group_id AS gid FROM tasks t 
	WHERE cell_id=cid AND status=0 AND progress IN (5,6) LIMIT 50);
CREATE TEMPORARY TABLE cons_mine (
	SELECT DISTINCT cons.task_id FROM consensuses cons 
	INNER JOIN candidate_a can ON can.id=cons.task_id AND can.gid=cons.comparison_group_id 
	WHERE cons.user_id=uid AND cons.status=2);
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id 
	INNER JOIN cons_mine mine ON mine.task_id=t.id 
	WHERE t.cell_id=cid AND t.progress IN (5,6) AND t.status=0 LIMIT 20);
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_compare_task_info_byid;
delimiter //
CREATE PROCEDURE omni_get_compare_task_info_byid
(IN tid BIGINT UNSIGNED)
BEGIN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,cmp.group_id,cmp.type,cmp.segment_groups,cmp.segment_group_sizes,u.name 
FROM tasks t 
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN comparisons cmp ON cmp.task_id=t.id AND cmp.group_id=t.comparison_group_id 
INNER JOIN validations val ON val.id=cmp.validations_id 
INNER JOIN users u ON u.id=val.user_id 
WHERE t.id=tid AND t.status IN (0,2) AND t.progress IN (3,5,6) LIMIT 4;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_compare_task_info_normal;
delimiter //
CREATE PROCEDURE omni_get_compare_task_info_normal
(IN tid BIGINT UNSIGNED)
BEGIN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,cmp.group_id,cmp.type,cmp.segment_groups,cmp.segment_group_sizes,u.name 
FROM tasks t 
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN comparisons cmp ON cmp.task_id=t.id AND cmp.group_id=t.comparison_group_id  
INNER JOIN validations val ON val.id=cmp.validations_id 
INNER JOIN users u ON u.id=val.user_id 
WHERE t.id=tid AND t.status=0 AND t.progress=3 LIMIT 4;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_compare_task_info_completed;
delimiter //
CREATE PROCEDURE omni_get_compare_task_info_completed
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path,cmp.group_id,cmp.type,cmp.segment_groups,cmp.segment_group_sizes,u.name 
FROM tasks t 
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN comparisons cmp ON cmp.task_id=t.id AND cmp.group_id=t.comparison_group_id 
INNER JOIN validations val ON val.id=cmp.validations_id 
INNER JOIN users u ON u.id=val.user_id 
INNER JOIN consensuses cons ON cons.comparison_group_id=t.comparison_group_id AND cons.version=t.latest_consensus_version 
WHERE t.id=tid AND t.progress IN (5,6) AND t.status=0 AND cons.user_id=uid AND cons.status=2 LIMIT 4;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_to_start_comparison_task;
delimiter //
CREATE PROCEDURE omni_update_to_start_comparison_task
(IN tid BIGINT UNSIGNED, IN gid BIGINT UNSIGNED, IN uid INT UNSIGNED) 
BEGIN
DECLARE max_ver SMALLINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET progress=4 WHERE id=tid;
SELECT latest_consensus_version INTO max_ver FROM tasks WHERE id=tid;
INSERT INTO consensuses (task_id,user_id,comparison_group_id,version,segments,duration,inspected,status) 
values (tid,uid,gid,max_ver,"",0,1,1);
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_exist_comparing_sts_in_consensuses;
delimiter //
CREATE PROCEDURE omni_get_exist_comparing_sts_in_consensuses
(IN tid BIGINT UNSIGNED, IN gid BIGINT UNSIGNED, IN uid INT UNSIGNED, OUT exist BIGINT UNSIGNED)
BEGIN
SELECT id INTO exist FROM consensuses 
WHERE task_id=tid AND comparison_group_id=gid AND status=1 LIMIT 1;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_submit_comparison_task;
delimiter //
CREATE PROCEDURE omni_submit_comparison_task
(IN tid BIGINT UNSIGNED, IN gid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN ptime INT UNSIGNED, IN seglist MEDIUMTEXT)
BEGIN
DECLARE cons_id BIGINT UNSIGNED;
DECLARE maxver SMALLINT UNSIGNED;
DECLARE exist_ BIGINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
DECLARE CONTINUE HANDLER FOR NOT FOUND
START TRANSACTION;
SELECT id INTO cons_id FROM consensuses WHERE task_id=tid AND comparison_group_id=gid AND user_id=uid AND status=1 LIMIT 1;
IF cons_id IS NULL THEN
	SIGNAL SQLSTATE 'ERROR' SET MESSAGE_TEXT='No data - zero rows selected(cons_id)', MYSQL_ERRNO=1329;
END IF;
SELECT latest_consensus_version INTO maxver FROM tasks WHERE id=tid;
UPDATE consensuses SET version=(maxver+1),inspected=0,duration=(duration+ptime),status=2,segments=seglist 
WHERE id=cons_id;
CALL omni_get_exist_comparing_sts_in_consensuses(tid,gid,uid,exist_);
IF exist_ IS NULL THEN 
UPDATE tasks SET progress=5,latest_consensus_version=(maxver+1) WHERE id=tid;
ELSE 
UPDATE tasks SET latest_consensus_version=(maxver+1) WHERE id=tid;
END IF;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_skip_comparison_task;
delimiter //
CREATE PROCEDURE omni_skip_comparison_task
(IN tid BIGINT UNSIGNED, IN gid BIGINT UNSIGNED, IN uid INT UNSIGNED)
BEGIN
DECLARE cons_id BIGINT UNSIGNED;
DECLARE my_ver SMALLINT UNSIGNED;
DECLARE exist_ing TINYINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
DECLARE CONTINUE HANDLER FOR NOT FOUND
START TRANSACTION;
SELECT id,version INTO cons_id,my_ver FROM consensuses 
WHERE task_id=tid AND comparison_group_id=gid AND user_id=uid AND status=1 LIMIT 1;
IF cons_id IS NULL THEN
	SIGNAL SQLSTATE 'ERROR' SET MESSAGE_TEXT='No data - zero rows selected(cons_id)', MYSQL_ERRNO=1329;
END IF;
UPDATE consensuses SET status=3 WHERE id=cons_id;
CALL omni_get_exist_comparing_sts_in_consensuses(tid,gid,uid,exist_ing);
IF exist_ing IS NULL THEN
UPDATE tasks SET progress=IF(latest_consensus_version>my_ver,5,3) WHERE id=tid;
END IF;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_update_notes;
delimiter //
CREATE PROCEDURE omni_update_notes
(IN tid BIGINT UNSIGNED, IN memo TEXT)
BEGIN
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET notes=memo WHERE id=tid;
COMMIT;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_task_list_byid;
delimiter //
CREATE PROCEDURE omni_get_task_list_byid
(IN tid BIGINT UNSIGNED)
BEGIN
DECLARE task_status TINYINT UNSIGNED;
DECLARE parent_ BIGINT UNSIGNED;
DROP TEMPORARY TABLE IF EXISTS tasklist;
CREATE TEMPORARY TABLE tasklist (
	SELECT t.id,t.cell_id,t.notes,t.depth,t.left_edge,t.right_edge,t.progress,t.status,vol.path FROM tasks t 
	INNER JOIN volumes vol ON vol.id=t.volume_id 
	WHERE t.id=tid LIMIT 1);
SELECT status INTO task_status FROM tasklist WHERE id=tid;
IF task_status=1 OR task_status=4 THEN
SET parent_=tid;
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,parent_ AS parent_id FROM tasklist tl;
ELSE
CALL omni_make_parent_id_tbl();
SELECT tl.id,tl.cell_id,tl.notes,tl.path,tl.progress,tl.status,tlp.parent_id FROM tasklist tl 
INNER JOIN tasklist_pid tlp ON tlp.child_id=tl.id;
END IF;
END; //
delimiter ;


DROP PROCEDURE IF EXISTS omni_get_view_task_info_byid;
delimiter //
CREATE PROCEDURE omni_get_view_task_info_byid
(IN tid BIGINT UNSIGNED)
BEGIN
DECLARE cons_id BIGINT UNSIGNED;
SELECT cons.id INTO cons_id FROM consensuses cons INNER JOIN tasks t 
ON t.id=cons.task_id AND t.comparison_group_id=cons.comparison_group_id AND t.latest_consensus_version=cons.version 
WHERE t.id=tid AND cons.status=2 LIMIT 1;
IF cons_id IS NULL THEN
SELECT id INTO cons_id FROM (
	SELECT cons.id,cons.comparison_group_id AS gid,version FROM consensuses cons INNER JOIN tasks t 
	ON t.id=cons.task_id WHERE t.id=tid AND cons.status=2) t ORDER BY gid DESC, version DESC LIMIT 1;
END IF;
SELECT t.id,t.cell_id,t.notes,t.spawning_coordinate,vol.path,cons.segments 
FROM tasks t 
INNER JOIN volumes vol ON vol.id=t.volume_id 
INNER JOIN consensuses cons ON cons.task_id=t.id 
WHERE t.id=tid AND cons.id=cons_id LIMIT 1;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_get_editing_task_info_byid;
delimiter //
CREATE PROCEDURE omni_get_editing_task_info_byid
(IN tid BIGINT UNSIGNED)
BEGIN
SELECT t.id,t.cell_id,t.notes,t.seeds,t.spawning_coordinate,vol.path FROM tasks t 
INNER JOIN volumes vol ON vol.id=t.volume_id 
WHERE t.id=tid AND t.status IN (0,2,3) LIMIT 1;
END; //
delimiter ;

DROP PROCEDURE IF EXISTS omni_submit_editing_task;
delimiter //
CREATE PROCEDURE omni_submit_editing_task
(IN tid BIGINT UNSIGNED, IN uid INT UNSIGNED, IN seglist MEDIUMTEXT, IN ptime INT UNSIGNED)
BEGIN
DECLARE gid BIGINT UNSIGNED;
DECLARE ver SMALLINT UNSIGNED;
DECLARE EXIT HANDLER FOR SQLWARNING
BEGIN
	ROLLBACK;
	SHOW WARNINGS;
END;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
BEGIN
	ROLLBACK;
	SHOW ERRORS;
END;
START TRANSACTION;
UPDATE tasks SET seeds=seglist,latest_consensus_version=latest_consensus_version+1 WHERE id=tid;
SELECT comparison_group_id,latest_consensus_version INTO gid,ver FROM tasks WHERE id=tid;
INSERT INTO consensuses (task_id,user_id,comparison_group_id,version,segments,duration,inspected,status) 
values (tid,uid,gid,ver,seglist,ptime,0,2);
COMMIT;
END; //
delimiter ;
