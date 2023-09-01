function auto_repeat_spine_skel (target_pc, start_num, end_num)

    p_scale = 1.2;
    % 20->10->12
    p_const = 12;
    
    spine_data_mat_file_path = sprintf('/data/research/iys0819/cell_morphology_pipeline/result/pc_spine_separation/spine_segmentation_of_cell_%d.th_high_0.9_th_low_0.01_dust_1500.with_additional_merge.mat',target_pc);
        
    load(spine_data_mat_file_path,'num_spine_segment_total');
    total_component_number = num_spine_segment_total;
    end_num = min(end_num,total_component_number);

    if start_num <= total_component_number
        
        load(spine_data_mat_file_path,'spine_segment_global_sub','spine_segment_root_sub');
        output_file_path = sprintf('/data/research/iys0819/cell_morphology_pipeline/result/skeleton_pc_spine/spine_skeleton_of_cell_%d.from_spine_segmentation.th_high_0.9_th_low_0.01_dust_1500.w_am.mat',target_pc);
        if isfile(output_file_path)
            load(output_file_path,'spine_skeleton_path_to_given_root_sub_global','spine_skeleton_path_to_given_root_dbf');
        else
            spine_skeleton_path_to_given_root_sub_global = cell(total_component_number,1);
            spine_skeleton_path_to_given_root_dbf = cell(total_component_number,1);
        end

        for i = start_num:end_num
            fprintf('skeletonizing the spine component %d of %d components\n',i,total_component_number);
            target_spine_comp = spine_segment_global_sub{i};
            target_spine_root = spine_segment_root_sub(i,1:3);
            [spine_skeleton_path_to_given_root_sub_global{i,1},spine_skeleton_path_to_given_root_dbf{i,1}] = skeletonize_spine_to_the_given_root (target_spine_comp,target_spine_root,p_scale,p_const);
        end
    
        save(output_file_path,'spine_skeleton_path_to_given_root_sub_global','spine_skeleton_path_to_given_root_dbf','p_scale','p_const','-v7.3');
    % skeletonize_spine_attaching_to_shaft (dust_removed_h5_file_name, size_vol_shaft, target_spine_comp_sub_file_name, nearest_skeleton_voxel_info_file_name, p_scale, p_const, start_num, end_num);
    end

end