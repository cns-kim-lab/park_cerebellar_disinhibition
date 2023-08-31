function [x_affinity, y_affinity, z_affinity] = load_affinity_volume(idx, net_prefix)
    x_affinity = [];
    y_affinity = [];
    z_affinity = [];
    
    if ~strncmpi(net_prefix, 'C1', 2) && ~strncmpi(net_prefix, 'B2', 2)
        print_(sprintf('@ERROR: unexpected net prefix(%s). load affinity volume(%d_%d_%d) failed.', net_prefix, idx), 1);
        return
    end

    cfg_fname = 'cfg_affin.txt';
%     jobconfig_path = ['/data/research/jwgim/matlab_code/pf_reconstruction/' cfg_fname];
    jobconfig_path = ['/data/lrrtm3_wt_code/matlab/pf_reconstruction/' cfg_fname];
    jobcfg = parsing_jobconfig(jobconfig_path);    
    
    % change start_cube_idx
    cidx = find(strcmpi('start_cube_idx', jobcfg(:,1)),1);
    if isempty(cidx) 
        print_(sprintf('@ERROR: start_cube_idx field not exists in job config file. load affinity volume(%d_%d_%d) failed.', idx), 1);
        return
    end
    jobcfg{cidx,2} = sprintf('%d,%d,%d', idx);    
    
    %change netname, fov, fwd_result_path
    cidx_netname = find(strcmpi('netname', jobcfg(:,1)), 1);
    if isempty(cidx_netname)
        print_(sprintf('@ERROR: netname field not exists in job config file. load affinity volume(%d_%d_%d) failed.', idx), 1);
    end
    cidx_fov = find(strcmpi('fwd_net_fov', jobcfg(:,1)), 1);
    if isempty(cidx_fov)
        print_(sprintf('@ERROR: fov field not exists in job config file. load affinity volume(%d_%d_%d) failed.', idx), 1);
    end
    cidx_fwd_path = find(strcmpi('fwd_result_path', jobcfg(:,1)), 1);
    if isempty(cidx_fwd_path)
        print_(sprintf('@ERROR: affin path field not exists in job config file. load affinity volume(%d_%d_%d) failed.', idx), 1);
    end
    cidx_omni_net = find(strcmpi('omni_net_prefix', jobcfg(:,1)), 1);
    if isempty(cidx_omni_net)
        print_(sprintf('@ERROR: omni net prefix field not exists in job config file. load affinity volume(%d_%d_%d) failed.', idx), 1);
    end
    
    if strncmpi(net_prefix, 'C1', 2)    %if net_prefix is C1*
        jobcfg{cidx_netname,2} = sprintf('%s', 'NetKslee');
        jobcfg{cidx_fov,2} = sprintf('%d,%d,%d', 129,129,33);
        jobcfg{cidx_fwd_path, 2} = sprintf('%s', '/data/lrrtm3_wt_affin/NetKslee/');        
    else    %if net_prefix is B2*
        jobcfg{cidx_netname,2} = sprintf('%s', 'Net64');
        jobcfg{cidx_fov,2} = sprintf('%d,%d,%d', 89,89,7);
        jobcfg{cidx_fwd_path, 2} = sprintf('%s', '/data/lrrtm3_wt_affin/Net64/');
    end
    jobcfg{cidx_omni_net, 2} = sprintf('%s', net_prefix);
    
    
    [chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(jobcfg); 

    [cube, valid] = get_affinity_cube_(jobcfg, 1, chan_coordinate_tbl, fwd_coordinate_tbl);
    if ~valid 
        print_(sprintf('@ERROR: load affinity volume(%d_%d_%d) failed.', idx), 1);
        return
    end
    
    [r,c,s,~] = size(cube);
    x_affinity = cube(:,2:end,:,1);
    y_affinity = cube(2:end,:,:,2);
    z_affinity = cube(:,:,2:end,3);
    x_affinity = cat(2, x_affinity, zeros(r,1,s));
    y_affinity = cat(1, y_affinity, zeros(1,c,s));
    z_affinity = cat(3, z_affinity, zeros(r,c,1));
end

function print_(sentence, iserror)
    user = account();
    if ~isempty(user)
        write_log(sentence, iserror);
    else
        fprintf('%s\n', sentence);
    end
end

function [cube, valid] = get_affinity_cube_(cfg, ridx, chan_tbl, fwd_tbl)
    cube = zeros([chan_tbl{ridx,4} 3], 'single');    
    
    valid = 1;
    %get cfg info
    [path,~] = get_cfg(cfg, 'fwd_result_path');
    [fwd_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    [net_prefix,~] = get_cfg(cfg, 'omni_net_prefix');
    
    chan_fr = chan_tbl{ridx,2};
    chan_to = chan_tbl{ridx,3};
    fname_suffix = '_affinity.h5';
    if ~strncmpi(net_prefix, 'C1', 2)
        fname_suffix = '_output.h5';
    end
  
    x = chan_fr(1);
    while 1
        y = chan_fr(2);
        while 1
            z = chan_fr(3);
            while 1     
                fridx = get_fwd_ridx_by_startpoint(fwd_tbl, [x,y,z]);
                if fridx < 1 
                    print_('@ERROR: get_affinity_cube, match cube not exist', 1);
                    valid = 0;
                    return
                end
                fwd_filename = sprintf(fwd_naming, fwd_tbl{fridx,1});
                fwd_outname = [path fwd_filename fname_suffix]; 
                
                %check existence of affinity file
                if exist(fwd_outname, 'file') < 1
                    print_(sprintf('@ERROR: affinity file not exist (fwd cube id:%d_%d_%d)', fwd_tbl{fridx,1}), 1);
                    valid = 0;
                    return
                end
                
                cube = reassemble_cube(cube, fwd_tbl, fridx, chan_fr, chan_to, [x,y,z], fwd_outname);
                en = min(chan_to, fwd_tbl{fridx,5});
                z = en(3)+1;
                if z >= chan_to(3) 
                    break
                end            
            end %third while
            y = en(2)+1;
            if y >= chan_to(2)
                break
            end        
        end %second while
        x = en(1)+1;
        if x >= chan_to(1)
            break
        end    
    end %first while
end