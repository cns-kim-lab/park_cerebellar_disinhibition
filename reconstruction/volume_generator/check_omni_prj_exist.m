function prj_exist = check_omni_prj_exist(omni_path, net, chan_tbl, ridx)
%     %get cfg info
%     [omni_path,~] = get_cfg(cfg, 'omni_create_path');
%     [net,~] = get_cfg(cfg, 'omni_net_prefix');
    
    startp = chan_tbl{ridx,2};
    startp = startp .* [1,1,4];
    cube_idx = chan_tbl{ridx,1};
    prj_name = sprintf('z%02d/y%02d/Net_%s_x%02d_y%02d_z%02d_st_%04d_%04d_%04d_sz_%d_%d_%d', cube_idx(3), cube_idx(2), net, cube_idx, startp, chan_tbl{ridx,4});
    full_name = [omni_path prj_name '.omni'];
    
    if exist(full_name, 'file')
        prj_exist = 1;
    else
        prj_exist = 0;
    end
    