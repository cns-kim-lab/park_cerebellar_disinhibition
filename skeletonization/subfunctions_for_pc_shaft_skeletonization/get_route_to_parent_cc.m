function [sub_cc_order, parent_of_sub_cc, route_to_parent_cc, dbf_of_route_to_parent_cc]  = get_route_to_parent_cc (ancestral_tasks_total,parent_cc_list,nearest_task_in_parent_cc,component_iso_mip3,ind_main_cc,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)
% return the parent cc ind and the route to the parent
    addpath ./mysql/

    %% constants
    scaling_factor_of_original_volume = [1 1 4];
    working_mip_level = 3;
    default_vol_size = [512 512 128];
    default_overlap_size = [32 32 8]; 

    %% list the links (pair of tasks - col 1 : task of parent, nearest to the ancestral task of offspring, col 2 : ancestral task of offspring)
    link_list = [nearest_task_in_parent_cc, ancestral_tasks_total(:,1)];
    
    %% provide referece task list, filling the blanks between start & end of indirect links
    [reference_task_list,~] = arrayfun(@(a,b) fill_gap_tasks_between_two_tasks (a,b,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd),link_list(:,1),link_list(:,2),'UniformOutput',false);
                
%         i) descendants of the main cc (including the ccs with the same ancestral task with the main cc)
%                                   : later than the main cc
    descendants_of_main_cc = list_descendants_of_main_cc (parent_cc_list,ancestral_tasks_total,ind_main_cc);
    queue_descendants = descendants_of_main_cc;

    sub_cc_order = [];
    parent_of_sub_cc = [];
    route_to_parent_cc = {};
    dbf_of_route_to_parent_cc = {};

    while ~isempty(queue_descendants)
        % current cc : the very first element of the queue
        current_cc = queue_descendants(1);
        current_link = link_list(current_cc,:);
        % refer the ccs sharing the same link as the current cc
        ccs_sharing_the_current_link = find(link_list(:,1)==link_list(current_cc,1) & link_list(:,2)==link_list(current_cc,2));
        ind_of_ccs_sharing_the_current_link = arrayfun(@(cc_num) find(ancestral_tasks_total(:,5)==cc_num),ccs_sharing_the_current_link);
    
        % identify the common parent
        common_ancestor_cc = setdiff(cell2mat(parent_cc_list(ind_of_ccs_sharing_the_current_link)),ccs_sharing_the_current_link);
        
        % (!) evaluate the distance between ccs
        [path_to_parent_ccs,dbf_path_to_parent_ccs] = arrayfun(@(offspring,offspring_ind) trace_path_to_parent(component_iso_mip3{offspring},...
                                                                                                component_iso_mip3(parent_cc_list{offspring_ind}),...
                                                                                                reference_task_list{offspring_ind},...
                                                                                                scaling_factor_of_original_volume,working_mip_level,default_vol_size,default_overlap_size,...
                                                                                                mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd),...
                                        ccs_sharing_the_current_link,ind_of_ccs_sharing_the_current_link,'UniformOutput',false);
        % mip level of the paths : iso mip3 (same as iso mip3 ccs)
        
        pathlength_to_parent_ccs = cellfun(@(paths_of_a)...
                                                            cellfun(@(path_i) sum(sqrt(sum(diff(path_i,1,1).^2,2))),paths_of_a)...
                                            ,path_to_parent_ccs,'UniformOutput',false);
        [~,ind_min_pathlength] = cellfun(@(pathlength) min(pathlength),pathlength_to_parent_ccs,'UniformOutput',false);
        parent_w_min_pathlength = cellfun(@(parent_list,min_ind) parent_list(min_ind),...
                                                                         parent_cc_list(ind_of_ccs_sharing_the_current_link),ind_min_pathlength);
        route_to_nearest_pathlength = cellfun(@(paths,min_ind) paths{min_ind},...
                                                                    path_to_parent_ccs,ind_min_pathlength,...
                                                                    'UniformOutput',false);
        dbf_route_to_nearest_pathlength = cellfun(@(dbf,min_ind) dbf{min_ind},...
                                                                    dbf_path_to_parent_ccs,ind_min_pathlength,...
                                                                    'UniformOutput',false);

                                                                
        path_to_commom_ancestor_cc = cellfun(@(paths,pl) paths{find(pl==common_ancestor_cc)},path_to_parent_ccs,parent_cc_list(ind_of_ccs_sharing_the_current_link),'UniformOutput',false); 
        dbf_path_to_commom_ancestor_cc = cellfun(@(dbf,pl) dbf{find(pl==common_ancestor_cc)},dbf_path_to_parent_ccs,parent_cc_list(ind_of_ccs_sharing_the_current_link),'UniformOutput',false); 
        pathlength_to_commom_ancestor_cc = cellfun(@(paths) sum(sqrt(sum(diff(paths,1,1).^2,2))),path_to_commom_ancestor_cc);
        [~,order_btw_siblings] = sort(pathlength_to_commom_ancestor_cc,'ascend');

        % set orders between siblings and substitute the route of the 1st cc to the route toward the common parent
        sub_cc_new = ccs_sharing_the_current_link(order_btw_siblings);
        parents_new = parent_w_min_pathlength(order_btw_siblings);
        parents_new(1) = common_ancestor_cc;
        routes_new = route_to_nearest_pathlength(order_btw_siblings);
        routes_new{1} = path_to_commom_ancestor_cc{order_btw_siblings(1)};
        dbf_routes_new = dbf_route_to_nearest_pathlength(order_btw_siblings);
        dbf_routes_new{1} = dbf_path_to_commom_ancestor_cc{order_btw_siblings(1)};
        
        % offspring near to common parent comes first
        % for 1st, select the common parent as a parent in skeletonization
        % from 2nd, select the nearest cc as a parent in skeletonization
        sub_cc_order = [sub_cc_order; sub_cc_new];
        parent_of_sub_cc = [parent_of_sub_cc; parents_new];
        route_to_parent_cc(end+1:end+length(ccs_sharing_the_current_link)) = routes_new;                         
        dbf_of_route_to_parent_cc(end+1:end+length(ccs_sharing_the_current_link)) = dbf_routes_new;                         

        % delete the ordered ccs from the queue
        queue_descendants = setdiff(queue_descendants,ccs_sharing_the_current_link,'stable');
    end

