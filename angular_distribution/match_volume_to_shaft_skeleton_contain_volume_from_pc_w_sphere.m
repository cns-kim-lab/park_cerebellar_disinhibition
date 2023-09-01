function [surroundings_w_valid_match_iso_mip3,shaft_skeleton_voxel_of_valid_match_iso_mip3,dbf_of_shaft_skeleton_voxel_of_valid_match,celltypes_of_surroundings_w_valid_match] = match_volume_to_shaft_skeleton_contain_volume_from_pc_w_sphere (target_pc_dend_id,dilation_count)
%% parameters
%     dilation_count = 10;
    dilation_strel_size = 1;
    dilation_strel = strel('sphere',dilation_strel_size*dilation_count);
    mip_factor_from_iso_mip1_to_iso_mip3 = 4;

%% prepared data
%     z_bound_mat_file_path = '/volume_1/research/iys0819/cell_morphology_analysis/angular_composition_around_pc_dend/code/z_bounds_of_PC_dendrites_in_iso_mip3_volume.mat';
    z_bound_mat_file_path = '/volume_1/research/iys0819/cell_morphology_analysis/angular_composition_around_pc_dend/code/z_bounds_of_PC_dendrites_in_iso_mip3_volume.400_and_402.mat';

%% load iso mip3 volume
    % need (iso mip3) shaft-spine separation
    vol_iso_mip3_h5_path = '/data/lrrtm3_wt_reconstruction/segment_iso_mip3_all_cells_210503.pc_cb_cut_and_int_axon_cut.sample_first_sheet.h5';
    vol_iso_mip3_shaft_spine_separated_h5_path  = '/data/research/iys0819/cell_morphology_pipeline/volumes/shaft_spine_separation.iso_mip1.e7.th20000.d14.spines_separated.0.9_0.01_1500.w_am.ds_to_iso_mip3.h5';
    vol_iso_mip3_shaft_spine_separated = h5read(vol_iso_mip3_shaft_spine_separated_h5_path,'/main');
    vol_iso_mip3_target_pc = floor(vol_iso_mip3_shaft_spine_separated./100000) == target_pc_dend_id;
    vol_iso_mip3_target_pc_dend = vol_iso_mip3_shaft_spine_separated == (target_pc_dend_id*100000+1);

%% dilate a PC volume
%% set bbox containing the dilated PC volume
% apply dilation on the bounding box of the target PC
    [z_min,z_max] = read_z_bounds_of_target_pc (z_bound_mat_file_path,target_pc_dend_id);
    z_min_plus_margin = max(1,z_min - dilation_count * dilation_strel_size);
    z_max_plus_margin = min(size(vol_iso_mip3_target_pc_dend,3),z_max + dilation_count * dilation_strel_size);
    vol_bbox_of_target_pc = vol_iso_mip3_target_pc(:,:,z_min_plus_margin:z_max_plus_margin);
    vol_bbox_of_target_pc_dend = vol_iso_mip3_target_pc_dend(:,:,z_min_plus_margin:z_max_plus_margin);

    a = vol_bbox_of_target_pc_dend;
    b = a;
%     for i=1:dilation_count
    b = imdilate(b,dilation_strel);
%     end
    
%% list the query points
    % include pc shaft and spine
    surrounding_of_target_pc = setdiff(find(b==1),find(a==1));
    
