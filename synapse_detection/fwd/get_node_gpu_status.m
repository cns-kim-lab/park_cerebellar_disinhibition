%gpu_id is driver id (nvidia-smi)
function status = get_node_gpu_status(fwd_node, fwd_node_user, fwd_node_pw, gpu_id) 

   % host_id = str2num(fwd_node(end-2:end));
    
   % connect_cmd = ['sshpass -p ' fwd_node_pw ' ssh -o StrictHostKeyChecking=no ' fwd_node_user '@' fwd_node];
   % node_cmd = ['nvidia-smi pmon -i ' num2str(gpu_id) ' -c 1'];
   % [~,cmdout] = system([connect_cmd ' ' node_cmd]);
  %  by_line = strsplit(cmdout, '\n');
  %  lastline = strsplit( by_line{end-1}, ' ' );
  %  pid = str2double( lastline{3} );

  node_cmd = 'nvidia-smi -q -d Memory |grep -A4 GPU|grep Free ';
  [~,cmdout] = system(node_cmd);
  line = strsplit(cmdout, ' ');
  memory_avail = str2double(line{4});
  
  
    if memory_avail > 8000   % (MiB) ~= idle gpu
        status = 'IDLE';    
        %disp(['kimserver' num2str(host_id) ', gpu ' num2str(gpu_id) ':' status ]);
        disp(['kimworkstation02 gpu 0: ' status '      available memory (MiB):   ' line{4}])
        return 
    else
        status = 'RUN';
        disp(['kimworkstation02 gpu 0: ' status '      available memory (MiB):   ' line{4}])

       % disp(['kimserver' num2str(host_id) ', gpu ' num2str(gpu_id) ':' status ]);
        return
    end

    