% revision plan : 
    %        ii) ancestors of the main cc 
    %                                   : can be noticed from ancestral_tasks_total
    %                                   : backtrack from the main cc 
    %       iii) distinct branch from the main cc 
    %                                   : match to the main cc and connect
    %                                   through the lost 'depth 0' task

%     Note
    %      i) main comes first at the ancestral_tasks_total & parent_cc_list  
    %     ii) generally, main can have multiple descendant groups  
    %    iii) generally, depth-zero task can belong to a sub cc  

    %%
    
    
    
    %% 
        

end

function descendants = list_descendants_of_main_cc (parent_list_cc,ancestral_tasks_total,ind_main_cc)

    descendants = [];
    queue_parent = ind_main_cc;
    while ~isempty(queue_parent)
        current_parent = queue_parent(1);
        % search tasks with current parent
        current_offsprings = setdiff(ancestral_tasks_total(find(cellfun(@(pl) ismember(current_parent,pl),parent_list_cc)),5),descendants);
        % add them into queue_parent
        % and insert to descendants
        descendants = [descendants; current_offsprings];
        queue_parent = [queue_parent(2:end); current_offsprings];
    end

end

function [path_to_parent_ccs,dbf_of_path_to_parent_ccs] = trace_path_to_parent(comp_offspring, comp_parents, reference_task_list, scaling_factor_of_original_volume, working_mip_level, default_vol_size, default_overlap_size, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

    % i) load voxels of reference task list
    ref_vol_mip0 = load_voxel_from_task_list(reference_task_list, default_vol_size, default_overlap_size, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
    % ii) adjust mip level and scaling factor
    ref_vol = unique(floor(ref_vol_mip0.*scaling_factor_of_original_volume./(2^working_mip_level)),'rows');
    % flooring is similar to '1:skip:end' downsampling  

    % ref) 'identify_roots_.....' code.
    % iii) get pairs of nearest voxels
    [point_in_offspring, point_in_parent] = cellfun(@(comp_a) find_nearest_pair (comp_offspring,comp_a,ref_vol,ref_vol),comp_parents,'UniformOutput',false);

    % iv) route between pairs
    margin = 2;
    [vol_cropped, offset_vol_cropped] = cellfun(@(comp_a) generate_cropped_volume_for_target_ccs (ref_vol, comp_a, comp_offspring, margin),comp_parents,'UniformOutput',false);
    [route_ind, dbf_of_route] = cellfun(@(vol_a,offset_vol_a,point_p,point_o)...
                                                                    get_route_between_points_in_task_volume (vol_a, offset_vol_a, point_p, point_o),...
                                                                    vol_cropped,offset_vol_cropped,point_in_parent,point_in_offspring,'UniformOutput',false);
            
    [path_to_parent_ccs_ind, dbf_of_path_to_parent_ccs] = cellfun(@(route_a,dbf_a,vol_a)...
                    leave_part_between_components_from_route (route_a, dbf_a, vol_a),...
                    route_ind,dbf_of_route,vol_cropped,'UniformOutput',false);

    % % Convert to subscripts
    [route_x,route_y,route_z] = cellfun(@(vol_a,route_ind_a) ind2sub(size(vol_a),route_ind_a),vol_cropped,path_to_parent_ccs_ind,'UniformOutput',false);
    path_to_parent_ccs = cellfun(@(x,y,z,offset) [x y z] + offset, route_x, route_y, route_z, offset_vol_cropped,'UniformOutput',false);   