%% match the query points to target pc
%% 0. load informations about PC shaft
    mat_dir = '/data/research/iys0819/cell_morphology_pipeline/result';
    spine_seg_mat_file_path = sprintf('%s/pc_spine_separation/spine_segmentation_of_cell_%d.th_high_0.9_th_low_0.01_dust_1500.with_additional_merge.mat',mat_dir,target_pc_dend_id);
    shaft_skel_mat_file_path = sprintf('%s/skeleton_pc_shaft/shaft_skeleton_of_cell_%d.ps_1.050_pc_10.mat',mat_dir,target_pc_dend_id);
    
    load(spine_seg_mat_file_path,'spine_segment_root_sub');
    load(shaft_skel_mat_file_path,'skeleton_of_ccs_pos');
    pc_skeleton_branch_path_sub = cellfun(@(x) cellfun(@(y) y-[0 0 z_min_plus_margin-1],x,'UniformOutput',false),skeleton_of_ccs_pos','UniformOutput',false);
    spine_segment_root_sub = floor(spine_segment_root_sub ./ mip_factor_from_iso_mip1_to_iso_mip3) - [0 0 z_min_plus_margin-1];

    root_of_branch = cell2mat(cellfun(@(x) x{1}(end,:),pc_skeleton_branch_path_sub,'UniformOutput',false));
    
    % about cellbody
    list_of_pc_w_cellbody = [1800 1100 400 1300];
    cellbody_iso_mip3_volume_h5_file_path = '/data/lrrtm3_wt_reconstruction/segment_iso_mip3_all_cells_210503.pc_cb_cut_and_int_axon_cut.sample_first_sheet.h5';
    
%% 1. locate the nearest foreground voxel from each query point

    fprintf('Leaving the target-only volume..\n');
    vol_iso_mip3_target_cell = uint32(zeros(size(vol_iso_mip3_target_pc)));
    vol_iso_mip3_target_cell(vol_iso_mip3_target_pc) = vol_iso_mip3_shaft_spine_separated(vol_iso_mip3_target_pc);
    vol_iso_mip3_target_cell = vol_iso_mip3_target_cell(:,:,z_min_plus_margin:z_max_plus_margin);

    fprintf('eliminating dust component generated during spine segmentation..\n');
    vol_iso_mip3_target_cell(vol_iso_mip3_target_cell==(target_pc_dend_id * 100000 + 2)) = 0;
       
    fprintf('distance transform of the target-only volume..\n');
    [~,nearest_foreground] = bwdist(vol_iso_mip3_target_cell);    
    fprintf('Done.\n');
    
    
%% (!) 1-i) check if the cell has soma, and remove them from query points
    soma_point = [];
    if ismember(target_pc_dend_id,list_of_pc_w_cellbody)
        fprintf('Finding soma segment to iso mip3 volume\n');
        vol_soma_iso_mip3 = fill_cellbody_to_vol_iso_mip3 (zeros(size(vol_iso_mip3_target_cell)),z_min_plus_margin,z_max_plus_margin,target_pc_dend_id,cellbody_iso_mip3_volume_h5_file_path);
        vol_soma_iso_mip3 = imfill(vol_soma_iso_mip3,'holes');
        cc_vol_soma_iso_mip3 = bwconncomp(vol_soma_iso_mip3);
        size_cc_vol_soma_iso_mip3 = cellfun(@length, cc_vol_soma_iso_mip3.PixelIdxList);
        [~,largest_cc_num] = max(size_cc_vol_soma_iso_mip3);
        largest_cc_of_soma = cc_vol_soma_iso_mip3.PixelIdxList{largest_cc_num};
        vol_soma_iso_mip3 = false(size(vol_soma_iso_mip3));
        vol_soma_iso_mip3(largest_cc_of_soma) = 1;
        soma_point = intersect(find(vol_soma_iso_mip3==1),surrounding_of_target_pc);
        fprintf('Done.\n');
    end
    surrounding_of_target_pc = setdiff(surrounding_of_target_pc,soma_point);
    
%%
    nearest_segment_number = vol_iso_mip3_target_cell(nearest_foreground(surrounding_of_target_pc));
    near_shaft_point = find(nearest_segment_number == (target_pc_dend_id * 100000 + 1));
    near_spine_point = find(nearest_segment_number > (target_pc_dend_id * 100000 + 2));
    spine_ind_of_near_spine_point = nearest_segment_number(near_spine_point) - target_pc_dend_id * 100000 - 2;

    [x,y,z] = ind2sub(size(vol_iso_mip3_target_cell),nearest_foreground(surrounding_of_target_pc(near_shaft_point)));
    nearest_voxel_from_near_shaft_point = [x y z];
    % for spine synapses, use spine_segment_root_sub(iso mip1) instead

    proximal_voxel_from_spine_root_of_near_spine_point = max([1 1 1], spine_segment_root_sub(spine_ind_of_near_spine_point,1:3));
    % from iso mip1 to iso mip3

    proximal_voxel_from_query_point = zeros([max([max(near_shaft_point), max(near_spine_point)]) 3]);
    proximal_voxel_from_query_point(near_shaft_point,1:3) = nearest_voxel_from_near_shaft_point;
    proximal_voxel_from_query_point(near_spine_point,1:3) = proximal_voxel_from_spine_root_of_near_spine_point;
    
