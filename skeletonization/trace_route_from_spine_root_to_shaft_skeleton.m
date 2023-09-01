function [route_from_spine_root_to_shaft_skeleton,dbf_of_route_from_spine_root_to_shaft_skeleton] = trace_route_from_spine_root_to_shaft_skeleton (target_cell_id,vol_iso_mip3)

    addpath ./subfunctions_for_pc_spine_skeletonization/
%% 0. get informations from previous calculations
%    : spine root position, shaft component, shaft skeleton
    
    spine_seg_mat_dir = '/data/research/iys0819/cell_morphology_pipeline/result/pc_spine_separation';
    h5_dir = '/data/research/iys0819/cell_morphology_pipeline/volumes';
    spine_seg_mat_file_path = sprintf('%s/spine_segmentation_of_cell_%d.th_high_0.9_th_low_0.01_dust_1500.with_additional_merge.mat',spine_seg_mat_dir,target_cell_id);

    shaft_skel_mat_dir = '/data/research/iys0819/cell_morphology_pipeline/result/skeleton_pc_shaft';
    shaft_skel_mat_file_path = sprintf('%s/shaft_skeleton_of_cell_%d.ps_1.050_pc_10.mat',shaft_skel_mat_dir,target_cell_id);
    load(spine_seg_mat_file_path,'spine_segment_id_list','spine_segment_root_sub');
    load(shaft_skel_mat_file_path,'skeleton_of_ccs_pos');
    branch_path_sub = skeleton_of_ccs_pos';
    
    shaft_h5_file_path = sprintf('%s/shaft_spine_separation.iso_mip1.e7.th20000.d14.ds_to_iso_mip3.h5',h5_dir);
    if vol_iso_mip3==-1
        vol_iso_mip3 = h5read(shaft_h5_file_path, '/main');
    end

    root_of_branch = cell2mat(cellfun(@(x) x{1}(end,:),branch_path_sub,'UniformOutput',false));
           
%% 1. locate the nearest shaft component skeleton from each spine root  
%   : the component should be neighboring the spine root voxel  
%   : caution for information loss due to downsampling  

    % i) label the voxels in shaft volume by component numbers
        % (!) incompleteness of shaft component skeletons
    vol_shaft_iso_mip3 = vol_iso_mip3 == (target_cell_id*10 + 1);
    mip_factor = 4;
    size_of_vol_shaft_iso_mip3 = size(vol_shaft_iso_mip3);
    cc_vol_shaft_iso_mip3 = bwconncomp(vol_shaft_iso_mip3);
    vol_shaft_iso_mip3 = double(vol_shaft_iso_mip3);
    for n=1:cc_vol_shaft_iso_mip3.NumObjects
        vol_shaft_iso_mip3(cc_vol_shaft_iso_mip3.PixelIdxList{n}) = n;
    end

    % ii) pair the shaft component skeletons to corresponding components
    [~,shaft_voxel_ind] = bwdist(logical(vol_shaft_iso_mip3));
    
    branch_path_ind = cellfun(@(x) sub2ind(size(vol_shaft_iso_mip3),x{1}(:,1),x{1}(:,2),x{1}(:,3)),branch_path_sub,'UniformOutput',false);
    component_id_of_each_skeleton_branch = cellfun(@(x) mode(vol_shaft_iso_mip3(shaft_voxel_ind(x))),branch_path_ind);

    % iii) assign component number to each spine
        % downscale the spine root coordinates 
    spine_segment_root_sub_iso_mip3 = round(spine_segment_root_sub./mip_factor);

% (?) set cutoff on distance to validate the matching  
    
    shaft_component_number = arrayfun(@(x,y,z) vol_shaft_iso_mip3(shaft_voxel_ind(x,y,z)),...
                                    spine_segment_root_sub_iso_mip3(:,1),spine_segment_root_sub_iso_mip3(:,2),spine_segment_root_sub_iso_mip3(:,3));
    [shaft_component_voxel_x,shaft_component_voxel_y,shaft_component_voxel_z] =...
                             arrayfun(@(x,y,z) ind2sub(size_of_vol_shaft_iso_mip3,shaft_voxel_ind(x,y,z)),...
                             spine_segment_root_sub_iso_mip3(:,1),spine_segment_root_sub_iso_mip3(:,2),spine_segment_root_sub_iso_mip3(:,3),'UniformOutput',false);
    shaft_component_voxel_sub = [cell2mat(shaft_component_voxel_x) cell2mat(shaft_component_voxel_y) cell2mat(shaft_component_voxel_z)];
    
        
