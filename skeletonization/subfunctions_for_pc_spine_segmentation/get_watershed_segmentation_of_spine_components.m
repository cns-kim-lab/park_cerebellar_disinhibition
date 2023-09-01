function [cell_of_spine_comp_global_sub, skeleton_root_of_each_spine_global_sub, max_mean_affinity_values, mean_affinity_values] = get_watershed_segmentation_of_spine_components (target_cell_id, target_spine_comp, size_of_vol,offset_of_vol,threshold_for_dust_segment,threshold_affin_high,imfill_or_not,original_h5_file_path,additional_merge,threshold_merge)

    % addpath to include codes for watershed  
    addpath ./watershed_kimlab/watershed_new/
    addpath ./watershed_kimlab/watershed_ref/
    addpath ./watershed_kimlab/hdf5_ref/
    
    margin = 1;
    truncate_to_even_or_not = 1;
    skip_even_or_odd = 1;

    [subvol_seg,offset_subvol_seg] = generate_subvolume_bounding_target_points(target_spine_comp,size_of_vol,margin,truncate_to_even_or_not);
    size_subvol_seg = size(subvol_seg);
    if imfill_or_not
        subvol_seg = imfill(subvol_seg,'holes');
    end

    [subvol_affin_resized, ~] = load_affin_map_of_input_segment_range (offset_of_vol,offset_subvol_seg,size_subvol_seg,skip_even_or_odd);
    size_subvol_affin_resized = size(subvol_affin_resized);

    % fit and mask the affinity volume to the segmentation volume
    % 'truncate_to_even_or_not' is supposed to be set as 1  
    xrange = min(size_subvol_seg(1),size_subvol_affin_resized(1));
    yrange = min(size_subvol_seg(2),size_subvol_affin_resized(2));
    zrange = min(size_subvol_seg(3),size_subvol_affin_resized(3));
    subvol_affin_masked_and_truncated_by_seg (:,:,:,1)= double(subvol_seg(1:xrange,1:yrange,1:zrange)) .* subvol_affin_resized(1:xrange,1:yrange,1:zrange,1);
    subvol_affin_masked_and_truncated_by_seg (:,:,:,2)= double(subvol_seg(1:xrange,1:yrange,1:zrange)) .* subvol_affin_resized(1:xrange,1:yrange,1:zrange,2);
    subvol_affin_masked_and_truncated_by_seg (:,:,:,3)= double(subvol_seg(1:xrange,1:yrange,1:zrange)) .* subvol_affin_resized(1:xrange,1:yrange,1:zrange,3);


%   preset in aff2seg
%     dust = 100; dust_low = 0.30; threshold_affin_low = 0.3;
%     dust = threshold_for_dust_segment;

%   preset in omnification_newcube
%     dust = 500; 
    threshold_affin_low = 0.01; dust_low = 0.001;
    
    dust = threshold_for_dust_segment;
    
    watershed_width = 128;
    nthread = 12;
    
    [watershed_segmentation_of_target_spine_component, ~, ~] = aff2seg(subvol_affin_masked_and_truncated_by_seg,'array',[],false,threshold_affin_high,threshold_affin_low,dust,dust_low,nthread,watershed_width);
    
    % there exist protrusions toward background region of the segmentation
    % remove such protrusions
    % plus, guarantee the background is marked as zero  
    watershed_segmentation_of_target_spine_component = fix_background_id_as_zero(watershed_segmentation_of_target_spine_component);
    watershed_segmentation_of_target_spine_component(~subvol_seg) = 0;
    
    % Set a proper threshold for surface segment merge
