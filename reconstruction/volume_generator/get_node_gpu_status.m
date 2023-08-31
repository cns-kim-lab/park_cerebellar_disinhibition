%gpu_id is driver id (nvidia-smi)
function status = get_node_gpu_status(fwd_node, fwd_node_user, fwd_node_pw, gpu_id) 
    host_id = str2num(fwd_node(end-2:end));
    
    connect_cmd = ['sshpass -p ' fwd_node_pw ' ssh -o StrictHostKeyChecking=no ' fwd_node_user '@' fwd_node];
    node_cmd = ['nvidia-smi pmon -i ' num2str(gpu_id) ' -c 1'];
    [~,cmdout] = system([connect_cmd ' ' node_cmd]);
    by_line = strsplit(cmdout, '\n');
    lastline = strsplit( by_line{end-1}, ' ' );
    pid = str2double( lastline{3} );

    if isnan(pid)   %idle gpu
        status = 'IDLE';
        disp(['kimserver' num2str(host_id) ', gpu ' num2str(gpu_id) ':' status ]);
        return 
    else
        status = 'RUN';
        disp(['kimserver' num2str(host_id) ', gpu ' num2str(gpu_id) ':' status ]);
        return
    end
        