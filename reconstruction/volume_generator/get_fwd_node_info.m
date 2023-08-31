function fwd_node_info = get_fwd_node_info(cfg)
    [fwd_node,~] = get_cfg(cfg, 'fwd_node_ip');
    [fwd_node_user,~] = get_cfg(cfg, 'fwd_node_user');
    [fwd_node_pw,~] = get_cfg(cfg, 'fwd_node_password');
    
    fwd_node_list = strsplit(fwd_node, ',');
    fwd_node_list = fwd_node_list .';
    [nnode,~] = size(fwd_node_list);
    
    fwd_node_user_list = strsplit(fwd_node_user, ',');
    fwd_node_user_list = fwd_node_user_list .';
    [nuser,~] = size(fwd_node_user_list);
    
    fwd_node_pw_list = strsplit(fwd_node_pw, ',');
    fwd_node_pw_list = fwd_node_pw_list .';
    [npw,~] = size(fwd_node_pw_list);
    
    %col1: node hostname(ip), col2: node user id, col3: node user pw
    fwd_node_info = cell([nnode, 3]);
    
    for iter=1:nnode
        fwd_node_info{iter,1} = fwd_node_list{iter,1};
        
        %if nuser(npw) and nnode mismatch, copy 1st data
        if nuser < nnode    
            fwd_node_info{iter,2} = fwd_node_user_list{1,1}; 
        else
            fwd_node_info{iter,2} = fwd_node_user_list{iter,1};
        end
        
        if npw < nnode
            fwd_node_info{iter,3} = fwd_node_pw_list{1,1};
        else
            fwd_node_info{iter,3} = fwd_node_pw_list{iter,1};
        end
    end   
