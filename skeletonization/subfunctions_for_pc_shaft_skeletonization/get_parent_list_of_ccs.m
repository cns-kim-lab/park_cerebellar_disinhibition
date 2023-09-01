function [parent_cc_list, nearest_task_in_parent_cc] = get_parent_list_of_ccs (ancestral_tasks,descendants)
    
    parent_cc_list = cell([size(ancestral_tasks,1) 1]);
    nearest_task_in_parent_cc = zeros([size(ancestral_tasks,1) 1]);
    depth_list = sort(unique(ancestral_tasks(:,2)),'descend');

    while ~isempty(depth_list)

        current_depth = depth_list(1);
        queue_current_depth = find(ancestral_tasks(:,2)==current_depth);
        
        for cn = 1:length(queue_current_depth)
            current_task_ind = queue_current_depth(cn);
            current_task_ancestral_task_info = ancestral_tasks(current_task_ind,:);
            current_task_left_edge = ancestral_tasks(current_task_ind,3);
            current_task_right_edge = ancestral_tasks(current_task_ind,4);
            
            ind_shallow_tasks = setdiff(find(ancestral_tasks(:,3)<=current_task_left_edge ...
                                & ancestral_tasks(:,4)>=current_task_right_edge),current_task_ind);
            
            shallow_tasks = ancestral_tasks(ind_shallow_tasks,:);
            shallow_descendants = descendants(ind_shallow_tasks);
            
            [nearest_task,depth_nearest_task] = extract_nearest_task (current_task_ancestral_task_info,shallow_descendants);
            max_nearest_depth = max(depth_nearest_task);
            ind_max_nearest_depth = find(depth_nearest_task == max_nearest_depth);
            
            if ~isempty(ind_max_nearest_depth)
                parent_cc_list{current_task_ind} = shallow_tasks(ind_max_nearest_depth,5);
                nearest_task_in_parent_cc(current_task_ind) = unique(nearest_task(ind_max_nearest_depth));
            end
        end
        
        depth_list = depth_list(2:end);
    end 
end

function  [nearest_task,depth_nearest_task] = extract_nearest_task (ancestral_task_offspring,descendants_parents)
           
%     depth_offspring = ancestral_task_offspring(2);
    left_edge_offspring = ancestral_task_offspring(3);
    right_edge_offspring = ancestral_task_offspring(4);
    
    ancestor_tasks_in_parent_cc = cellfun(@(descendant_a) descendant_a(descendant_a(:,3)<=left_edge_offspring & descendant_a(:,4)>=right_edge_offspring,:),descendants_parents,'UniformOutput',false);
    ancestor_tasks_in_parent_cc_sorted = cellfun(@(an_a) sortrows(an_a,2,'descend'),ancestor_tasks_in_parent_cc,'UniformOutput',false);
    nearest_task = cellfun(@(an_s_a) an_s_a(1,1),ancestor_tasks_in_parent_cc_sorted);
    depth_nearest_task = cellfun(@(an_s_a) an_s_a(1,2),ancestor_tasks_in_parent_cc_sorted);
    
end
