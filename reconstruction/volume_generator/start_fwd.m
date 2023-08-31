function [sts_table,fwd_joblist] = start_fwd(cfg, sts_table, sts_ridx, fwd_joblist, fwd_ridx)
    %get fwd cfg info
    fwd_node_info = get_fwd_node_info(cfg);
    [nnode,~] = size(fwd_node_info);
    flag_find_node_info = 0;
    for node_idx=1:nnode
        if strcmpi(fwd_node_info{node_idx,1}, sts_table{sts_ridx,1}) == 1
            node = fwd_node_info{node_idx,1};
            node_user = fwd_node_info{node_idx,2};
            node_pw = fwd_node_info{node_idx,3};
            flag_find_node_info = 1;
            break
        end
    end
    if flag_find_node_info ~= 1
        disp(['@can not find login info (' sts_table{sts_ridx,1} ')']);
        return
    end
    
    [default_path,~] = get_cfg(cfg, 'job_default_path');
    [netname,~] = get_cfg(cfg, 'netname');
    
%     kaffe_path = '/data/research/jwgim/cnn_pkg/kaffe/python/'; %for old unet
    kaffe_path = '/data/research/jwgim/cnn_pkg/kaffe_new_cfg/python/'; % for RS unet
    fwdcfg_path = sprintf('%s%s%sx%dy%dz%d%s', default_path, netname, '/cfg_', fwd_joblist{fwd_ridx,1}, '.cfg');
%     fwdsc_path = [kaffe_path 'forward.py'];   %for old unet
    fwdsc_path = [kaffe_path 'infer.py'];   %for RS unet
    fwdlog_path = sprintf('%s%s%sx%dy%dz%d%s', default_path, 'fwd_log/', netname, fwd_joblist{fwd_ridx,1}, '_log');
    fwdscript_path = sprintf('%s%s%sx%dy%dz%d%s', default_path, netname, '/execute_', fwd_joblist{fwd_ridx,1}, '.sh');
    
    host_id = str2num( node(end-2:end) );
    gpu_id = cvt_deviceid_driver2cuda(host_id, sts_table{sts_ridx,2});   %using cuda id for fwd
    switch(host_id)     %shell script file write
        case 101
            fid = fopen(fwdscript_path, 'w'); %for sv101
            fprintf(fid, '#! /bin/bash\n');
            fprintf(fid, 'export PATH=$PATH:/usr/local/cuda-7.5/bin\n');
            fprintf(fid, 'export LD_LIBRARY_PATH=/usr/local/cuda-7.5/lib64\n');
            fprintf(fid, 'export PATH=$PATH:/data/research/jwgim/cnn_pkg/sl_caffe/caffe/build/tools:/data/research/jwgim/cnn_pkg/sl_caffe/caffe/python\n');
            %for old unet
%             fprintf(fid, 'export PYTHONPATH=/data/research/jwgim/cnn_pkg/sl_caffe/caffe/python:/data/research/jwgim/cnn_pkg/kaffe:/data/research/jwgim/cnn_pkg/kaffe/layers\n');
            %for RS unet
            fprintf(fid, 'export PYTHONPATH=/data/research/jwgim/cnn_pkg/sl_caffe/caffe/python:/data/research/jwgim/cnn_pkg/kaffe_new_cfg:/data/research/jwgim/cnn_pkg/kaffe_new_cfg/layers\n');
            fprintf(fid, ['python ' fwdsc_path ' ' num2str(gpu_id) ' ' fwdcfg_path '>' fwdlog_path ' 2>&1 &disown\n']);
            fclose(fid); 
        otherwise
            fid = fopen(fwdscript_path, 'w');   %for sv102, sv103
            fprintf(fid, '#! /bin/bash\n');
            fprintf(fid, 'export PATH=$PATH:/usr/local/cuda-8.0/bin\n');
            fprintf(fid, 'export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64\n');
            fprintf(fid, 'export PATH=$PATH:/usr/local/caffe_opencl/caffe/build/tools:/usr/local/caffe_opencl/caffe/python\n');
            %for old unet
%             fprintf(fid, 'export PYTHONPATH=/usr/local/caffe_opencl/caffe/python:/data/research/jwgim/cnn_pkg/kaffe:/data/research/jwgim/cnn_pkg/kaffe/layers\n');
            fprintf(fid, 'export PYTHONPATH=/usr/local/caffe_opencl/caffe/python:/data/research/jwgim/cnn_pkg/kaffe_new_cfg:/data/research/jwgim/cnn_pkg/kaffe_new_cfg/layers\n');            
            %for RS unet
            fprintf(fid, ['python ' fwdsc_path ' ' num2str(gpu_id) ' ' fwdcfg_path '>' fwdlog_path ' 2>&1 &disown\n']);
            fclose(fid);
    end
            
    cmd = ['chmod ug+x ' fwdscript_path];
    system(cmd);
    
    connect_cmd = ['sshpass -p ' node_pw ' ssh -o StrictHostKeyChecking=no ' node_user '@' node];
    node_cmd = fwdscript_path;
    [~,~] = system([connect_cmd ' ' node_cmd]);
    
    %update job list and status table
    fwd_joblist{fwd_ridx,4} = 'FWD';
    sts_table{sts_ridx,3} = fwd_joblist{fwd_ridx,1};
    sts_table{sts_ridx,4} = fwd_ridx;
    sts_table{sts_ridx,5} = 'RUN';
    sts_table{sts_ridx,6} = datetime('now');
    
    disp(['fwd_jobidx: ' num2str(fwd_ridx) ' FWD start (gpu: ' num2str(cvt_deviceid_cuda2driver(host_id, gpu_id)) ')']);
    pause(10);
