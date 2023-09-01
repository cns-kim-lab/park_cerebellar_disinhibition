% Apply TEASAR algorithm to purkinje cell dendritic shaft, which was disconnected into several connected components after the separation of shaft and spine parts.

% This code refers to the mysql database 

% input variables
%   input_h5_file_path : path for the h5 file containing shaft-spine separated segmentations of the target purkinje cell.
%   target_cell_id : the id of the purkinje cell. 
%   output_

function skeletonize_pc_shaft_components_recursively (input_h5_file_path, output_dir, target_cell_id, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

    addpath ./subfunctions_for_pc_shaft_skeletonization/
    % input_h5_file_path = '/data/research/iys0819/cell_morphology_pipeline/volumes/shaft_spine_separation.iso_mip1.e7.th20000.d14.ds_to_iso_mip3.h5';
    roots_of_target_pc_file_path = './additional_infos/roots_of_shafts_in_shaft-spine_separation_volume.mat';

    vol_iso_mip3 = h5read(input_h5_file_path,'/main');
    load(roots_of_target_pc_file_path,'roots_of_target_pcs_iso_mip3_voxels');

    fprintf('shaft skeletonization of cell %d\n',target_cell_id);
    rt_pnt_in_vol_shaft_iso_mip3 = roots_of_target_pcs_iso_mip3_voxels(roots_of_target_pcs_iso_mip3_voxels(:,1)==target_cell_id,2:4);

    %% constants
    threshold_in_iso_mip3 = 100;
    default_vol_size = [512 512 128];
    default_overlap_size = [32 32 8];
    %% teasar parameters
    close_or_not = 0;
    p_scale = 1.05;
    p_const = 10;
    
    %% output file name
    result_file_name = sprintf('%s/shaft_skeleton_of_cell_%d.ps_%.3f_pc_%d.mat',output_dir,target_cell_id,p_scale,p_const);


    %% 1. get ccs from shaft
    fprintf('\t analyzing ccs\n');
    vol_target_shaft_iso_mip3 = vol_iso_mip3 == (target_cell_id*10+1);
    cc_vol_target_shaft_iso_mip3 = bwconncomp(vol_target_shaft_iso_mip3);
    vol_size = cc_vol_target_shaft_iso_mip3.ImageSize;
    cc_voxels_vol_target_shaft_iso_mip3 = cc_vol_target_shaft_iso_mip3.PixelIdxList;

    %% 2. threshold the shaft ccs
    num_cc_voxels = cellfun(@length, cc_voxels_vol_target_shaft_iso_mip3);
    cc_voxels_vol_arget_shaft_iso_mip3_over_threshold = cc_voxels_vol_target_shaft_iso_mip3(num_cc_voxels>=threshold_in_iso_mip3);

    [x,y,z] = cellfun(@(cc) ind2sub(vol_size,cc),cc_voxels_vol_arget_shaft_iso_mip3_over_threshold,'UniformOutput',false);
    component_iso_mip3 = cellfun(@(a,b,c) [a b c], x,y,z, 'UniformOutput',false);
    component_iso_mip3_ind = cc_voxels_vol_arget_shaft_iso_mip3_over_threshold;
    component = cellfun(@(a,b,c) [a b c] .* 2^(3-0), x,y,z, 'UniformOutput',false);

    %% 3. choose main_cc

    rt_pnt_in_vol_shaft_iso_mip0 = rt_pnt_in_vol_shaft_iso_mip3 .* 2^(3-0);
    ind_main_cc = find(cellfun(@(cc) ismember(rt_pnt_in_vol_shaft_iso_mip0,cc,'rows'),component));
    ind_sub_cc = setdiff(1:length(component),ind_main_cc);
    fprintf('\t Done.\n');

    %% 4. get task_info, volume_info of ccs
    fprintf('\t task & volume info of sub components\n');
    [task_info_sub,volume_info_sub] = cellfun(@(c) find_task_about_multiple_coord(c, floor(target_cell_id./100), mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd),component(ind_sub_cc),'UniformOutput',false);
    fprintf('\t Done.\n');
    fprintf('\t task & volume info of the main component\n');
    [task_info_main,volume_info_main] = find_task_about_multiple_coord(component{ind_main_cc}, floor(target_cell_id./100), mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
    fprintf('\t Done.\n');
    % Elapsed time is 3668.576416 seconds.

    task_info_file_name = sprintf('%s/task_info_of_shaft_of_cell_%d.mat',output_dir,target_cell_id);
    save(task_info_file_name,'task_info_sub','volume_info_sub','task_info_main','volume_info_main');

    %% 5. extract task trees of ccs
    % tic;
    fprintf('\t building task trees of sub ccs\n');
    [ancestral_tasks_sub,descendants_sub,voxel_list_sub] = cellfun(@(t,v) find_descendant_groups_in_task_list (t,v,0),...
                                                                            task_info_sub,volume_info_sub,'UniformOutput',false);
    fprintf('\t Done.\n');                                                                    
    % toc;
    % Elapsed time is 160.157988 seconds.
    %%
    fprintf('\t building task trees of main ccs\n');
    [ancestral_tasks_main,descendants_main] = find_descendant_groups_in_task_list(task_info_main,volume_info_main,1);
    fprintf('\t Done.\n');
    %% 6. select dominant descendant groups of sub_ccs

    % tic;
    fprintf('\t selecting dominant descendant groups\n');
    [ancestral_tasks_sub_dom,descendants_sub_dom] = cellfun(@(a,d,v,c) select_main_descendant_group (a,d,v,c),...
                                                                    ancestral_tasks_sub,...
                                                                    descendants_sub,...
                                                                    voxel_list_sub,...
                                                                    cc_voxels_vol_arget_shaft_iso_mip3_over_threshold(ind_sub_cc),...
                                                                    'UniformOutput',false);
    ancestral_tasks_sub_dom = cell2mat(ancestral_tasks_sub_dom');
    descendants_sub_dom = descendants_sub_dom';
    fprintf('\t Done.\n');
    % toc;
    % Elapsed time is 33.933767 seconds.

    %% 7. wrap the main & sub cc descendant group infos

    fprintf('\t wrapping descendant group infos\n');
    ancestral_tasks_total = [ancestral_tasks_main, ind_main_cc; ancestral_tasks_sub_dom, ind_sub_cc'];
    descendants_total = cell(length(descendants_main)+length(descendants_sub_dom),1);
    descendants_total(1:length(descendants_main)) = descendants_main(1:end);
    descendants_total(length(descendants_main)+1:end) = descendants_sub_dom(1:end);
    fprintf('\t Done.\n');
    %% 8. get 'parent list' of ccs

    fprintf('\t get parent list of ccs\n');
    [parent_cc_list,nearest_task_in_parent_cc] = get_parent_list_of_ccs (ancestral_tasks_total,descendants_total);
    % 'parent_cc_list' : list of ccs that possess the most nearest task (including itself) ancestral to the most ancestral task of a cc
    fprintf('\t Done.\n');

    %% 9. get route to parent of each cc : it also determines the roots for each cc
    % tic;
    fprintf('\t get route to parent of each cc\n');
    [sub_cc_order, parent_of_sub_cc, route_to_parent_cc, dbf_of_route_to_parent_cc]  = get_route_to_parent_cc (ancestral_tasks_total,parent_cc_list,nearest_task_in_parent_cc,component_iso_mip3,ind_main_cc,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
    % toc;
    fprintf('\t Done.\n');
    %% 10. componentwise skeletonization
    fprintf('\t componentwise skeletonization\n');
    source_point_of_each_sub_cc_in_sub_cc_order = cellfun(@(route_a) route_a(1,:),route_to_parent_cc,'UniformOutput',false);
    source_point_list = [rt_pnt_in_vol_shaft_iso_mip3, source_point_of_each_sub_cc_in_sub_cc_order];
    cc_order = [ind_main_cc; sub_cc_order];
    %
    % i) main & its descendants
    % tic;
    [skeleton_of_ccs_pos, skeleton_of_ccs_dbf, ~, ~, dil_count] = cellfun(@(cc,source_point) get_skeleton_of_connected_component(cc, vol_size, source_point, close_or_not, p_scale, p_const),...
                                                                    component_iso_mip3_ind(cc_order),source_point_list,'UniformOutput',false);
    % toc;
    % Elapsed time is 293.940907 seconds.
    % (generalization unfinished)
    % *ii) ancestors of the main
    % *iii) other descendant ccs of depth-0 task
    fprintf('\t Done.\n');
    %% 11. prolong the routes to parent to their parent's skeleton voxel
    fprintf('\t extend the routes to parent to reach the skeleton of parent\n');
    % list the parents
    parent_cc_ind = unique(parent_of_sub_cc);
    parent_cc_ind_cell = mat2cell(parent_cc_ind,ones(size(parent_cc_ind)));
    skeleton_merged_parent = arrayfun(@(parent) cell2mat(skeleton_of_ccs_pos{find(cc_order==parent)}'),parent_cc_ind,'UniformOutput',false);
    source_point_parent = arrayfun(@(parent) source_point_list{cc_order==parent},parent_cc_ind,'UniformOutput',false);

    % list the offsprings of parents
    offspring_cc = arrayfun(@(parent) sub_cc_order(find(parent_of_sub_cc==parent)),parent_cc_ind,'UniformOutput',false);
    route_short = arrayfun(@(parent) route_to_parent_cc(find(parent_of_sub_cc==parent)),parent_cc_ind,'UniformOutput',false);
    dbf_short = arrayfun(@(parent) dbf_of_route_to_parent_cc(find(parent_of_sub_cc==parent)),parent_cc_ind,'UniformOutput',false);

    % extend the routes
    [route_extended,dbf_route_extended] = cellfun(@(parent_cc_ind,skel_parent,source_parent,route,dbf) extend_route_to_parent_cc_to_skeleton(component_iso_mip3_ind{parent_cc_ind},skel_parent,source_parent,vol_size,route,dbf),...
                                                            parent_cc_ind_cell,skeleton_merged_parent,source_point_parent,route_short,dbf_short,'UniformOutput',false);

    % rearrange the results
    route_to_parent_cc_extended = cell(size(route_to_parent_cc));
    dbf_of_route_to_parent_cc_extended = cell(size(dbf_of_route_to_parent_cc));
    for i = 1:length(sub_cc_order)
        sub_cc_ind = sub_cc_order(i);
        [in_offspring_list_or_not,ind_in_offspring_list] = cellfun(@(clist) ismember(sub_cc_ind,clist),offspring_cc);
        offspring_group_ind = find(in_offspring_list_or_not);
        ind_in_offspring_group = ind_in_offspring_list(offspring_group_ind);
        route_to_parent_cc_extended{i} = route_extended{offspring_group_ind}{ind_in_offspring_group};
        dbf_of_route_to_parent_cc_extended{i} = dbf_route_extended{offspring_group_ind}{ind_in_offspring_group};
    end
    route_to_parent_cc_extended = [{[]}, route_to_parent_cc_extended];
    dbf_of_route_to_parent_cc_extended = [{[]}, dbf_of_route_to_parent_cc_extended];

    fprintf('\t Done.\n');
    %% 12. summarize the results and save
    fprintf('\t summarize and save the results\n');
    extended_skeleton_of_ccs_pos = skeleton_of_ccs_pos;
    extended_skeleton_of_ccs_dbf = skeleton_of_ccs_dbf;
    % skeleton_of_ccs_pos doesn't contain the source of each skeleton

    for i = 1:length(extended_skeleton_of_ccs_pos)
        extended_skeleton_of_ccs_pos{i}{1} = [skeleton_of_ccs_pos{i}{1}; route_to_parent_cc_extended{i}];
        extended_skeleton_of_ccs_dbf{i}{1} = [skeleton_of_ccs_dbf{i}{1} dbf_of_route_to_parent_cc_extended{i}'];
    end

    extended_merged_skeleton_of_ccs_pos = cell(size(extended_skeleton_of_ccs_pos));
    extended_merged_skeleton_of_ccs_dbf = cell(size(extended_skeleton_of_ccs_dbf));
    for i = 1:length(extended_merged_skeleton_of_ccs_dbf)
        [extended_merged_skeleton_of_ccs_pos{i},inds] = unique(cell2mat(extended_skeleton_of_ccs_pos{i}'),'rows','stable');
        dbf_temp = cell2mat(extended_skeleton_of_ccs_dbf{i});
        extended_merged_skeleton_of_ccs_dbf{i} = dbf_temp(inds);
    end

    [merged_skeleton_total_pos,inds] = unique(cell2mat(extended_merged_skeleton_of_ccs_pos'),'rows','stable');
    merged_skeleton_total_dbf = cell2mat(extended_merged_skeleton_of_ccs_dbf);
    merged_skeleton_total_dbf = merged_skeleton_total_dbf(inds);

    save(result_file_name,'target_cell_id','p_scale','p_const','threshold_in_iso_mip3',...
                            'skeleton_of_ccs_pos','skeleton_of_ccs_dbf',...
                            'route_to_parent_cc','dbf_of_route_to_parent_cc',...
                            'route_to_parent_cc_extended','dbf_of_route_to_parent_cc_extended',...
                            'extended_skeleton_of_ccs_pos','extended_skeleton_of_ccs_dbf',...
                            'merged_skeleton_total_pos','merged_skeleton_total_dbf','-v7.3');
    fprintf('Done.\n');
end