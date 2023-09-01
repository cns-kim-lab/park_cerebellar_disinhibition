function subvol_affin_resized = load_affin_map_of_input_segment_range (offset_of_vol,offset_subvol_seg,size_subvol_seg)
  
    affin_offset_subvol_seg_in_original_volume = (offset_subvol_seg + offset_of_vol) .*2 ./ [1 1 4];
    affin_size_of_subvol_seg = size_subvol_seg;
    affin_size_of_subvol_seg_in_original_volume = ceil(affin_size_of_subvol_seg .*2 ./ [1 1 4]);
    
    coord_lower_bound = affin_offset_subvol_seg_in_original_volume + 1;
    coord_upper_bound = affin_offset_subvol_seg_in_original_volume + affin_size_of_subvol_seg_in_original_volume;
    subvol_affin = read_affinity_map (coord_lower_bound,coord_upper_bound);
    
    resized_size = ceil(size(subvol_affin,[1 2 3]).*[1 1 4]./[2 2 2]);
    subvol_x_affin_resized = imresize3(subvol_affin(:,:,:,1),resized_size,'nearest');
    subvol_y_affin_resized = imresize3(subvol_affin(:,:,:,2),resized_size,'nearest');
    subvol_z_affin_resized = imresize3(subvol_affin(:,:,:,3),resized_size,'nearest');
    subvol_affin_resized = zeros([size(subvol_x_affin_resized) 3]);
    subvol_affin_resized(:,:,:,1) = subvol_x_affin_resized;
    subvol_affin_resized(:,:,:,2) = subvol_y_affin_resized;
    subvol_affin_resized(:,:,:,3) = subvol_z_affin_resized;
    % under the condition where the subvol_seg was truncated to even, offset preserved during this procedure
    offset_subvol_affin_resized = offset_subvol_seg;

end