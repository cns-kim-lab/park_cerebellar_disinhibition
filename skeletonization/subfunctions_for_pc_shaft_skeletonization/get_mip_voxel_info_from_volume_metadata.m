function [sub_local, offset, mip_vol_size] = get_mip_voxel_info_from_volume_metadata (net_id,vxyz,supervoxel_list,default_vol_size,default_overlap_size)
   
    vol_id = sprintf('x%02d_y%02d_z%02d',vxyz);
    [path_vol,vol_coord_info] = lrrtm3_get_vol_info('/data/lrrtm3_wt_omnivol/',net_id,vol_id,1);
    file_path = sprintf('/data/lrrtm3_wt_omnivol/%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',path_vol, 0);       
    chunk = lrrtm3_get_vol_segmentation(file_path,vol_coord_info);
    chunk = ismember(chunk, supervoxel_list); 

    ind_local = find(chunk);
    [x_local,y_local,z_local] = ind2sub(size(chunk),ind_local);
    sub_local = [x_local,y_local,z_local];
    offset = (vxyz - 1) .* (default_vol_size - default_overlap_size);

    mip_vol_size = vol_coord_info.mip_vol_size;
    
end
