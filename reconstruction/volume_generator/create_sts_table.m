function sts_table =  create_sts_table(cfg)
    fwd_node_info = get_fwd_node_info(cfg);
    [nnode,~] = size(fwd_node_info);    
    ngpu = 0;
    
    %node, gpuid, jobid, joblist_ridx, status, starttime
    sts_table = cell(0,6);
    for idx=1:nnode
        fwd_node = fwd_node_info{idx,1};
        fwd_node_user = fwd_node_info{idx,2};
        fwd_node_pw = fwd_node_info{idx,3};
        
        node_cmd = 'nvidia-smi -L';
        connect_cmd = ['sshpass -p ' fwd_node_pw ' ssh -o StrictHostKeyChecking=no ' fwd_node_user '@' fwd_node];
        [~, cmdout] = system([connect_cmd ' ' node_cmd]);

        %split by enter
        by_line = strsplit(cmdout, '\n');
        if isempty(by_line{end})
            by_line = by_line(1:end-1);
        end
        [row,~] = size(by_line.');
        len = row;
        gpu_list = by_line(3:end);
        temp_cell = cell(len-2, 6);
        for gpuidx=1:len-2
            temp_cell{gpuidx,1} = fwd_node;
            gpu_ = strsplit(gpu_list{gpuidx}, ':');
            id_str = strsplit(gpu_{1}, ' ');
            gpu_id = str2num(id_str{2});    %driver-id
            temp_cell{gpuidx,2} = gpu_id;
            temp_cell{gpuidx,3} = [0,0,0];
            temp_cell{gpuidx,4} = 0;
            temp_cell{gpuidx,5} = get_node_gpu_status(fwd_node, fwd_node_user, fwd_node_pw, gpu_id);
            temp_cell{gpuidx,6} = datetime('now');            
        end
        sts_table(ngpu+1:ngpu+(len-2),:) = temp_cell(:,:);
        ngpu = ngpu + (len-2);
    end
   