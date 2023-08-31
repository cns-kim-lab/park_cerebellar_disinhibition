delimiter //
drop procedure if exists r_tree_traversal //
create procedure r_tree_traversal(IN pparent_id int)

begin

DECLARE new_lft int;

SELECT rgt INTO new_lft FROM tree_map WHERE node_id = pparent_id;
UPDATE tree_map SET rgt = rgt + 2 WHERE rgt >= new_lft;
UPDATE tree_map SET lft = lft + 2 WHERE lft > new_lft;
INSERT INTO tree_map (lft, rgt, parent_id) VALUES (new_lft, (new_lft + 1), pparent_id);
SELECT LAST_INSERT_ID();

end
//
delimiter ;


call r_tree_traversal(1);

