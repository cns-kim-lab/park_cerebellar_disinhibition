function skeleton_root_of_each_spine_local_ind = select_root_for_skeleton_among_contact_to_shaft (cell_of_segments_of_watershed_local_ind,list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment,edges_at_boundary_from_neighboring_segment,size_subvol)

    number_of_segments = length(list_of_neighboring_segment);
    skeleton_root_of_each_spine_local_ind = zeros(number_of_segments,1);
    
    for i=1:number_of_segments
        ind_contact_to_shaft = list_of_neighboring_segment{i} == 1;
        
        edges_to_shaft = edges_at_boundary_to_neighboring_segment{i}{ind_contact_to_shaft};
        [x_t,y_t,z_t,~] = ind2sub([size_subvol 3],edges_to_shaft);
        voxels_preceding_shaft = unique([x_t,y_t,z_t],'rows');
        voxels_preceding_shaft_ind = sub2ind(size_subvol,voxels_preceding_shaft(:,1),voxels_preceding_shaft(:,2),voxels_preceding_shaft(:,3));

        edges_from_shaft = edges_at_boundary_from_neighboring_segment{i}{ind_contact_to_shaft};
        [x_f,y_f,z_f,w_f] = ind2sub([size_subvol 3],edges_from_shaft);
        edges_from_shaft_sub = [x_f,y_f,z_f,w_f];
        voxels_succeeding_shaft = unique([edges_from_shaft_sub(edges_from_shaft_sub(:,4)==1,1:3) + [1 0 0];...
                                    edges_from_shaft_sub(edges_from_shaft_sub(:,4)==2,1:3) + [0 1 0];...
                                    edges_from_shaft_sub(edges_from_shaft_sub(:,4)==3,1:3) + [0 0 1];],'rows');
        voxels_succeeding_shaft_ind = sub2ind(size_subvol,voxels_succeeding_shaft(:,1),voxels_succeeding_shaft(:,2),voxels_succeeding_shaft(:,3));
        
        voxels_contact_to_shaft = intersect(cell_of_segments_of_watershed_local_ind{i},[voxels_preceding_shaft_ind; voxels_succeeding_shaft_ind]);
        skeleton_root_of_each_spine_local_ind(i) = select_midpoint(voxels_contact_to_shaft,size_subvol);
    end

end

function midpoint = select_midpoint(voxels_ind,size_vol)

    [x,y,z] = ind2sub(size_vol,voxels_ind);

    median_of_voxels_sub = median([x y z]);
    distance_from_median = vecnorm([x y z] - median_of_voxels_sub,2,2);
    [~,midpoint_rownum] = min(distance_from_median);
    midpoint = voxels_ind(midpoint_rownum);
    
end

