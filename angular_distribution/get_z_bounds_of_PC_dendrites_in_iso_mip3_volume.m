function [list_of_target_pc_dend_id,z_min,z_max] = get_z_bounds_of_PC_dendrites_in_iso_mip3_volume (list_of_target_pc_dend_id)

    %% load iso mip3 volume
    % need (iso mip3) shaft-spine separation
    vol_iso_mip3_h5_path = '/data/lrrtm3_wt_reconstruction/segment_iso_mip3_all_cells_210503.pc_cb_cut_and_int_axon_cut.sample_first_sheet.h5';
    vol_iso_mip3 = h5read(vol_iso_mip3_h5_path,'/main');
    
    z_min = zeros(length(list_of_target_pc_dend_id),1);
    z_max = zeros(length(list_of_target_pc_dend_id),1);
    
    for i=1:length(list_of_target_pc_dend_id)
        
        target_pc_dend_id = list_of_target_pc_dend_id(i);
        fprintf('Finding z bounds of PC %d...\n',target_pc_dend_id);
        vol_iso_mip3_target_pc_dend = vol_iso_mip3 == target_pc_dend_id;
        [~,~,z] = ind2sub(size(vol_iso_mip3_target_pc_dend),find(vol_iso_mip3_target_pc_dend==1));
        z_min(i) = min(z);
        z_max(i) = max(z);
        
    end

end