function rtn = load_segment_size(idx, net_prefix, seg_list)
    home_vols = '/data/lrrtm3_wt_omnivol/';
    
    global size_of_uint32 size_of_chunk_linear size_of_chunk
    size_of_chunk = [128 128 128];
    size_of_chunk_linear = prod(size_of_chunk);
    size_of_uint32 = 4;

    volume_idx_str = sprintf('x%02d_y%02d_z%02d', idx);

    [path_of_vol_in_home, ~] = ...
        lrrtm3_get_vol_info(home_vols, net_prefix, volume_idx_str, 1);
    
    [~, seg_size] = omni_read_segment_size([home_vols path_of_vol_in_home], seg_list);    
    rtn = seg_size';
end