%% 2. trace the route from the nearest shaft component voxel from each spine root to shaft skeleton root
%   : pass shaft component and its spine roots 

    route_from_spine_root_to_shaft_skeleton = cell(length(spine_segment_id_list),1);
    dbf_of_route_from_spine_root_to_shaft_skeleton = cell(length(spine_segment_id_list),1);
    for i = 1:length(component_id_of_each_skeleton_branch)
        cn = component_id_of_each_skeleton_branch(i);
        fprintf('%d / %d skeleton subtree embedded in component %d\n',i,length(component_id_of_each_skeleton_branch),cn);
        component_ind = cc_vol_shaft_iso_mip3.PixelIdxList{cn};
        current_branch_path_sub = branch_path_sub{i};
        root_of_corresponding_comp = root_of_branch(i,:);
        target_spine = find(shaft_component_number==cn);
        shaft_component_voxel_of_target_spine = shaft_component_voxel_sub(target_spine,:);

        [route_in_shaft,dbf_of_route_in_shaft] = get_route_to_skeleton_of_main_component (component_ind,...
                                                                                                        current_branch_path_sub,...
                                                                                                        shaft_component_voxel_of_target_spine,...
                                                                                                        size_of_vol_shaft_iso_mip3,...
                                                                                                        root_of_corresponding_comp);
        route_from_spine_root_to_shaft_skeleton(target_spine) = route_in_shaft;
        dbf_of_route_from_spine_root_to_shaft_skeleton(target_spine) = dbf_of_route_in_shaft;
    end
%%
end

function [route_in_the_main_comp_sub,dbf_of_routes] = get_route_to_skeleton_of_main_component (main_component_ind,skeleton_of_main_comp_sub,branching_point_at_main_body_vol_shaft_iso_mip3,size_of_vol,rt_pnt_iso_mip3_sub)
   
    margin = 1;
    truncate_to_even_or_not = 0;
    [vol_main_comp_iso_mip3,offset_vol_main_comp_iso_mip3] = generate_subvolume_bounding_target_points(main_component_ind,size_of_vol,margin,truncate_to_even_or_not);
    rt_pnt_iso_mip3_sub_new = rt_pnt_iso_mip3_sub - offset_vol_main_comp_iso_mip3;
    branching_point_at_main_body_vol_shaft_iso_mip3_new = branching_point_at_main_body_vol_shaft_iso_mip3 - offset_vol_main_comp_iso_mip3;
    
    skeleton_of_main_comp_sub = cell2mat(skeleton_of_main_comp_sub');
    skeleton_of_main_comp_sub_new = skeleton_of_main_comp_sub - offset_vol_main_comp_iso_mip3;
    size_of_vol_new = size(vol_main_comp_iso_mip3);
    skeleton_of_main_comp_ind = sub2ind(size_of_vol_new, skeleton_of_main_comp_sub_new(:,1), skeleton_of_main_comp_sub_new(:,2), skeleton_of_main_comp_sub_new(:,3));

    dbf = bwdist(~vol_main_comp_iso_mip3);
    dbf = double(dbf);
    [pdrf,indfrom,~] = dijkstra_root2all (dbf, size_of_vol_new, rt_pnt_iso_mip3_sub_new, 1);
    pdrf = pdrf .* logical(vol_main_comp_iso_mip3);

    number_of_sub_comp = size(branching_point_at_main_body_vol_shaft_iso_mip3_new,1);
    route_in_the_main_comp_sub = cell(number_of_sub_comp,1);
    dbf_of_routes = cell(number_of_sub_comp,1);
    for i=1:number_of_sub_comp
%         fprintf('\t\t%d of %d\n',i,number_of_sub_comp);
        if sum(branching_point_at_main_body_vol_shaft_iso_mip3_new(i,:)) ~= 0
            [route_sub,route_ind] = backtrack_the_route_to_source (pdrf, indfrom, skeleton_of_main_comp_ind, rt_pnt_iso_mip3_sub_new, branching_point_at_main_body_vol_shaft_iso_mip3_new(i,:));
            dbf_of_routes{i} = dbf(route_ind);
            route_in_the_main_comp_sub{i} = route_sub + offset_vol_main_comp_iso_mip3;
        end
    end

    
end

function [route_between_points_sub,route_between_points_ind] = backtrack_the_route_to_source (pdrf, indfrom, skeleton_of_main_comp_ind, point_on_main_body_in_bbox_sub, point_on_target_body_in_bbox_sub)

    size_bbox = size(pdrf);
    terminal_ind = sub2ind(size_bbox,point_on_target_body_in_bbox_sub(1),point_on_target_body_in_bbox_sub(2),point_on_target_body_in_bbox_sub(3));
    source_ind = sub2ind(size_bbox,point_on_main_body_in_bbox_sub(1),point_on_main_body_in_bbox_sub(2),point_on_main_body_in_bbox_sub(3));
    now_ind = terminal_ind;
    route_between_points_ind = now_ind;
    while now_ind ~= source_ind && ~ismember(now_ind,skeleton_of_main_comp_ind)
        now_ind = indfrom(now_ind);
        route_between_points_ind = [route_between_points_ind; now_ind];
    end
    
    [x,y,z] = ind2sub(size_bbox,route_between_points_ind);
    route_between_points_sub = [x y z];
    
end