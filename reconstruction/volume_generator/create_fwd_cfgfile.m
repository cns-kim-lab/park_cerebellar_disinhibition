function create_fwd_cfgfile(cfg, fwd_tbl, fwd_ridx)
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [fwd_net_proto,~] = get_cfg(cfg, 'fwd_net_prototxt');
    [fwd_net_wei,~] = get_cfg(cfg, 'fwd_net_weight');
    [fwd_net_spec,~] = get_cfg(cfg, 'fwd_net_spec_path');
    [fwd_result_path,~] = get_cfg(cfg, 'fwd_result_path');
    [fwd_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    [netname,~] = get_cfg(cfg, 'netname');
%     [fwd_net_fov,~] = get_cfg(cfg, 'fwd_net_fov');    %for old unet
%     fwd_net_fov = str2num(fwd_net_fov); %must do flip dim
    
%     kaffe_path = '/data/research/jwgim/cnn_pkg/kaffe';    %for old unet
    kaffe_path = '/data/research/jwgim/cnn_pkg/kaffe_new_cfg';
    savename = sprintf('%s%s%sx%dy%dz%d%s', default_path, netname, '/cfg_', fwd_tbl{fwd_ridx,1}, '.cfg');
    
    fwd_output_name = sprintf(fwd_naming, fwd_tbl{fwd_ridx,1});
    
    %create file
    fid = fopen(savename, 'w');
    fprintf(fid, '[forward]\n');
    fprintf(fid, 'kaffe_root = %s\n', kaffe_path);
    fprintf(fid, 'dspec_path = %s\n', [default_path fwd_net_spec]);
    fprintf(fid, 'model = %s\n', [default_path fwd_net_proto]);
    fprintf(fid, 'weights = %s\n', [default_path fwd_net_wei]);
%     fprintf(fid, 'test_range = [%d]\n', fwd_ridx-1);  %for old unet
%     fprintf(fid, 'fov = (%d,%d,%d)\n', fwd_net_fov(3), fwd_net_fov(2), fwd_net_fov(1));
%     fprintf(fid, 'border = dict(type=''mirror_border'', fov=%%(fov)s)\n');
    fprintf(fid, 'drange = [%d]\n', fwd_ridx-1);    %for RS unet
    fprintf(fid, 'border = None\n');
%     fprintf(fid, 'scan_list = [''output'']\n');   %for old unet
%     fprintf(fid, 'scan_params = None\n');
    fprintf(fid, 'scan_params = dict(stride=(0.5,0.5,0.5), blend=''bump'')\n');     %for RS unet
    fprintf(fid, 'scan_list = {''affinity'':dict(dst=(1,1,1))}\n');
    fprintf(fid, 'flip_spec = {0:'''', 7:''flip-xy'', 15:''flip-xyz''}\n');
    fprintf(fid, 'save_prefix = %s%s\n', fwd_result_path, fwd_output_name);
    
    fclose(fid);
 
 