%     voxels_to_be_merged = extract_voxels_to_be_merged_into_nearest_segment (subvol_seg,watershed_segmentation_of_target_spine_component,threshold_for_dust_segment);
    % size thresholding done in aff2seg. merge only the background voxels in the segment
    voxels_to_be_merged = extract_voxels_to_be_merged_into_nearest_segment_v2 (subvol_seg,watershed_segmentation_of_target_spine_component);
    watershed_segmentation_of_target_spine_component = merge_voxels_into_nearest_segment (subvol_seg,watershed_segmentation_of_target_spine_component,voxels_to_be_merged);
  
    cell_of_spine_comp_ind_local = describe_segments_in_local_ind (watershed_segmentation_of_target_spine_component);

    % merge oversegmented components
    if additional_merge
        [cell_of_spine_comp_ind_local, skeleton_root_of_each_spine_local_ind, max_mean_affinity_values, mean_affinity_values, ~, ~, ~, ~] = merge_oversegmented_spine_segments (target_cell_id, cell_of_spine_comp_ind_local, watershed_segmentation_of_target_spine_component, subvol_affin_masked_and_truncated_by_seg, offset_subvol_seg, original_h5_file_path, threshold_merge);

    else
        subvol_w_shaft = overwrite_shaft_segment_to_spine_volume (watershed_segmentation_of_target_spine_component, target_cell_id, original_h5_file_path, offset_subvol_seg);
        [list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment, edges_at_boundary_from_neighboring_segment] = identify_adjacent_segments (subvol_w_shaft); 
        
        contact_to_shaft_or_not = cellfun(@(x) ismember(1,x),list_of_neighboring_segment);
        
        skeleton_root_of_each_spine_local_ind_shaft_contact_seg_only = select_root_for_skeleton_among_contact_to_shaft (cell_of_spine_comp_ind_local(contact_to_shaft_or_not),list_of_neighboring_segment(contact_to_shaft_or_not),...
                                                                                                                        edges_at_boundary_to_neighboring_segment(contact_to_shaft_or_not),edges_at_boundary_from_neighboring_segment(contact_to_shaft_or_not),size(subvol_w_shaft));
                                                                                                                  
        skeleton_root_of_each_spine_local_ind = NaN(length(list_of_neighboring_segment),1);
        skeleton_root_of_each_spine_local_ind(contact_to_shaft_or_not) = skeleton_root_of_each_spine_local_ind_shaft_contact_seg_only;
        max_mean_affinity_values = [];
        mean_affinity_values = [];
    end
    
    cell_of_spine_comp_global_sub = cellfun(@(x) from_local_ind_to_global_sub (x,size_subvol_seg,offset_subvol_seg),cell_of_spine_comp_ind_local,'UniformOutput',false);
    skeleton_root_of_each_spine_global_sub = from_local_ind_to_global_sub(skeleton_root_of_each_spine_local_ind,size_subvol_seg,offset_subvol_seg);

end

function [subvol_affin_resized, subvol_affin] = load_affin_map_of_input_segment_range (offset_of_vol,offset_subvol_seg,size_subvol_seg,skip_even_or_odd)
  
    affin_offset_subvol_seg_in_original_volume = (offset_subvol_seg + offset_of_vol) .*2 ./ [1 1 4];
    affin_size_of_subvol_seg = size_subvol_seg;
    affin_size_of_subvol_seg_in_original_volume = ceil(affin_size_of_subvol_seg .*2 ./ [1 1 4]);
    
    coord_lower_bound = affin_offset_subvol_seg_in_original_volume + 1;
    coord_upper_bound = affin_offset_subvol_seg_in_original_volume + affin_size_of_subvol_seg_in_original_volume;
    subvol_affin = read_affinity_map (coord_lower_bound,coord_upper_bound);
    
    if skip_even_or_odd
        subvol_x_affin_resized = imresize3(subvol_affin(:,:,:,1),size(subvol_affin,[1 2 3]).*[1 1 2],'nearest');
        subvol_y_affin_resized = imresize3(subvol_affin(:,:,:,2),size(subvol_affin,[1 2 3]).*[1 1 2],'nearest');
        subvol_z_affin_resized = imresize3(subvol_affin(:,:,:,3),size(subvol_affin,[1 2 3]).*[1 1 2],'nearest');
        subvol_x_affin_resized = subvol_x_affin_resized(1:2:end,1:2:end,:);
        subvol_y_affin_resized = subvol_y_affin_resized(1:2:end,1:2:end,:);
        subvol_z_affin_resized = subvol_z_affin_resized(1:2:end,1:2:end,:);
    else
        resized_size = ceil(size(subvol_affin,[1 2 3]).*[1 1 4]./[2 2 2]);
        subvol_x_affin_resized = imresize3(subvol_affin(:,:,:,1),resized_size,'nearest');
        subvol_y_affin_resized = imresize3(subvol_affin(:,:,:,2),resized_size,'nearest');
        subvol_z_affin_resized = imresize3(subvol_affin(:,:,:,3),resized_size,'nearest');
    end
    subvol_affin_resized = zeros([size(subvol_x_affin_resized) 3]);
    subvol_affin_resized(:,:,:,1) = subvol_x_affin_resized;
    subvol_affin_resized(:,:,:,2) = subvol_y_affin_resized;
    subvol_affin_resized(:,:,:,3) = subvol_z_affin_resized;
    % under the condition where the subvol_seg was truncated to even, offset preserved during this procedure
    offset_subvol_affin_resized = offset_subvol_seg;

