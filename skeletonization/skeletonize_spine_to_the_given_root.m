function [spine_skeleton_path_to_given_root_sub_global,spine_skeleton_path_to_given_root_dbf] = skeletonize_spine_to_the_given_root (non_shaft_cc_sub, non_shaft_cc_root_voxel_sub, p_scale, p_const)

    addpath ./subfunctions_for_pc_spine_skeletonization/
    margin = 2;
    [subvolume, offset_bbox] = prepare_subvolume_including_spine (non_shaft_cc_sub, margin);

    size_subvol = size(subvolume);
    if length(non_shaft_cc_root_voxel_sub) ~= 3
        spine_skeleton_path_to_given_root_sub_global = {};
        spine_skeleton_path_to_given_root_dbf = {};
        return;
    end    
    source_pos = non_shaft_cc_root_voxel_sub - offset_bbox;
    source_ind = sub2ind(size_subvol,source_pos(1),source_pos(2),source_pos(3));

    dbf = bwdist(~subvolume);
    dbf = double(dbf);

    clear dijkstra_root2all
    [pdrf, indfrom, ~] = dijkstra_root2all (dbf, size_subvol, source_pos, 1);
    pdrf = pdrf .* subvolume;
    clear dijkstra_root2all
    [dsf, ~, ~] = dijkstra_root2all (dbf, size_subvol, source_pos, 0);
    dsf = dsf .* subvolume;

    [~, spine_skeleton_path_to_given_root_local_ind, ~] = backtracking4teasar_old (dbf, dsf, pdrf, indfrom, p_scale, p_const, source_ind, size_subvol);
    
    spine_skeleton_path_to_given_root_dbf = cellfun(@(x) dbf(x),spine_skeleton_path_to_given_root_local_ind, 'UniformOutput', false);
    [x,y,z] = cellfun(@(x) ind2sub(size_subvol,x), spine_skeleton_path_to_given_root_local_ind,'UniformOutput',false);
    spine_skeleton_path_to_given_root_sub_global = cellfun(@(a,b,c) [a' b' c'] + offset_bbox, x,y,z, 'UniformOutput', false);
    
end

function [subvolume, offset_bbox] = prepare_subvolume_including_spine (non_shaft_cc_sub, margin)

    
    bbox_lower_bound = min(non_shaft_cc_sub,[],1);
    bbox_upper_bound = max(non_shaft_cc_sub,[],1);
    bbox_size = bbox_upper_bound - bbox_lower_bound + 1;
    bbox_size_w_margin = bbox_size + margin*2;
    offset_bbox = bbox_lower_bound - margin - 1;
    
    subvolume = false(bbox_size_w_margin);

    non_shaft_cc_sub_in_subvolume = non_shaft_cc_sub - bbox_lower_bound + 1 + margin;
    non_shaft_cc_ind_in_subvolume = sub2ind(bbox_size_w_margin, non_shaft_cc_sub_in_subvolume(:,1), non_shaft_cc_sub_in_subvolume(:,2), non_shaft_cc_sub_in_subvolume(:,3));
    subvolume(non_shaft_cc_ind_in_subvolume) = true;

end
