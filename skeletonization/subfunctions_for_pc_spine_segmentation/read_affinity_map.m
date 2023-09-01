function output_volume = read_affinity_map (coord_lower_bound, coord_upper_bound)

    affinity_map_directory = '/volume_3/lrrtm3_wt_affin/NetKslee';

    channel_h5_file = '/volume_3/lrrtm3_wt_recon/channel.h5';
    channel_h5_info = h5info(channel_h5_file,'/main');
    channel_h5_size = channel_h5_info.Dataspace.Size;
    
    sub_map_size = [512 512 128];
%     maximum_affinity_sub_map_number = ceil(channel_h5_size./sub_map_size);
    lower_bound_sub_map_number = ceil(coord_lower_bound./sub_map_size);
    upper_bound_sub_map_number = ceil(coord_upper_bound./sub_map_size);
    x_list_of_target_sub_map_number = lower_bound_sub_map_number(1):upper_bound_sub_map_number(1);
    y_list_of_target_sub_map_number = lower_bound_sub_map_number(2):upper_bound_sub_map_number(2);
    z_list_of_target_sub_map_number = lower_bound_sub_map_number(3):upper_bound_sub_map_number(3);
    
    output_volume_size = coord_upper_bound - coord_lower_bound + 1;
    output_volume_offset = coord_lower_bound - 1;
    output_volume = zeros([output_volume_size 3]);
    
    for xm = x_list_of_target_sub_map_number
        for ym = y_list_of_target_sub_map_number
            for zm = z_list_of_target_sub_map_number
                
                target_sub_map_index = [xm ym zm];
                target_sub_map_file = sprintf('%s/x%d_y%d_z%d_affinity.h5',affinity_map_directory,target_sub_map_index);
                offset_of_valid_region_of_target_sub_map = sub_map_size .* (target_sub_map_index-1);
                half_of_fov = [65 65 17];
                offset_of_whole_region_of_target_sub_map = max([0 0 0], offset_of_valid_region_of_target_sub_map - half_of_fov);
                
                lower_bound_of_valid_region_of_target_sub_map_global = max([1 1 1],sub_map_size .* (target_sub_map_index-1) + 1);
                upper_bound_of_valid_region_of_target_sub_map_global = min(sub_map_size .* target_sub_map_index, channel_h5_size);
                
                minimum_of_overlap_global = max(lower_bound_of_valid_region_of_target_sub_map_global,coord_lower_bound);
                maximum_of_overlap_global = min(upper_bound_of_valid_region_of_target_sub_map_global,coord_upper_bound);
                
                minimum_of_overlap_local = minimum_of_overlap_global - offset_of_whole_region_of_target_sub_map;
                maximum_of_overlap_local = maximum_of_overlap_global - offset_of_whole_region_of_target_sub_map;
                size_of_overlap =  maximum_of_overlap_local - minimum_of_overlap_local + 1;
                
                overlap_region = h5read(target_sub_map_file,'/main',[minimum_of_overlap_local 1],[size_of_overlap 3]);
                x1 = minimum_of_overlap_global(1) - output_volume_offset(1);
                x2 = maximum_of_overlap_global(1) - output_volume_offset(1);
                y1 = minimum_of_overlap_global(2) - output_volume_offset(2);
                y2 = maximum_of_overlap_global(2) - output_volume_offset(2);
                z1 = minimum_of_overlap_global(3) - output_volume_offset(3);
                z2 = maximum_of_overlap_global(3) - output_volume_offset(3);                
                output_volume(x1:x2,y1:y2,z1:z2,1:3) = overlap_region;
                
            end
        end
    end

end