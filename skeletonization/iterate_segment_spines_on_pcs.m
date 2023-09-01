target_id_list = load_target_PC_dendrite_id_list; 

% original_h5_file_dir = '/data/research/iys0819/cell_morphology_pipeline/volumes/';
% original_h5_file_name = 'shaft_spine_separation.iso_mip1.e7.th20000.d14.h5';
% original_h5_file_path = [original_h5_file_dir original_h5_file_name];

% original_h5_file_path : path to shaft-spine separated volume (iso mip1)
vol = h5read(original_h5_file_path,'/main');
dust_size = 1500;
%%
for i = 16:length(target_id_list)
    target_id = target_id_list(i);
    fprintf('spine segmentation of cell %d\n',target_id);
    fprintf('\t obtaining connnected components of the target cell\n');
    cc_vol_spine = bwconncomp(vol==(target_id*10+2));
    fprintf('\t Done.\n');
%%
    fprintf('\t spine segmentation, with additional merge\n');
    [num_spine_segment_total, spine_segment_global_sub, spine_segment_id_list, spine_segment_root_sub, spine_segment_original_comp_num, max_mean_affinity_values, mean_affinity_values] = segment_spines ...
                                        (original_h5_file_dir, original_h5_file_name, cc_vol_spine, target_id, dust_size, 1, 0);
                                    
    matfilename = sprintf('spine_segmentation_of_cell_%d.th_high_0.9_th_low_0.01_dust_%d.with_additional_merge.mat',target_id,dust_size);
    save([original_h5_file_dir matfilename],'num_spine_segment_total', 'spine_segment_global_sub', 'spine_segment_id_list', 'spine_segment_root_sub', 'spine_segment_original_comp_num', 'max_mean_affinity_values', 'mean_affinity_values','-v7.3');
    fprintf('\t Done.\n');
%%
    fprintf('\t spine segmentation, without additional merge\n');
    [num_spine_segment_total_2, spine_segment_global_sub_2, spine_segment_id_list_2, spine_segment_root_sub_2, spine_segment_original_comp_num_2, max_mean_affinity_values_2, mean_affinity_values_2] = segment_spines ...
                                        (original_h5_file_dir, original_h5_file_name, cc_vol_spine, target_id, dust_size, 0, 0);
                                    
    matfilename_2 = sprintf('spine_segmentation_of_cell_%d.th_high_0.9_th_low_0.01_dust_%d.no_additional_merge.mat',target_id,dust_size);
    save([original_h5_file_dir matfilename_2],'num_spine_segment_total_2', 'spine_segment_global_sub_2', 'spine_segment_id_list_2', 'spine_segment_root_sub_2', 'spine_segment_original_comp_num_2', 'max_mean_affinity_values_2', 'mean_affinity_values_2','-v7.3');
    fprintf('\t Done.\n');
end