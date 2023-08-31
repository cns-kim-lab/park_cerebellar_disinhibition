function [sts_table, fwd_joblist, exist_done] = check_finished_fwd(sts_table, fwd_joblist, cfg)
    exist_done = 0; %no available gpu (on node)
    [row,~] = size(sts_table);
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [netname,~] = get_cfg(cfg, 'netname');
    fwd_node_info = get_fwd_node_info(cfg);
    [nnode,~] = size(fwd_node_info);
    
    disp('check gpu status');
    
    %check only currently 'RUN' state in sts_stable
    for iter=1:row
        %skip not running (in sts_table)
        if strcmpi( sts_table{iter,5}, 'RUN' ) == 0
            continue
        end
        
        host_name = sts_table{iter,1};
        flag_find_node = 0;
        for node_idx=1:nnode
            if strcmpi(fwd_node_info{node_idx,1}, host_name) == 1
                fwd_node_user = fwd_node_info{node_idx,2};
                fwd_node_pw = fwd_node_info{node_idx,3};
                flag_find_node = 1;
                break
            end
        end
        if flag_find_node ~= 1
            disp(['@can not find login info (' host_name ')']);
            return
        end
        
        host_id = str2num(host_name(end-2:end));
        gpuid =  sts_table{iter,2}; %driver id
        host_sts = get_node_gpu_status(host_name, fwd_node_user, fwd_node_pw, gpuid);


        %'RUN' -> 'IDLE' gpu
        if strcmpi(host_sts, 'IDLE') == 1
            %check fwd_idx (for incase of different process)
            fwd_tbl_id = sts_table{iter,4};
            if fwd_tbl_id < 1
                disp(['new IDLE gpu found. host=' host_name ', gpuid=' num2str(gpuid)]);
                sts_table{iter,3} = 0;  %jobid 
                sts_table{iter,4} = 0;  %joblist_ridx
                sts_table{iter,5} = 'IDLE'; %sts
                exist_done = 1;
                return
            end           
            
            disp(['fwd_jobidx: ' num2str(fwd_tbl_id) ' FWD done']);
            %previous job cleanup
            cfgfile = sprintf('%s%s%sx%dy%dz%d%s', default_path, netname, '/cfg_', sts_table{iter,3}, '.cfg');
            shfile = sprintf('%s%s%sx%dy%dz%d%s', default_path, netname, '/execute_', sts_table{iter,3}, '.sh');
            %delete config & shell script file 
            cmd = ['rm -rf ' cfgfile];
            system(cmd);
            cmd = ['rm -rf ' shfile];
            system(cmd);
            %update sts_table, joblist
            fwd_joblist{fwd_tbl_id,4} = 'DONE';
            fwd_joblist{fwd_tbl_id,6} = datetime('now');
            
            sts_table{iter,3} = 0;  %jobid
            sts_table{iter,4} = 0;  %joblist_ridx
            sts_table{iter,5} = 'IDLE'; %sts
            exist_done = 1;
        end
    end
