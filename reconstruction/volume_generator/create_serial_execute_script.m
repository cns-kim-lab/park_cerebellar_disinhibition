function create_serial_execute_script(cfg, core_list, idxlist, name_prefix)
    [omni_create_path,~] = get_cfg(cfg, 'omni_create_path');
    
    num_job = length(idxlist);    
    unit_core = int32(core_list ./ min(core_list));
    
    if int32( num_job / sum(unit_core)) < 2
        fr = 1;
        to = num_job;

        fname = [name_prefix num2str(1) '.sh'];
        fid = fopen(fname, 'w');
        fprintf(fid, '#! /bin/bash\n');
        for idx=fr:to
            fprintf(fid, [omni_create_path 'make_%d.sh\n'], idxlist(idx));
            fprintf(fid, ['rm -rf ' omni_create_path 'make_%d.sh\n'], idxlist(idx));
        end
        fprintf(fid, 'echo ''all job done''\n');
        fclose(fid);
        cmd = ['chmod ug+wx ' fname];
        system(cmd);
        return
    end
    
    num_node = length(core_list);
    to = 0;
    for node_iter=1:num_node        
        fr = to +1;
        to = fr +int32(num_job / sum(unit_core)) *unit_core(node_iter) -1; 
        if node_iter == num_node
            to = num_job;
        end
        if fr >= to
            disp('no job left');
            continue
        end
        
%         fname = [name_prefix num2str(node_iter) '_core_' num2str(core_list(node_iter)) '.sh'];
        fname = [name_prefix num2str(node_iter) '.sh'];
        fid = fopen(fname, 'w');
        fprintf(fid, '#! /bin/bash\n');
        for idx=fr:to
            fprintf(fid, [omni_create_path 'make_%d.sh\n'], idxlist(idx));
            fprintf(fid, ['rm -rf ' omni_create_path  'make_%d.sh\n'], idxlist(idx));
        end
        fprintf(fid, 'echo ''all job done''\n');
        fclose(fid);
        cmd = ['chmod ug+wx ' fname];
        system(cmd);
    end
   