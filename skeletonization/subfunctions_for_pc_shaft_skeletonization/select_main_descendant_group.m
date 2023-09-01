function [main_ancestral_task,main_descendant_group] =select_main_descendant_group (ancestral_tasks,descendants,voxel_list,cc_voxels)

    miplevel_input_cc_voxel = 3;
    miplevel_voxel_list = 0;
    mip_factor = 2^(miplevel_input_cc_voxel-miplevel_voxel_list);
    scaling_factor = [1 1 4];

    % 1. upscale the cc_voxels to aniso mip0
        % (!) need test the coincidence of voxels after upscaling
    cc_voxels_upscaled = cc_voxels .* mip_factor ./ scaling_factor;

    % 2. count the number of common voxels
    number_of_common_voxels = cellfun(@(v) sum(ismember(v,cc_voxels_upscaled,'rows')),voxel_list);
    [max_number_of_common_voxels,ind_max_number_of_common_voxels] = max(number_of_common_voxels);
    number_of_descendant_groups_with_max_number = sum(number_of_common_voxels==max_number_of_common_voxels);

    % 3. select the main ancestral task
        % : if there are groups with the same size, choose larger(# of tasks) one, shallower one, former(smaller left edge value) one 
    if number_of_descendant_groups_with_max_number == 1
        % criterion i) common voxel size
        main_ancestral_task = ancestral_tasks(ind_max_number_of_common_voxels,:);
        main_descendant_group = descendants{ind_max_number_of_common_voxels};
    else
        ancestors_max_in_voxel = ancestral_tasks(number_of_common_voxels==max_number_of_common_voxels,:);
        descendants_max_in_voxel = descendants(number_of_common_voxels==max_number_of_common_voxels);
        number_of_tasks_in_group = cellfun(@(g) numel(g),descendants_max_in_voxel);
        [max_task_num,ind_max_task_num] = max(number_of_tasks_in_group);
        number_of_max_task_group = sum(number_of_tasks_in_group==max_task_num);
        if number_of_max_task_group == 1
            % criterion ii) task group length
            main_ancestral_task = ancestors_max_in_voxel(ind_max_task_num,:);
            main_descendant_group = descendants_max_in_voxel{ind_max_task_num};
        else
            ancestors_max_max = ancestors_max_in_voxel(number_of_tasks_in_group==max_task_num,:);
            descendants_max_max = descendants_max_in_voxel(number_of_tasks_in_group==max_task_num);
            depth_ancestors_max_max = ancestors_max_max(:,2);
            [max_depth,ind_max_depth] = max(depth_ancestors_max_max);
            number_of_max_depth_group = sum(depth_ancestors_max_max==max_depth);
            if number_of_max_depth_group == 1
                % criterion iii) depth
                main_ancestral_task = ancestors_max_max(ind_max_depth,:);
                main_descendant_group = descendants_max_max{ind_max_depth};
            else
                % criterion iv) former
                ancestors_max_max_max = ancestors_max_max(depth_ancestors_max_max==max_depth,:);
                descendants_max_max_max = descendants_max_max(depth_ancestors_max_max==max_depth);
                [~,ind_minimum_left_edge] = min(ancestors_max_max_max(:,3));
                main_ancestral_task = ancestors_max_max_max(ind_minimum_left_edge,:);
                main_descendant_group = descendants_max_max_max{ind_minimum_left_edge};
            end
        end
    end

end