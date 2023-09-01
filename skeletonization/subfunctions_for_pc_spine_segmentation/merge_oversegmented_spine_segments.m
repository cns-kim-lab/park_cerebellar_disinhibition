% function [cell_of_segments_of_watershed_local_ind, skeleton_root_of_each_spine_local_ind, affinity_boundary_ratios, min_affinity_boundary_ratios] = merge_oversegmented_spine_segments (cell_of_segments_of_watershed_local_ind, subvol_watershed, subvol_boundary_affin, offset_subvol, original_h5_file_path, threshold_merge)
 function [cell_of_segments_of_watershed_local_ind, skeleton_root_of_each_spine_local_ind, max_mean_affinity_values, mean_affinity_values, id_of_each_segment_at_first, segments_no_root_at_start, segments_merged, segments_deleted] = merge_oversegmented_spine_segments (target_cell_id, cell_of_segments_of_watershed_local_ind, subvol_watershed, subvol_affin_masked_and_truncated_by_seg, offset_subvol, original_h5_file_path, threshold_merge)


%% 1) adjacency info between spine and shaft segments
    %% 1-1) Superpose watershed result with shaft volume
    
    subvol_w_shaft = overwrite_shaft_segment_to_spine_volume (subvol_watershed, target_cell_id, original_h5_file_path, offset_subvol);
    id_of_each_segment = cellfun(@(x) subvol_w_shaft(x(1)),cell_of_segments_of_watershed_local_ind);
    id_of_each_segment_at_first = id_of_each_segment;
    
    %% 1-2) Get adjacency info of each spine segments using 'identify_adjacent_segments'
    [list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment,edges_at_boundary_from_neighboring_segment] = identify_adjacent_segments (subvol_w_shaft); 

    
%% 2) (recursively) merge rootless segments to neighbor w root
    %% 2-1) List segments without contact to shaft(id 1)
    contact_to_shaft_or_not = cellfun(@(x) ismember(1,x),list_of_neighboring_segment);
    segments_w_root = id_of_each_segment(contact_to_shaft_or_not);
    segments_no_root = id_of_each_segment(~contact_to_shaft_or_not);
    segments_no_root_at_start = segments_no_root;
    segments_merged = [];
    segments_deleted = [];
    max_mean_affinity_values = [];
    mean_affinity_values = [];

    while ~isempty(segments_no_root)

    %% 2-2) List segments without contact to shaft, but with contact to segment with contact to shaft
        segments_w_neighbor_w_root = id_of_each_segment(find(cellfun(@(x) sum(ismember(x,segments_w_root)),list_of_neighboring_segment)));
        segments_no_root_but_w_neighbor_w_root = segments_no_root(ismember(segments_no_root,segments_w_neighbor_w_root));
    
    %% 2-3) Select a target
        if isempty(segments_no_root_but_w_neighbor_w_root)
            for i=1:length(segments_no_root)
                target_segment_id = segments_no_root(i);
                segments_deleted(end+1) = target_segment_id;
                target_segment_ind = find(id_of_each_segment==target_segment_id);
                target_segment_voxels_local_ind = cell_of_segments_of_watershed_local_ind{target_segment_ind};
                subvol_w_shaft(target_segment_voxels_local_ind) = 0;
            end
            cell_of_segments_of_watershed_local_ind(ismember(id_of_each_segment,segments_no_root)) = [];
            [list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment,edges_at_boundary_from_neighboring_segment] = identify_adjacent_segments (subvol_w_shaft); 
            segments_no_root = [];
            break;
        end
        target_segment_id = segments_no_root_but_w_neighbor_w_root(1);
        target_segment_ind = find(id_of_each_segment == target_segment_id);

    %% 2-4) Compare the mean affinity at the interfaces with the neighbors with roots
        neighbor_w_root_ind = ismember(list_of_neighboring_segment{target_segment_ind},segments_w_root);
    
        affinity_of_edges_btw_neighbor_w_root = cellfun(@(e,f) subvol_affin_masked_and_truncated_by_seg([e;f]),...
                                                             edges_at_boundary_to_neighboring_segment{target_segment_ind}(neighbor_w_root_ind),...
                                                             edges_at_boundary_from_neighboring_segment{target_segment_ind}(neighbor_w_root_ind),...
                                                             'UniformOutput',false);
%                                                              x_edges_to_neighbors{target_segment_ind}(neighbor_w_root_ind),y_edges_to_neighbors{target_segment_ind}(neighbor_w_root_ind),z_edges_to_neighbors{target_segment_ind}(neighbor_w_root_ind),...
%                                                              'UniformOutput',false);

        mean_affinity_of_edges_to_the_neighbor_w_root = cellfun(@mean, affinity_of_edges_btw_neighbor_w_root);
        mean_affinity_values(end+1:end+length(mean_affinity_of_edges_to_the_neighbor_w_root)) = mean_affinity_of_edges_to_the_neighbor_w_root; 
        [max_mean_affinity,max_mean_affinity_ind] = max(mean_affinity_of_edges_to_the_neighbor_w_root);
        id_of_parent_candidate_segment = list_of_neighboring_segment{target_segment_ind}(max_mean_affinity_ind);
        max_mean_affinity_values(end+1) = max_mean_affinity;
    
    %% 2-5) Decide the target component to be merged to a neighbor or be removed  
            
        if  max_mean_affinity > threshold_merge
        % merge
            segments_merged(end+1) = target_segment_id;
            target_segment_voxels_local_ind = cell_of_segments_of_watershed_local_ind{target_segment_ind};
            size_of_merged_segment = length(target_segment_voxels_local_ind);
            cell_of_segments_of_watershed_local_ind{id_of_each_segment==id_of_parent_candidate_segment}(end+1:end+size_of_merged_segment) = target_segment_voxels_local_ind;
            
            cell_of_segments_of_watershed_local_ind(target_segment_ind) = [];
            subvol_w_shaft(target_segment_voxels_local_ind) = id_of_parent_candidate_segment;
%             subvol_watershed(target_segment_voxels_local_ind) = id_of_parent_candidate_segment;
        else
            % remove
            segments_deleted(end+1) = target_segment_id;
            target_segment_voxels_local_ind = cell_of_segments_of_watershed_local_ind{target_segment_ind};
            
            cell_of_segments_of_watershed_local_ind(target_segment_ind) = [];
            subvol_w_shaft(target_segment_voxels_local_ind) = 0;
        end
        
    %% 2-6) Renew contact info
        id_of_each_segment = cellfun(@(x) subvol_w_shaft(x(1)),cell_of_segments_of_watershed_local_ind);
        [list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment,edges_at_boundary_from_neighboring_segment] = identify_adjacent_segments (subvol_w_shaft); 
        contact_to_shaft_or_not = cellfun(@(x) ismember(1,x),list_of_neighboring_segment);
        segments_w_root = id_of_each_segment(contact_to_shaft_or_not);
        segments_no_root = id_of_each_segment(~contact_to_shaft_or_not);
    
    end
    
%% 3) return midpoint among the contact to shaft

    skeleton_root_of_each_spine_local_ind = select_root_for_skeleton_among_contact_to_shaft (cell_of_segments_of_watershed_local_ind,list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment,edges_at_boundary_from_neighboring_segment,size(subvol_w_shaft));
    
end



