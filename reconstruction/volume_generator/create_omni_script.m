function create_omni_script(cfg, seg_fname, chan_tbl, ridx)
    %get cfg info
    [omni_create_path,~] = get_cfg(cfg, 'omni_create_path');
    [net_prefix,~] = get_cfg(cfg, 'omni_net_prefix');
%     [tracer_list,valid] = get_cfg(cfg, 'omni_tracer_list');  %for old omni
%     if valid ~= 1
%         tracer_list = cell(1,1);
%         tracer_list{1,1} = 'joinuser';
%     else
%         tracer_list = strsplit(tracer_list, ',');        
%     end
%     tracer_list = tracer_list .';
%     [nuser,~] = size(tracer_list);
        
    path_omni_exe = '/data/omni/omni.omnify/omni.omnify';
    
    cube_idx = chan_tbl{ridx,1};
    omni_cmd_fname = sprintf('omnicmd_x%dy%dz%d.cmd', cube_idx);
%     omni_cmd_fname = ['omnicmd_' num2str(ridx) '.cmd'];
    
    offset = chan_tbl{ridx,2}-1;
    offset = offset .* [1,1,4]; %z axis resolution 
%     chan_fname = sprintf([default_path chan_spath chan_naming '.h5'], chan_tbl{ridx,1});
    script_fname = sprintf('%smake_x%dy%dz%d.sh', omni_create_path, cube_idx);
%     script_fname = [omni_create_path 'make_' num2str(ridx) '.sh'];
    omni_prj_name = sprintf('z%02d/y%02d/Net_%s_x%02d_y%02d_z%02d_st_%04d_%04d_%04d_sz_%d_%d_%d', ...
        cube_idx(3), cube_idx(2), net_prefix, cube_idx, (chan_tbl{ridx,2}).*[1,1,4], chan_tbl{ridx,4});
    ln_target = sprintf('z%02d/y%02d/channel_info/x%02d_y%02d_z%02d/channels', cube_idx(3), cube_idx(2), cube_idx);
    ln_loc = [omni_prj_name '.omni.files/channels'];
    
    fid = fopen(script_fname, 'w');
    fprintf(fid, '#! /bin/bash\n');
    fprintf(fid, 'echo ''create:%s.omni'' >> %s\n', [omni_create_path omni_prj_name], omni_cmd_fname);
    fprintf(fid, 'echo ''loadHDF5seg:%s'' >> %s\n', seg_fname, omni_cmd_fname);
    fprintf(fid, 'echo ''mesh'' >> %s\n', omni_cmd_fname);    
%     fprintf(fid, 'echo ''loadHDF5chann:%s'' >> %s\n', chan_fname, omni_cmd_fname);    
%     fprintf(fid, 'echo ''setChanAbsOffset:1,%d,%d,%d'' >> %s\n', offset, omni_cmd_fname);
    fprintf(fid, 'echo ''setSegAbsOffset:1,%d,%d,%d'' >> %s\n', offset, omni_cmd_fname);
    fprintf(fid, 'echo ''setSegResolution:1,1,1,4'' >> %s\n', omni_cmd_fname);
    fprintf(fid, 'echo ''close'' >> %s\n', omni_cmd_fname);
    fprintf(fid, '%s --headless --cmdfile %s\n', path_omni_exe, omni_cmd_fname);
    fprintf(fid, 'rm -rf %s\n', omni_cmd_fname);
    fprintf(fid, 'rm -rf %s\n', seg_fname);
%     for iter=1:nuser %for old omni
%         fprintf(fid, 'cp -R %s%s.omni.files/users/_default %s%s.omni.files/users/%s\n', ...
%           omni_create_path, omni_prj_name, omni_create_path, omni_prj_name, tracer_list{iter,1});
%     end
    fprintf(fid, 'chmod -R g+w %s%s.omni.files\n', omni_create_path, omni_prj_name);
    fprintf(fid, 'ln -s %s%s %s%s\n', omni_create_path, ln_target, omni_create_path, ln_loc);
    fprintf(fid, 'chown -R :kimlab_tracer %s%s.omni*\n', omni_create_path, omni_prj_name);
    fprintf(fid, 'chmod g+x %s%s.omni*\n', omni_create_path, omni_prj_name);
    fclose(fid);
    
    sys_cmd = ['chmod ug+wx ' script_fname];
    system(sys_cmd);    
    