end

function watershed_segmentation = fix_background_id_as_zero (watershed_segmentation)

    background_id_in_watershed_transform = watershed_segmentation(1,1,1);
    background_voxels_in_watershed_transform = watershed_segmentation == background_id_in_watershed_transform;
    zero_valued_voxels_in_watershed_transform = watershed_segmentation == 0;
    watershed_segmentation(zero_valued_voxels_in_watershed_transform) = background_id_in_watershed_transform;
    watershed_segmentation(background_voxels_in_watershed_transform) = 0;
    
end

% function voxels_to_be_merged = extract_voxels_to_be_merged_into_nearest_segment (volume,segmented_volume,threshold_for_dust_segment)
% 
%     nonzero_voxels_in_volume = find (volume~=0);
%     nonzero_voxels_in_segmented_volume = find (segmented_volume~=0);
%     voxels_to_be_merged = setdiff(nonzero_voxels_in_volume, nonzero_voxels_in_segmented_volume);
%     
%     dust_voxels = [];
%     [segment_info,segment_inds] = summarize_segment_info (segmented_volume);
%     for i=1:size(segment_info,2)
%         segment_id = segment_info(1,i);
%         segment_size = segment_info(2,i);
%         segment_cc_num = segment_info(3,i);
%         
%         if (segment_id ~= 0) && ((segment_size < threshold_for_dust_segment) || (segment_cc_num > 1))
%             dust_voxels = [dust_voxels; segment_inds{i}];
%         end
%     end
%     
%     dust_voxels_inside_target_component = intersect(nonzero_voxels_in_volume,dust_voxels);
%     voxels_to_be_merged = union(voxels_to_be_merged,dust_voxels_inside_target_component);
%     
% end

% function [segment_info,segment_inds] = summarize_segment_info (segmented_volume)
% 
%     id_list = unique(segmented_volume(:));
%     segment_info = [];
%     segment_inds = cell(1,length(id_list));
%     
%     for i=1:length(id_list)
%         current_id = double(id_list(i));
%         cc = bwconncomp(segmented_volume==current_id);
%         inds = find(segmented_volume==current_id);
%         segment_info(:,end+1) = [current_id; length(inds); cc.NumObjects];
%         segment_inds{i} = inds;
%     end
% 
% end

function voxels_to_be_merged = extract_voxels_to_be_merged_into_nearest_segment_v2 (volume,segmented_volume)

    nonzero_voxels_in_volume = find (volume~=0);
    nonzero_voxels_in_segmented_volume = find (segmented_volume~=0);
    voxels_to_be_merged = setdiff(nonzero_voxels_in_volume, nonzero_voxels_in_segmented_volume);
        
end

function complete_segmentation = merge_voxels_into_nearest_segment (volume,segmented_volume,voxels_to_be_merged)

    volume_minus_lost_voxels = volume;
    volume_minus_lost_voxels(voxels_to_be_merged) = 0;
    [~,nearest_segmented_voxel] = bwdist(volume_minus_lost_voxels);
    complete_segmentation = segmented_volume;
    nonzero_target_segment = nearest_segmented_voxel(voxels_to_be_merged) ~= 0;
    complete_segmentation(voxels_to_be_merged(nonzero_target_segment)) = segmented_volume(nearest_segmented_voxel(voxels_to_be_merged(nonzero_target_segment)));

end

function cell_of_spine_comp_ind_local = describe_segments_in_local_ind (complete_segmentation)

    id_list = setdiff(unique(complete_segmentation(:)),[0]);
    cell_of_spine_comp_ind_local = arrayfun(@(n) find(complete_segmentation==n),id_list, 'UniformOutput', false);
    
end

function global_sub = from_local_ind_to_global_sub (local_ind,size_subvol,offset_subvol)

    [x,y,z] = ind2sub(size_subvol,local_ind);
    global_sub = [x y z] + offset_subvol;

end
