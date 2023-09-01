function [list_of_neighboring_segment,edges_at_boundary_to_neighboring_segment, edges_at_boundary_from_neighboring_segment] = identify_adjacent_segments (vol)
% function [list_of_neighboring_segment,x_edges_to_a_segment,y_edges_to_a_segment,z_edges_to_a_segment] = identify_adjacent_segments (vol, cell_spine_components_local_ind)
% In 'vol', shaft and each spine component should be identified by distinct ids.

    % retrieve neighboring segment info for each voxel
    neighborhood_info_array = check_neighboring_segment (vol); % check_neighborhood : [size(vol) 6] sized array, describing neighboring
                                                          % segment id of each voxel only when the voxel is adjacent to another segment  
    % Among voxels belonging to each spine component, list every edge to/from each neighboring segment  
    [list_of_neighboring_segment, edges_at_boundary_to_neighboring_segment, edges_at_boundary_from_neighboring_segment] = list_edges_to_neighboring_segment(neighborhood_info_array, vol);

end

function check_neighborhood = check_neighboring_segment (vol)

    padded_vol = zeros(size(vol)+1);
    padded_vol(1:end-1,1:end-1,1:end-1) = vol;
    padded_vol(padded_vol==0) = NaN;
    
    % check if there's '1' in neighborhood  
    check_neighborhood = NaN([size(vol) 3]);
    original_vol = padded_vol(1:end-1,1:end-1,1:end-1);
                                      
    shifted_volume = padded_vol(2:end,1:end-1,1:end-1);
    check_neighborhood(:,:,:,1) = ((shifted_volume - original_vol)~=0) .* ~isnan(shifted_volume - original_vol) .* shifted_volume;     

    shifted_volume = padded_vol(1:end-1,2:end,1:end-1);
    check_neighborhood(:,:,:,2) = ((shifted_volume - original_vol)~=0) .* ~isnan(shifted_volume - original_vol) .* shifted_volume;    
    
    shifted_volume = padded_vol(1:end-1,1:end-1,2:end);
    check_neighborhood(:,:,:,3) = ((shifted_volume - original_vol)~=0) .* ~isnan(shifted_volume - original_vol) .* shifted_volume; 
    
end

function [list_of_neighboring_segment, edges_at_boundary_to_neighboring_segment, edges_at_boundary_from_neighboring_segment] = list_edges_to_neighboring_segment(neighborhood_info_array, vol_seg)

%     size_vol = size(vol_seg);

    % extract edges that matter
    edges_at_boundaries = neighborhood_info_array~=0 & ~isnan(neighborhood_info_array);
    edges_at_boundaries = find(edges_at_boundaries == 1);
    vol_seg_threefold = repmat(vol_seg,[1 1 1 3]);
    
    % col1 : edge index in subvol_affin, col2 : segment id, col3 : contacting neighbor segment id
    edge_info = [edges_at_boundaries vol_seg_threefold(edges_at_boundaries) neighborhood_info_array(edges_at_boundaries)];
           
    segment_ids = setdiff(unique(vol_seg(:)),[0 1]);
    % make cells for each component's neighbors
    % iterate on cell ids in vol_seg
    list_of_neighboring_segment = arrayfun(@(s) unique(union(edge_info(edge_info(:,2)==s,3),edge_info(edge_info(:,3)==s,2))),segment_ids,'UniformOutput',false);
    
    % cells of cells, containing edges connecting to neighboring components
    % refer to neighborhood_info_array again
    edges_at_boundary_to_neighboring_segment = cellfun(@(s,l) arrayfun(@(n) edge_info(edge_info(:,2)==s & edge_info(:,3)==n,1),l,'UniformOutput',false),...
                                                        mat2cell(segment_ids,ones(size(segment_ids))),list_of_neighboring_segment,'UniformOutput',false);
                                                    
    edges_at_boundary_from_neighboring_segment = cellfun(@(s,l) arrayfun(@(n) edge_info(edge_info(:,3)==s & edge_info(:,2)==n,1),l,'UniformOutput',false),...
                                                        mat2cell(segment_ids,ones(size(segment_ids))),list_of_neighboring_segment,'UniformOutput',false);

end
