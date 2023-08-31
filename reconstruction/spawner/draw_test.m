%%
function draw_test(task1, task2)
addpath /data/research/bahn/code/mysql/


global h_sql
%{
mysql('close'); 
h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
mysql(h_sql, 'use omni');
%h_sql = mysql('open','10.1.26.181','root','1234');
%mysql(h_sql, 'use omni0714t');
%}
%task1 = 7040; task2 = 7084;
[cell1, depth1, left1, right1] = mysql(h_sql, ...
    sprintf(['select cell_id, depth, left_edge, right_edge from tasks where id=%d;'], task1));
[cell2, depth2, left2, right2] = mysql(h_sql, ...
    sprintf(['select cell_id, depth, left_edge, right_edge from tasks where id=%d;'], task2));

%task1 <- task2
if cell1==cell2 && depth1<depth2 && left1<left2 && right1>right2
    draw_subtree(task1,task2)
%task1 -> task2
elseif cell1==cell2 && depth1>depth2 && left1>left2 && right1<right2
    draw_subtree(task2,task1)
else
    subplot(2,1,1)
    draw_subtree(task1,task1)
    subplot(2,1,2)
    draw_subtree(task2,task2)
end

%mysql('close');     
 
end
%%
function draw_subtree(task1,task2)

global h_sql

[cell1, depth1, left1, right1, status1] = mysql(h_sql, ...
    sprintf(['select cell_id, depth, left_edge, right_edge, status from tasks where id=%d;'], task1));

parent = []; par_depth = [];
if depth1~=0
    [parent, par_depth, par_left, par_right] = mysql(h_sql, ...
        sprintf(['select id, depth, left_edge, right_edge from tasks ' ...
        'where cell_id=%d && depth=%d && left_edge<%d && right_edge>%d'],cell1,depth1-1,left1,right1));
end
    
[child_list, child_depth, child_left, child_right] = mysql(h_sql, ...
    sprintf(['select id, depth, left_edge, right_edge from tasks ' ...
    'where cell_id=%d && depth>%d && left_edge>%d && right_edge<%d && status!=1'],cell1,depth1,left1,right1));

tree_depth = [par_depth depth1 child_depth'];
tree_left = [par_left left1 child_left'];
tree_right = [par_right right1 child_right'];
labels = [parent task1 child_list'];

tree_ind = [1:length(tree_depth)];

tree_depth = tree_depth - min(tree_depth);
tree_nodes = zeros(1,length(tree_depth));

for i=1:length(tree_depth)
    
    if tree_depth(i)==0
       tree_nodes(i)=0;
    else
        ind = intersect( intersect( find( (tree_depth(:) == tree_depth(i)-1) ), ...
            find( tree_left(:) < tree_left(i) ) ), ...
            find( tree_right(:) > tree_right(i) ) );
        tree_nodes(i) = ind;
    end
    
end

hold off
treeplot(tree_nodes);
hold on
[x,y] = treelayout(tree_nodes);

for i=1:length(x)
    
    if (labels(i)==task1) || (labels(i)==task2)
        text(x(i),y(i),num2str(labels(i)),'FontWeight','bold');
    else
        text(x(i),y(i),num2str(labels(i)));
    end
end

if status1==1
   text(0,0,sprintf('Status of task %d is "stashed"\n',task1)); 
end

end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    