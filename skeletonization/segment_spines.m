function [num_spine_segment_total, spine_segment_global_sub, spine_segment_id_list, spine_segment_root_sub, spine_segment_original_comp_num, max_mean_affinity_values, mean_affinity_values] = segment_spines (original_h5_file_dir, original_h5_file_name, cc_vol_spine, target_id, dust, additional_merge, write_spine_segmented_volume_or_not)
% function [num_spine_segment_total, spine_segment_global_sub, spine_segment_id_list, spine_segment_root_sub, spine_segment_original_comp_num, max_mean_affinity_values, mean_affinity_values] = segment_spines (original_h5_file_dir, original_h5_file_name, write_spine_segmented_volume_or_not, threshold_affin)

    addpath ./subfunctions_for_pc_spine_segmentation/
    %% parameters
    original_h5_file_path = [original_h5_file_dir original_h5_file_name];
    size_of_vol = h5info(original_h5_file_path,'/main').Dataspace.Size;
%     offset_of_vol = [0 0 558];
    offset_of_vol = [0 0 0];
    threshold_for_dust_segment = dust;
    threshold_affin_high = 0.90;
    imfill_or_not = 0;
%     additional_merge = 1;
    threshold_merge = 0.5;
      
    %% volume & cc preparation  
%     vol = double(h5read(original_h5_file_path,'/main')==2);
%     vol_spine = vol==(target_id*100+1);
%     cc_vol_spine = bwconncomp(vol_spine);
%     clear vol_spine
    num_cc_vol_spine = cc_vol_spine.NumObjects;
    
    %% empty cell & arrays to store results
    num_spine_segment_total = 0;
    spine_segment_global_sub = {};
    max_mean_affinity_values = cell(num_cc_vol_spine,1);
    mean_affinity_values = cell(num_cc_vol_spine,1);
    spine_segment_id_list = [];
    spine_segment_root_sub = [];
    spine_segment_original_comp_num = [];
    last_spine_id = 2;
    
    %% iteration of watershed segmentation
    tic;
    start_num = 1;
    for i=start_num:num_cc_vol_spine
        fprintf('Spine component (%d of %d) in %d...\n',i,num_cc_vol_spine,target_id);
        target_spine_comp = cc_vol_spine.PixelIdxList{i};
                                                                                                                                
        [cell_of_spine_comp_global_sub, skeleton_root_of_each_spine_global_sub, max_mean_affinity, mean_affinity] = get_watershed_segmentation_of_spine_components...
                                                                                                                                    (target_id,...
                                                                                                                                    target_spine_comp,...
                                                                                                                                    size_of_vol,...
                                                                                                                                    offset_of_vol,...
                                                                                                                                    threshold_for_dust_segment,...
                                                                                                                                    threshold_affin_high,...
                                                                                                                                    imfill_or_not,...
                                                                                                                                    original_h5_file_path,...
                                                                                                                                    additional_merge,...
                                                                                                                                    threshold_merge);
        num_spine_segment_of_iteration = length(cell_of_spine_comp_global_sub);
        num_spine_segment_total = num_spine_segment_total + num_spine_segment_of_iteration;
        spine_segment_global_sub(end+1:end+num_spine_segment_of_iteration) = cell_of_spine_comp_global_sub;
        max_mean_affinity_values{i} = max_mean_affinity;
        mean_affinity_values{i} = mean_affinity;
        spine_segment_id_list(end+1:end+num_spine_segment_of_iteration) = last_spine_id+1:last_spine_id+num_spine_segment_of_iteration;
        if ~isempty(spine_segment_id_list)
            last_spine_id = spine_segment_id_list(end);
        end
        % spine id : 3 ~ #+2 (1 for shaft, 2 for neglected spine components)
        spine_segment_root_sub(end+1:end+num_spine_segment_of_iteration,1:3) = skeleton_root_of_each_spine_global_sub;
        spine_segment_original_comp_num(end+1:end+num_spine_segment_of_iteration,1) = i;
    end
    toc;
    
    %% save results
%     save(sprintf('spine_segmentation_of_%s.th_affin_%.3f.th_merge_%.2f.mat',original_h5_file_name,threshold_affin,threshold_merge), 'num_spine_segment_total', 'spine_segment_global_sub', 'spine_segment_id_list', 'spine_segment_root_sub','-v7.3');

    %% write spine segmented volume
    if write_spine_segmented_volume_or_not
        
        vol = double(h5read(original_h5_file_path,'/main')==1);
        for i=1:num_spine_segment_total
            ith_spine_segment_global_ind = sub2ind(size_of_vol,spine_segment_global_sub{i}(:,1),spine_segment_global_sub{i}(:,2),spine_segment_global_sub{i}(:,3));
            vol(ith_spine_segment_global_ind) = spine_segment_id_list(i); 
        end
        
        spine_segmented_h5_file_path = sprintf('%s.spine_segmented.th_affin_%.3f.th_merge_%.2f.h5',original_h5_file_path,threshold_affin,threshold_merge);
        h5create(spine_segmented_h5_file_path,'/main',size_of_vol,'Datatype','uint32','ChunkSize',[128 128 128]);
        h5write(spine_segmented_h5_file_path,'/main',uint32(vol));
    end

end

% 2020/12/29  
% parameters : 
% original_h5_file_dir = '/data/research/iys0819/analysis_synapse_detection/volumes/'
% original_h5_file_name = 'shaft_and_else.cell_11.iso_mip1_new.e5.th5000.d10.e2.th400.d4.h5'
% write_spine_segmented_volume_or_not = false
% original_h5_file_path = [original_h5_file_dir original_h5_file_name];
% size_of_vol = h5info(original_h5_file_path,'/main').Dataspace.Size;
% offset_of_vol = [0 0 558];
% threshold_for_dust_segment = 100;
% threshold_affin = 0.25;
% margin_for_subvol_generation = 3;
% imfill_or_not = 0;
% threshold_merge = 0.9;