%% 1-ii) label the voxels in shaft volume by component numbers
        % (!) incompleteness of shaft component skeletons
    fprintf('decomposing shaft segment into connected components\n');
    vol_shaft_iso_mip3 = vol_iso_mip3_target_cell == (target_pc_dend_id*100000 + 1);
    size_of_vol_shaft_iso_mip3 = size(vol_shaft_iso_mip3);
    cc_vol_shaft_iso_mip3 = bwconncomp(vol_shaft_iso_mip3);
    vol_shaft_iso_mip3 = uint32(vol_shaft_iso_mip3);
    for n=1:cc_vol_shaft_iso_mip3.NumObjects
        vol_shaft_iso_mip3(cc_vol_shaft_iso_mip3.PixelIdxList{n}) = n+1;
    end
    
%% 1-iv) pair the shaft component skeletons to corresponding components
    fprintf('match shaft skeleton branches to shaft connected components\n');
    [~,shaft_voxel_ind] = bwdist(logical(vol_shaft_iso_mip3));
    branch_path_ind = cellfun(@(x) sub2ind(size(vol_shaft_iso_mip3),x{1}(:,1),x{1}(:,2),x{1}(:,3)),pc_skeleton_branch_path_sub,'UniformOutput',false);
    component_id_of_each_skeleton_branch = cellfun(@(x) mode(vol_shaft_iso_mip3(shaft_voxel_ind(x))),branch_path_ind);
    
%% 1-v) assign component number to each synapse
    proximal_voxel_from_query_point_ind = sub2ind(size(shaft_voxel_ind),proximal_voxel_from_query_point(:,1),proximal_voxel_from_query_point(:,2),proximal_voxel_from_query_point(:,3));
    shaft_component_number = vol_shaft_iso_mip3(shaft_voxel_ind(proximal_voxel_from_query_point_ind));
                                
    [shaft_component_voxel_x,shaft_component_voxel_y,shaft_component_voxel_z] =...
                             ind2sub(size_of_vol_shaft_iso_mip3,shaft_voxel_ind(proximal_voxel_from_query_point_ind));
                         
    shaft_component_voxel_sub = [shaft_component_voxel_x shaft_component_voxel_y shaft_component_voxel_z];


%% 2. trace the route from the nearest shaft component voxel from each spine root to shaft skeleton root
   
    
    shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points = zeros(length(proximal_voxel_from_query_point),3);
    dbf_of_matched_shaft_skeleton_voxel = zeros(length(proximal_voxel_from_query_point),1);
%%
    for i = 1:length(component_id_of_each_skeleton_branch)

        cn = component_id_of_each_skeleton_branch(i);
        fprintf('%d / %d skeleton subtree embedded in component %d : ',i,length(component_id_of_each_skeleton_branch),cn);
        component_ind = find(vol_shaft_iso_mip3==cn);
        current_branch_path_sub = pc_skeleton_branch_path_sub{i};
        root_of_corresponding_comp = root_of_branch(i,:);

        target_point = find(shaft_component_number==cn);
        shaft_component_voxel_of_target = shaft_component_voxel_sub(target_point,:);

        [matched_skeleton_voxel_sub_in_input_volume,dbf_at_matched_skeleton_voxel,voxel_length_of_longest_path] = get_route_to_skeleton_of_main_component_v2 (component_ind,...
                                                                                    current_branch_path_sub,...
                                                                                    shaft_component_voxel_of_target,...
                                                                                    size_of_vol_shaft_iso_mip3,...
                                                                                    root_of_corresponding_comp);
  
        shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(target_point,1:3) = matched_skeleton_voxel_sub_in_input_volume;
        dbf_of_matched_shaft_skeleton_voxel(target_point) = dbf_at_matched_skeleton_voxel;
        fprintf('match complete, voxel length of longest path = %d\n',voxel_length_of_longest_path);
    end

    [x,y,z] = ind2sub(size_of_vol_shaft_iso_mip3,surrounding_of_target_pc);
    query_point_sub = [x y z];

