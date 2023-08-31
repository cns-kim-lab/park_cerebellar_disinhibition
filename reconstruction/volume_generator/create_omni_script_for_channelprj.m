function create_omni_script_for_channelprj(cfg, chan_tbl, ridx, script_fname)
    %get cfg info
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [chan_naming,~] = get_cfg(cfg, 'channel_cube_naming');
    [chan_spath,~] = get_cfg(cfg, 'channel_cube_save_path');
    [omni_create_path,~] = get_cfg(cfg, 'omni_create_path');

        
    path_omni_exe = '/data/omni/omni.omnify/omni.omnify';
    omni_cmd_fname = ['omnicmd_' num2str(ridx) '.cmd'];
    
    offset = chan_tbl{ridx,2}-1;
    offset = offset .* [1,1,4];
    chan_fname = sprintf([default_path chan_spath chan_naming '.h5'], chan_tbl{ridx,1});
    cube_idx = chan_tbl{ridx,1};
    omni_prj_name = sprintf('x%02d_y%02d_z%02d_chanprj', cube_idx);
        
    mv_src = [omni_create_path omni_prj_name '.omni.files/channels'];
    mv_dst =  sprintf('%sz%02d/y%02d/channel_info/x%02d_y%02d_z%02d/', omni_create_path, cube_idx(3), cube_idx(2), cube_idx);
    mv_meta_src = [omni_create_path omni_prj_name '.omni.files/projectMetadata.yaml*'];
   
    %make omni - mv channel info - rm omni prj
    fid = fopen(script_fname, 'w');
    fprintf(fid, '#! /bin/bash\n');
    fprintf(fid, 'echo ''create:%s.omni'' >> %s\n', [omni_create_path omni_prj_name], omni_cmd_fname);
    fprintf(fid, 'echo ''loadHDF5chann:%s'' >> %s\n', chan_fname, omni_cmd_fname);    
    fprintf(fid, 'echo ''setChanAbsOffset:1,%d,%d,%d'' >> %s\n', offset, omni_cmd_fname);
    fprintf(fid, 'echo ''setChanResolution:1,1,1,4'' >> %s\n', omni_cmd_fname);
    fprintf(fid, 'echo ''close'' >> %s\n', omni_cmd_fname);
    fprintf(fid, '%s --headless --cmdfile %s\n', path_omni_exe, omni_cmd_fname);
    fprintf(fid, 'rm -rf %s\n', omni_cmd_fname);    
    fprintf(fid, 'chmod -R g+w %s%s.omni.files\n', omni_create_path, omni_prj_name);  
    fprintf(fid, 'mv %s %s\n', mv_src, mv_dst);
    fprintf(fid, 'mv %s %s\n', mv_meta_src, mv_dst);
    fprintf(fid, 'rm -rf %s.omni*\n', [omni_create_path omni_prj_name]);
    fclose(fid);
      