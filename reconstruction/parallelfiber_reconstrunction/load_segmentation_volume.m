function cube = load_segmentation_volume(idx, net_prefix)
    home_vols = '/data/lrrtm3_wt_omnivol/';
    path_file_segmentation = sprintf('.files/segmentations/segmentation1/%d/volume.uint32_t.raw',0);
    
    global size_of_uint32 size_of_chunk_linear size_of_chunk
    size_of_chunk = [128 128 128];
    size_of_chunk_linear = prod(size_of_chunk);
    size_of_uint32 = 4;

    volume_idx_str = sprintf('x%02d_y%02d_z%02d', idx);

    [path_of_vol_in_home, vol_coord_info] = ...
        lrrtm3_get_vol_info(home_vols, net_prefix, volume_idx_str, 1); 
    file_path = sprintf('%s%s%s', home_vols, path_of_vol_in_home, path_file_segmentation);
    cube = lrrtm3_get_vol_segmentation(file_path, vol_coord_info);
end