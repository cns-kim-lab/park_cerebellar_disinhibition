function [ancestral_tasks,descendants,voxel_list] = find_descendant_groups_in_task_list (task_info, volume_info, main_or_not)
% from a list of tasks & its corresponding volume info,
% return the task info of the ancestral tasks of shaft cc, descendants, and its voxels
 
% keep every independent branch
 
    default_vol_size = [512 512 128];
    default_overlap_size = [32 32 8]; 
    
    % 1) find parents of each task
    [task_list,sort_ind] = sortrows(task_info,2,'descend');
    volume_list = volume_info(sort_ind,:);
%     volume_list(:,1) = volume_info(sort_ind,1);
%     volume_list(:,2) = volume_info(sort_ind,2);
%     volume_list(:,3) = volume_info(sort_ind,3);
    parent_list = zeros([size(task_list,1) 1]);

    %       i) list all tasks with the lowest depth    
    %               plus, all tasks with higher depth, sorted in descending order of depth number  
    depth_list = sort(unique(task_list(:,2)),'descend');    
    
    % loop over depth
    %       ii) empty the list finding the parent task of each
    %           : if a task has no parent, it becomes a parent of
    %             isolated tasks (parent = 0)

    while ~isempty(depth_list)
    %       iii) fill a queue with tasks with next lowest depth
        current_depth = depth_list(1);
        queue_current_depth = find(task_list(:,2)==current_depth);
        queue_shallow_tasks = find(task_list(:,2)<current_depth);
    
        for cn = 1:length(queue_current_depth)
            current_task_ind = queue_current_depth(cn);
            current_task_id = task_list(current_task_ind,1);
            current_task_left_edge = task_list(current_task_ind,3);
            current_task_right_edge = task_list(current_task_ind,4);
                % check all 'upper' tasks
                % access the lower tasks first
                
            for sn = 1:length(queue_shallow_tasks)
                shallow_task_ind = queue_shallow_tasks(sn);
                shallow_task_id = task_list(shallow_task_ind,1);
                shallow_task_left_edge = task_list(shallow_task_ind,3);
                shallow_task_right_edge = task_list(shallow_task_ind,4);
                if (shallow_task_left_edge < current_task_left_edge) && (current_task_right_edge < shallow_task_right_edge)
                    parent_list(current_task_ind) = shallow_task_id;
                    break;
                end                
            end
            
        end
            
        depth_list = depth_list(2:end);
    end 
    
    % 2) list descendant groups
    [ancestral_tasks,descendants] = list_descendants (task_list,parent_list);
    
    % 3) load voxels
    if main_or_not
        voxel_list = {};
    else
        [cell_of_sub_local, cell_of_offset, ~] = cellfun(@(x,y,z) get_mip_voxel_info_from_volume_metadata (x,y,z,default_vol_size,default_overlap_size),...
                                                                                    volume_list(:,1),volume_list(:,2),volume_list(:,3),'UniformOutput', false);
        % translate to global
        cell_of_sub_global = cellfun(@(x,y) x+y,cell_of_sub_local,cell_of_offset,'UniformOutput',false);
    
        % merge within descendant groups - conserve voxels(global)
        voxel_list = cellfun(@(d) unique(cell2mat(cell_of_sub_global(ismember(task_list(:,1),d))),'rows'),descendants,'UniformOutput',false);
    end

end

% subfunctions

% list_descendants : from parent list, find all descendant tasks
% 'descendants' contain the ancestral task itself
function [indep_ancestors,descendants] = list_descendants (task_list,parent_list)
    indep_ancestors = task_list(find(parent_list==0),:);
    descendants = cell(size(indep_ancestors,1),1);
    for i = 1:size(indep_ancestors,1)
        queue_parent = indep_ancestors(i,1);
        descendants{i} = indep_ancestors(i,:);
        while ~isempty(queue_parent)
            current_parent = queue_parent(1);
            % search tasks with current parent
            descendant_tasks = task_list(parent_list==current_parent,:);
            % add them into queue_parent
            % and insert to descendants
            descendants{i} = [descendants{i}; descendant_tasks];
            queue_parent = [queue_parent(2:end) descendant_tasks(:,1)'];
        end
    end
end

    
    