end

function ref_vol_mip0 = load_voxel_from_task_list(reference_task_list, default_vol_size, efault_overlap_size,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)
   
    volume_info = arrayfun(@(t_id) find_volume_info_from_task_id(t_id, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd),reference_task_list,'UniformOutput',false);
    [net_id_list,xyz,segs] = cellfun(@(c) c{:},volume_info','UniformOutput',false);
    [cell_of_sub_local, cell_of_offset, ~] = cellfun(@(x,y,z) get_mip_voxel_info_from_volume_metadata (x,y,z,default_vol_size,default_overlap_size),net_id_list,xyz,segs,'UniformOutput', false);
    cell_of_sub_global = cellfun(@(x,y) x+y,cell_of_sub_local,cell_of_offset,'UniformOutput',false);
    ref_vol_mip0 = unique(cell2mat(cell_of_sub_global'),'rows');

    
    function [sub_local, offset, mip_vol_size] = get_mip_voxel_info_from_volume_metadata (net_id,vxyz,supervoxel_list,default_vol_size,default_overlap_size)
   
    vol_id = sprintf('x%02d_y%02d_z%02d',vxyz);
    [path_vol,vol_coord_info] = lrrtm3_get_vol_info('/data/lrrtm3_wt_omnivol/',net_id{1},vol_id,1);
    file_path = sprintf('/data/lrrtm3_wt_omnivol/%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',path_vol, 0);       
    chunk = lrrtm3_get_vol_segmentation(file_path,vol_coord_info);
    chunk = ismember(chunk, supervoxel_list); 

    ind_local = find(chunk);
    [x_local,y_local,z_local] = ind2sub(size(chunk),ind_local);
    sub_local = [x_local,y_local,z_local];
    offset = (vxyz - 1) .* (default_vol_size - default_overlap_size);

    mip_vol_size = vol_coord_info.mip_vol_size;
    
end

end

function [point_on_main_body, point_on_target_body] = find_nearest_pair (main_component,target_component,relevant_task_voxel_for_main,relevant_task_voxel_for_target)
    
    intersection_w_target_component = intersect(target_component,relevant_task_voxel_for_target,'rows','stable');
    intersection_w_main_component = intersect(main_component,relevant_task_voxel_for_main,'rows','stable');   

    distance_btw_intersections = pdist2(intersection_w_main_component,intersection_w_target_component);
    
    [~,min_ind] = min(distance_btw_intersections,[],'all','linear');
    [min_ind_main,min_ind_target] = ind2sub(size(distance_btw_intersections),min_ind);
    
    point_on_main_body = intersection_w_main_component(min_ind_main,:);
    point_on_target_body = intersection_w_target_component(min_ind_target,:);

end

function [bbox_task, bbox_offset] = generate_cropped_volume_for_target_ccs (voxel_sub, main_component, target_component, margin)
    
    intersection_w_target_component = intersect(target_component,voxel_sub,'rows','stable');
    intersection_w_main_component = intersect(main_component,voxel_sub,'rows','stable');   

    min_sub = min(voxel_sub,[],1);
    max_sub = max(voxel_sub,[],1);
    size_bbox_task = max_sub - min_sub + 1 + 2 * margin;
    bbox_task = zeros(size_bbox_task);
    bbox_offset = min_sub - margin - 1;
    
    voxel_local_sub = voxel_sub - (min_sub - margin) + 1;
    voxel_local_ind = sub2ind(size_bbox_task, voxel_local_sub(:,1), voxel_local_sub(:,2), voxel_local_sub(:,3));
    
    intersection_w_main_component_local_sub = intersection_w_main_component - (min_sub - margin) + 1;
    intersection_w_target_component_local_sub = intersection_w_target_component - (min_sub - margin) + 1;
    intersection_w_main_component_local_ind = sub2ind(size_bbox_task, intersection_w_main_component_local_sub(:,1), intersection_w_main_component_local_sub(:,2), intersection_w_main_component_local_sub(:,3));
    intersection_w_target_component_local_ind = sub2ind(size_bbox_task, intersection_w_target_component_local_sub(:,1), intersection_w_target_component_local_sub(:,2), intersection_w_target_component_local_sub(:,3));
    
    bbox_task(voxel_local_ind) = 1;
    bbox_task(intersection_w_main_component_local_ind) = 2;
    bbox_task(intersection_w_target_component_local_ind) = 3;
    
end

function [route_between_points_ind_in_bbox_task, dbf_on_route] = get_route_between_points_in_task_volume (bbox_task, bbox_offset, point_on_main_body, point_on_target_body, point_on_main_body_in_bbox_sub, point_on_target_body_in_bbox_sub)

    if ~isempty(point_on_main_body)
        point_on_main_body_in_bbox_sub = point_on_main_body - bbox_offset;
    end
    if ~isempty(point_on_target_body)
        point_on_target_body_in_bbox_sub = point_on_target_body - bbox_offset;
    end

    size_bbox = size(bbox_task);
    dbf = double(bwdist(~logical(bbox_task)));
    [pdrf, indfrom, ~] = dijkstra_root2all (dbf, size_bbox, point_on_main_body_in_bbox_sub, 1);
    pdrf = pdrf .* logical(bbox_task);
    
    route_between_points_ind_in_bbox_task = backtrack_the_route_between_points (pdrf, indfrom, point_on_main_body_in_bbox_sub, point_on_target_body_in_bbox_sub);
    dbf_on_route = dbf(route_between_points_ind_in_bbox_task);
    
end

function route_between_points_ind = backtrack_the_route_between_points (pdrf, indfrom, point_on_main_body_in_bbox_sub, point_on_target_body_in_bbox_sub)

    size_bbox = size(pdrf);
    terminal_ind = sub2ind(size_bbox,point_on_target_body_in_bbox_sub(1),point_on_target_body_in_bbox_sub(2),point_on_target_body_in_bbox_sub(3));
    source_ind = sub2ind(size_bbox,point_on_main_body_in_bbox_sub(1),point_on_main_body_in_bbox_sub(2),point_on_main_body_in_bbox_sub(3));
    now_ind = terminal_ind;
    route_between_points_ind = now_ind;
    while now_ind ~= source_ind
        now_ind = indfrom(now_ind);
        route_between_points_ind = [route_between_points_ind; now_ind];
    end
    
end


function [part_of_route_between_components, dbf_of_part_of_route_between_components] = leave_part_between_components_from_route (route_between_points_ind_in_bbox_task, dbf_on_route, bbox_task)

    voxel_type_of_route_between_points_ind_in_bbox_task = bbox_task(route_between_points_ind_in_bbox_task);
    part_in_main_component = find(voxel_type_of_route_between_points_ind_in_bbox_task == 2);
    part_in_target_component = find(voxel_type_of_route_between_points_ind_in_bbox_task == 3);
    
    last_of_part_of_route_in_target_component = max(part_in_target_component);
    first_of_part_of_route_in_main_component = min(part_in_main_component);
    
    if first_of_part_of_route_in_main_component < last_of_part_of_route_in_target_component
        part_of_route_between_components = -1;
        dbf_of_part_of_route_between_components = -1;
    else
        part_of_route_between_components = route_between_points_ind_in_bbox_task(last_of_part_of_route_in_target_component:first_of_part_of_route_in_main_component);
        dbf_of_part_of_route_between_components = dbf_on_route(last_of_part_of_route_in_target_component:first_of_part_of_route_in_main_component);
    end

end

