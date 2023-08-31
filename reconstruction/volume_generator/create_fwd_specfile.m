%create fwd spec file (write all fwd cube info)
function create_fwd_specfile(cfg, fwd_joblist)
    %get cfg info 
    [job_default_path,~] = get_cfg(cfg, 'job_default_path');
    [fwd_input_path,~] = get_cfg(cfg, 'fwd_input_cube_save_path');
    [fwd_input_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    [fwd_spec_path,~] = get_cfg(cfg, 'fwd_net_spec_path');
    [fwd_preprocess_option,~] = get_cfg(cfg, 'fwd_preprocess');
    if strcmpi(fwd_preprocess_option, 'on')   
        [fwd_preprocess_mode,~] = get_cfg(cfg, 'fwd_preprocess_mode');
    end
    
    [row, ~] = size(fwd_joblist);
    %create file
    fid = fopen([job_default_path fwd_spec_path], 'w');
    fprintf(fid, '%s\n', '[files]');
    fprintf(fid, 'dir = %s\n', [job_default_path fwd_input_path]);
    fprintf(fid, ['img = %%(dir)s/' fwd_input_naming '.h5\n'], fwd_joblist{1,1});
    for iter=2:row
        fprintf(fid, '      %%(dir)s/');
        fprintf(fid, fwd_input_naming, fwd_joblist{iter,1});
        fprintf(fid, '.h5\n');
    end
    fprintf(fid, '\n[image]\nfile = img\n');
    if strcmpi(fwd_preprocess_option, 'on') %for old unet
        fprintf(fid, 'preprocess = dict(type=''standardize'',mode=''%s'')\n', upper(fwd_preprocess_mode));
    elseif strcmpi(fwd_preprocess_option, 'divideby') %for RS unet
        fprintf(fid, 'preprocess = dict(type=''divideby'')\n');
    end
    fprintf(fid,'\n[dataset]\ninput = image\n');
    fclose(fid);
    