function create_batch_script(cfg, core_list, chan_tbl, cfg_path)
    [omni_create_path,~] = get_cfg(cfg, 'omni_create_path');
    
    sidx = find(cfg_path=='/', 1, 'last');
    eidx = find(cfg_path=='.', 1, 'last');
    cfg_phasenum = str2num(cfg_path(sidx+10:eidx-1));    
    
    unit_core = int32(core_list ./ min(core_list));
    [row,~] = size(chan_tbl);
    num_job = row;
    for ridx = 1:row
        if strcmpi(chan_tbl{ridx,5}, 'DONE') == 1
            num_job = num_job-1;
        end
    end
    
    %omnification using only 1 node
    if int32(num_job/sum(unit_core)) < 2 
        fr = 1;
        to = num_job;
        
        fname = sprintf('%sCfg%d_makebatch1.sh',omni_create_path, cfg_phasenum);
        write_batch_script(fname, fr, to, chan_tbl, omni_create_path);
        return
    end
    
    %omnification using multiple node
    num_node = length(core_list);
    to = 0;
    for node_iter = 1:num_node
        fr = to+1;
        to = fr +int32(num_job / sum(unit_core)) *unit_core(node_iter) -1;
        if node_iter == num_node
            to = num_job;
        end
        if fr >= to
            disp('no job left');
            continue
        end
        
        fname = sprintf('%sCfg%d_makebatch%d.sh',omni_create_path, cfg_phasenum, node_iter);
        write_batch_script(fname, fr, to, chan_tbl, omni_create_path);
    end
    
    
function write_batch_script(fname, fr, to, chan_tbl, omni_create_path)
    fid = fopen(fname, 'w');
    fprintf(fid, '#! /bin/bash\n');
    for idx=fr:to
        cube_idx = chan_tbl{idx,1};
        fprintf(fid, '%smake_x%dy%dz%d.sh\n', omni_create_path, cube_idx);
        fprintf(fid, 'rm -rf %smake_x%dy%dz%d.sh\n', omni_create_path, cube_idx);
    end
    fprintf(fid, 'echo ''all job done''\n');
    fclose(fid);
    cmd = ['chmod ug+wx ' fname];
    system(cmd);
    return
    