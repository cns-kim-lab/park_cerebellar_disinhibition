function [extended_route,dbf_of_extended_route] = extend_route_to_parent_cc_to_skeleton(parent_cc_voxel_ind,skel_parent,source_parent,vol_size,route,dbf_route)

    margin = 2;
    [volume_parent_iso_mip3,offset_volume_parent_iso_mip3] = cut_volume_to_fit_target_segment (parent_cc_voxel_ind, vol_size, margin);
    cropped_vol_size = size(volume_parent_iso_mip3);
    
    skel_parent_local = skel_parent - offset_volume_parent_iso_mip3;
    skeleton_of_parent_ind = sub2ind(cropped_vol_size, skel_parent_local(:,1), skel_parent_local(:,2), skel_parent_local(:,3));
    source_parent_local = source_parent - offset_volume_parent_iso_mip3;

    dbf = bwdist(~volume_parent_iso_mip3);
    dbf = double(dbf);
    [pdrf,indfrom,~] = dijkstra_root2all (dbf, cropped_vol_size, source_parent_local, 1);
    pdrf = pdrf .* logical(volume_parent_iso_mip3);

    number_of_offspring_cc = numel(route);
    extension_in_the_parent_comp_sub = cell(size(route));
    dbf_extension_in_the_parent_comp = cell(size(route));
    
    for i=1:number_of_offspring_cc
        starting_point_local = route{i}(end,:) - offset_volume_parent_iso_mip3;
        [extension_in_the_parent_comp_sub_local,extension_in_the_parent_comp_ind] = backtrack_the_route_to_source (pdrf, indfrom, skeleton_of_parent_ind, source_parent_local, starting_point_local);
        extension_in_the_parent_comp_sub{i} = extension_in_the_parent_comp_sub_local + offset_volume_parent_iso_mip3;
        dbf_extension_in_the_parent_comp{i} = dbf(extension_in_the_parent_comp_ind);
    end
    
    extended_route = cellfun(@(a,b) [a; b],route,extension_in_the_parent_comp_sub,'UniformOutput',false);
    dbf_of_extended_route = cellfun(@(a,b) [a; b],dbf_route,dbf_extension_in_the_parent_comp,'UniformOutput',false);

end 

function [volume_new, offset_new] = cut_volume_to_fit_target_segment (target_connected_component, volume_size, margin)

    [x,y,z] = ind2sub(volume_size,target_connected_component);
    min_x = min(x); min_y = min(y); min_z = min(z);
    max_x = max(x); max_y = max(y); max_z = max(z);
    x = x - min_x + 1 + margin;
    y = y - min_y + 1 + margin;
    z = z - min_z + 1 + margin;
    volume_new = false(max_x-min_x+1+(margin*2),max_y-min_y+1+(margin*2),max_z-min_z+1+(margin*2));
    new_ind = sub2ind(size(volume_new),x,y,z);
    % +-margin around the min & max
    volume_new(new_ind) = true;
    offset_new = [min_x, min_y, min_z] - 1 - margin;

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
