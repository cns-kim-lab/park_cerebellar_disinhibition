%% load data
target_pc_dend_id_list = load_target_PC_dendrite_id_list;
target_pc_dend_id_list = double(target_pc_dend_id_list([1 2 4:14])); % omit 1802,400,402

%% loop
dil_count_list = [5 10 15];
for i=1:length(target_pc_dend_id_list)
    target_pc_id = target_pc_dend_id_list(i);
    for n=1:length(dil_count_list)
        dil_count = dil_count_list(n);
        fprintf('%d, %d\n',target_pc_id,dil_count);

        mat_dir_1 = '/data/research/iys0819/cell_morphology_analysis/angular_composition_around_pc_dend/result';
        mat_dir_2 = '/data/research/iys0819/cell_morphology_pipeline/result';

        %% list target info

        match_result_file_path = sprintf('%s/result_surrounding_volume_match_to_shaft_skeleton_of_PC_%d.dilation_count_%d.self_spine_included.mat',mat_dir_1,target_pc_id,dil_count);
        skel_direction_file_path = sprintf('%s/directions_on_skeleton_pc_shaft/directions_on_shaft_skeleton_of_cell_%d.mat',mat_dir_2,target_pc_id);   
        load(match_result_file_path);
        load(skel_direction_file_path);

        %% skeleton voxel identification
        [~,ind_skeleton_voxel] = ismember(shaft_skeleton_voxel_of_valid_match_iso_mip3,merged_merged_pos,'rows');
        %%
        dend_dir = merged_merged_dir(ind_skeleton_voxel,:);
        hori_dir = horizontal_vector(ind_skeleton_voxel,:);
        vert_dir = vertical_vector(ind_skeleton_voxel,:);
        %%    
        %%
        root_dir = surroundings_w_valid_match_iso_mip3 - shaft_skeleton_voxel_of_valid_match_iso_mip3;
        proj_root_dir = root_dir - dend_dir.*dot(root_dir,dend_dir,2);
        norm_proj_root_dir = proj_root_dir./vecnorm(proj_root_dir,2,2);

        %% save
        out_mat_dir = mat_dir_1;
        total_out_mat_path = sprintf('%s/directions_of_surrounding_volume_voxels_of_PC_%d.dilation_count_%d.self_spine_included.mat',out_mat_dir,target_pc_id,dil_count);

        save(total_out_mat_path,...
            'dend_dir','hori_dir','vert_dir','norm_proj_root_dir',...
            '-v7.3');

    end
end