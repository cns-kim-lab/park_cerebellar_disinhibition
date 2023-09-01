function subvol_w_shaft = overwrite_shaft_segment_to_spine_volume (subvol_watershed, target_cell_id, original_h5_file_path, offset_subvol)

    size_of_subvol = size(subvol_watershed);
    size_of_vol = h5info(original_h5_file_path,'/main').Dataspace.Size;
    
    lower_bound_of_window = offset_subvol + 1;
    upper_bound_of_window = min(offset_subvol + size_of_subvol, size_of_vol);
    
    size_of_window = upper_bound_of_window - lower_bound_of_window + 1;
    
    subvol_w_shaft = int32(zeros(size_of_subvol));
    subvol_w_shaft(1:size_of_window(1),1:size_of_window(2),1:size_of_window(3)) = uint8(h5read(original_h5_file_path,'/main',lower_bound_of_window,size_of_window)==(target_cell_id*10+1));    
    
    subvol_watershed(subvol_watershed~=0) = subvol_watershed(subvol_watershed~=0) + 1; % avoid id '1' for spine segments
    
    subvol_w_shaft = subvol_w_shaft + subvol_watershed;
    
end