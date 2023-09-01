function separate_pc_shaft_and_spine (pre_sep_seg_vol_path, output_dir, target_list,erosion_strength,dilation_strength,threshold_size)
  
    fprintf('read volume\n');
    % vol_iso_mip1 = uint16(h5read('/data/research/iys0819/cell_morphology_pipeline/volumes/pre_shaft-spine_separation.iso_mip1.h5','/main'));
    vol_iso_mip1 = uint16(h5read(pre_sep_seg_vol_path,'/main'));
    % pre_sep_seg_vol_path : path to h5 file of segmentation volume of PCs with soma separated from dendrite

    h5filename = sprintf('shaft_spine_separation.iso_mip1.e%d.th%d.d%d',erosion_strength,threshold_size,dilation_strength);
    ds_h5filename = sprintf('shaft_spine_separation.iso_mip1.e%d.th%d.d%d.ds_to_iso_mip2',erosion_strength,threshold_size,dilation_strength);

    vol_out = uint32(zeros(size(vol_iso_mip1)));
    h5filepath = [output_dir h5filename '.h5'];
    h5create(h5filepath,'/main',size(vol_out),'Datatype','uint32','ChunkSize',[128 128 128]);

    for i=1:length(target_list)
        target = target_list(i);

        fprintf('Shaft-spine separation of the cell %d\n',target);
        fprintf('Identify target voxel only\n');
        vol_iso_mip1_target = vol_iso_mip1 == target;
    
        fprintf('Remove minute dusts\n');
        cc_vol_iso_mip1_target = bwconncomp(vol_iso_mip1_target);
        num_cc_vol_iso_mip1_target = cellfun(@length, cc_vol_iso_mip1_target.PixelIdxList);
        [~,largest_cc] = max(num_cc_vol_iso_mip1_target);
        vol_iso_mip1_target = false(size(vol_iso_mip1_target));
        vol_iso_mip1_target(cc_vol_iso_mip1_target.PixelIdxList{largest_cc}) = true;
        clear cc_vol_iso_mip1_target

        fprintf('erode the target cell volume\n');
        se = strel('sphere',erosion_strength);
        vol_iso_mip1_target_eroded = imerode(vol_iso_mip1_target,se); 
        fprintf('get the connected components of the eroded volume\n');
        cc_vol_iso_mip1_target_eroded = bwconncomp(vol_iso_mip1_target_eroded);
        clear vol_iso_mip1_target_eroded;

        fprintf('leave the connected components over the threshold only\n');
        size_cc_vol_iso_mip1_target_eroded = cellfun(@length, cc_vol_iso_mip1_target_eroded.PixelIdxList);
        list_of_ccs_over_threshold = find(size_cc_vol_iso_mip1_target_eroded>threshold_size);
        vol_iso_mip1_target_eroded_thresholded = false(size(vol_iso_mip1_target));
        for i=1:length(list_of_ccs_over_threshold)
            vol_iso_mip1_target_eroded_thresholded(cc_vol_iso_mip1_target_eroded.PixelIdxList{list_of_ccs_over_threshold(i)})=true;
        end
        clear cc_vol_iso_mip1_target_eroded

        fprintf('dilate the thresholded & eroded volume to get boundary for dendrite\n');
        se=strel('sphere',dilation_strength); 
        bound_dendrite_vol_iso_mip1_target_eroded_thresholded_dilated = imdilate(vol_iso_mip1_target_eroded_thresholded,se);
        clear vol_iso_mip1_target_eroded_thresholded;

        fprintf('get dendrite part\n');
        vol_iso_mip1_target_dend = vol_iso_mip1_target.*bound_dendrite_vol_iso_mip1_target_eroded_thresholded_dilated;
        clear bound_dendrite_vol_iso_mip1_target_eroded_thresholded_dilated;

        fprintf('get spine part\n');
        vol_iso_mip1_target_spine = logical((vol_iso_mip1_target-vol_iso_mip1_target_dend)>0);

        fprintf('write to unified volume\n');
        vol_out(vol_iso_mip1_target_dend~=0) = target*10 + 1;
        
        clear vol_iso_mip1_target_dend
        vol_out(vol_iso_mip1_target_spine~=0) = target*10 + 2;
        clear vol_iso_mip1_target_spine
    
    end

    fprintf('write h5 file\n');
    h5write(h5filepath,'/main',vol_out);
        
    fprintf('write ds h5 file\n');
    vol_out_mip2 = vol_out(1:2:end,1:2:end,1:2:end);
    ds_h5filepath = [output_dir ds_h5filename '.h5'];
    h5create(ds_h5filepath,'/main',size(vol_out_mip2),'Datatype','uint32','ChunkSize',[128 128 128]);
    h5write(ds_h5filepath,'/main',vol_out_mip2);

end