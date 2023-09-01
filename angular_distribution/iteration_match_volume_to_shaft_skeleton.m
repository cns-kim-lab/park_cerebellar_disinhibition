%target_pc_dend_id_list = load_target_PC_dendrite_id_list;
%%
target_pc_dend_id_list = double(target_pc_dend_id_list([1 2 4:14])); % omit 1802,400,402

for i=1:length(target_pc_dend_id_list)
    target_pc_dend_id = target_pc_dend_id_list(i);
    dil_count_list = [5 10 15];
    for n=1:length(dil_count_list)
%     target_pc_dend_id = 2000;
        dilation_count = dil_count_list(n);
        fprintf('target_id = %d, dilation count : %d\n',target_pc_dend_id,dilation_count);
        [surroundings_w_valid_match_iso_mip3,shaft_skeleton_voxel_of_valid_match_iso_mip3,dbf_of_shaft_skeleton_voxel_of_valid_match,celltypes_of_surroundings_w_valid_match] = match_volume_to_shaft_skeleton_contain_volume_from_pc_w_sphere(target_pc_dend_id,dilation_count);
        %%
        save(sprintf('../result/result_surrounding_volume_match_to_shaft_skeleton_of_PC_%d.dilation_count_%d.self_spine_included.mat',target_pc_dend_id,dilation_count),'surroundings_w_valid_match_iso_mip3','shaft_skeleton_voxel_of_valid_match_iso_mip3','dbf_of_shaft_skeleton_voxel_of_valid_match','celltypes_of_surroundings_w_valid_match','target_pc_dend_id','-v7.3');
    end
end