%% check the result
    figure; hold on;
    skeleton_merged_within_ccs = cellfun(@(x) cell2mat(x'),pc_skeleton_branch_path_sub,'UniformOutput',false);
    
    cellfun(@(x) scatter3(x(:,1),x(:,2),x(:,3),'.k'),skeleton_merged_within_ccs);
   
    sample_point_list = randi(size(query_point_sub,1),100,1);
    
    quiver3(query_point_sub(sample_point_list,1),query_point_sub(sample_point_list,2),query_point_sub(sample_point_list,3),...
            proximal_voxel_from_query_point(sample_point_list,1)-query_point_sub(sample_point_list,1),...
            proximal_voxel_from_query_point(sample_point_list,2)-query_point_sub(sample_point_list,2),...
            proximal_voxel_from_query_point(sample_point_list,3)-query_point_sub(sample_point_list,3),...
            0,'LineWidth',2,'Color','b');
        
    quiver3(proximal_voxel_from_query_point(sample_point_list,1),proximal_voxel_from_query_point(sample_point_list,2),proximal_voxel_from_query_point(sample_point_list,3),...
            shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(sample_point_list,1)-proximal_voxel_from_query_point(sample_point_list,1),...
            shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(sample_point_list,2)-proximal_voxel_from_query_point(sample_point_list,2),...
            shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(sample_point_list,3)-proximal_voxel_from_query_point(sample_point_list,3),...
            0,'LineWidth',2,'Color','r');
    
    set(gca,'DataAspectRatio',[1 1 1]);
        
%% 3. list the query points matched to each skeleton voxel

    lines_w_valid_matches = shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(:,1)~=0 & shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(:,2)~=0 & shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(:,3)~=0;
    shaft_skeleton_voxel_of_valid_match_iso_mip3 = shaft_skeleton_voxel_matched_to_proximal_voxel_of_query_points(lines_w_valid_matches,:) + [0,0,z_min_plus_margin-1];
    dbf_of_shaft_skeleton_voxel_of_valid_match = dbf_of_matched_shaft_skeleton_voxel(lines_w_valid_matches);
    surroundings_w_valid_match_iso_mip3 = query_point_sub(lines_w_valid_matches,:) + [0,0,z_min_plus_margin-1];

%     ind_matched_shaft_skeleton_voxel = sub2ind(size_of_vol_shaft_iso_mip3,shaft_skeleton_voxel_of_valid_matches(:,1),shaft_skeleton_voxel_of_valid_matches(:,2),shaft_skeleton_voxel_of_valid_matches(:,3));
%     merged_skeleton = unique(cell2mat(skeleton_merged_within_ccs),'rows');
%     ind_merged_skeleton = sub2ind(size_of_vol_shaft_iso_mip3,merged_skeleton(:,1),merged_skeleton(:,2),merged_skeleton(:,3));
%     list_of_matched_surrounding_voxels = arrayfun(@(x) surroundings_w_valid_match(find(x==ind_matched_shaft_skeleton_voxel),:),ind_merged_skeleton,'UniformOutput',false);

%% 4. refer the original volume to figure out the celltypes of query points
    vol_iso_mip3_all_cells = floor(h5read(vol_iso_mip3_h5_path,'/main')./100);
    vol_iso_mip3_all_cells_cut = vol_iso_mip3_all_cells(:,:,z_min_plus_margin:z_max_plus_margin);
    omni_ids_of_surroundings_w_valid_match = vol_iso_mip3_all_cells_cut(surrounding_of_target_pc(lines_w_valid_matches));
    celltypes_of_surroundings_w_valid_match = get_celltype_from_omni_id_list(omni_ids_of_surroundings_w_valid_match,target_pc_dend_id/100);

end

%% subfunctions

function [z_min_of_target_pc_dend,z_max_of_target_pc_dend] = read_z_bounds_of_target_pc (z_bound_mat_file_path,target_pc_id)

    load(z_bound_mat_file_path,'target_pc_dend_id_list','z_min','z_max');
    target_pc_dend_ind = target_pc_dend_id_list == target_pc_id;
    z_min_of_target_pc_dend = z_min(target_pc_dend_ind);
    z_max_of_target_pc_dend = z_max(target_pc_dend_ind);

end

function vol_iso_mip3_target_cell = fill_cellbody_to_vol_iso_mip3 (vol_iso_mip3_target_cell,z_min,z_max,target_cell_id,cellbody_iso_mip3_volume_h5_file_path)

    vol_iso_mip3_cellbody = h5read(cellbody_iso_mip3_volume_h5_file_path,'/main') == (target_cell_id + 1);
    vol_iso_mip3_cellbody = vol_iso_mip3_cellbody(:,:,z_min:z_max);
    vol_iso_mip3_target_cell(vol_iso_mip3_cellbody) = target_cell_id*100000;

end

function [matched_skeleton_voxel_sub_in_input_volume,dbf_at_matched_skeleton_voxel,voxel_length_of_longest_path] = get_route_to_skeleton_of_main_component_v2 (main_component_ind,skeleton_of_main_comp_sub,proximal_voxel_of_query_points,size_of_vol,rt_pnt_iso_mip3_sub)
   
    margin = 1;
    truncate_to_even_or_not = 0;
    
    [vol_main_comp_iso_mip3,offset_vol_main_comp_iso_mip3] = generate_subvolume_bounding_target_points(main_component_ind,size_of_vol,margin,truncate_to_even_or_not);
    rt_pnt_iso_mip3_sub_new = rt_pnt_iso_mip3_sub - offset_vol_main_comp_iso_mip3;
    proximal_voxel_of_query_points_w_new_offset = proximal_voxel_of_query_points - offset_vol_main_comp_iso_mip3;
    
    skeleton_of_main_comp_sub = cell2mat(skeleton_of_main_comp_sub');
    skeleton_of_main_comp_sub_new = skeleton_of_main_comp_sub - offset_vol_main_comp_iso_mip3;
    size_of_vol_new = size(vol_main_comp_iso_mip3);
    skeleton_of_main_comp_ind = sub2ind(size_of_vol_new, skeleton_of_main_comp_sub_new(:,1), skeleton_of_main_comp_sub_new(:,2), skeleton_of_main_comp_sub_new(:,3));

    dbf = bwdist(~vol_main_comp_iso_mip3);
    dbf = double(dbf);
    [pdrf,indfrom,~] = dijkstra_root2all (dbf, size_of_vol_new, rt_pnt_iso_mip3_sub_new, 1);
    pdrf = pdrf .* logical(vol_main_comp_iso_mip3);

%     indfrom_original = indfrom;
    indfrom_w_fixed_points = indfrom;
    indfrom_w_fixed_points(skeleton_of_main_comp_ind) = skeleton_of_main_comp_ind;

    proximal_voxel_of_query_points_w_new_offset_ind = sub2ind(size_of_vol_new,proximal_voxel_of_query_points_w_new_offset(:,1),proximal_voxel_of_query_points_w_new_offset(:,2),proximal_voxel_of_query_points_w_new_offset(:,3));

    a = proximal_voxel_of_query_points_w_new_offset_ind;
    c = true(size(a));
    it_count = 0;

    while sum(c)
        b = a;
        a = indfrom_w_fixed_points(a);
        c = a~=b;
        it_count = it_count+1;
%         disp(it_count);
    end 
    
    [x,y,z] = ind2sub(size_of_vol_new,a);
    matched_skeleton_voxel_sub_in_input_volume = [x y z] + offset_vol_main_comp_iso_mip3;
    dbf_at_matched_skeleton_voxel = dbf(a);    
    voxel_length_of_longest_path = it_count;
    
end

function celltypes_of_surroundings_w_valid_match = get_celltype_from_omni_id_list(omni_ids_of_surroundings_w_valid_match,target_pc_dend_id)

    addpath /data/lrrtm3_wt_code/matlab/mysql/
    celltypes_of_surroundings_w_valid_match = zeros(size(omni_ids_of_surroundings_w_valid_match));
    nonzero_ind = omni_ids_of_surroundings_w_valid_match~=0;
    
    h_sql = [];
    try
        h_sql = mysql('open','localhost','omnidev','rhdxhd!Q2W');
    catch    
        fprintf('stat - already db open, close and reopen\n');    
        mysql(h_sql, 'close');
        h_sql = mysql('open','localhost','omnidev','rhdxhd!Q2W');
    end

    r = mysql(h_sql, 'use omni_20210503');
    if r <= 0
        fprintf('db connection fail\n');
        return;
    end
    
    omni_id_list_to_query = unique(omni_ids_of_surroundings_w_valid_match(nonzero_ind));
    string_omni_id_list_to_query = sprintf('%d,',omni_id_list_to_query);
    query_to_mysql = sprintf(['select cm.omni_id, cm.type1 from cell_metadata cm where cm.omni_id in (%s)'],string_omni_id_list_to_query(1:end-1));
    [omni_ids_from_query, celltypes_from_query] = mysql(h_sql,query_to_mysql);
    mysql(h_sql,'close');
    
    omni_id_list = [1:max(omni_ids_from_query)];
    celltype_list = zeros(size(omni_id_list));
    [Lia,Locb] = ismember(omni_ids_from_query,omni_id_list);
    celltype_list(Locb) = celltypes_from_query(Lia);
    celltypes_of_surroundings_w_valid_match(nonzero_ind) = celltype_list(omni_ids_of_surroundings_w_valid_match(nonzero_ind));
    celltypes_of_surroundings_w_valid_match(omni_ids_of_surroundings_w_valid_match==target_pc_dend_id) = 8;

end









