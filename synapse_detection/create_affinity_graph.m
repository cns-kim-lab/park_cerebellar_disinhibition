function create_affinity_graph(fwd_assembly_path, affinity_path)
    
    h5create(affinity_path, '/main', [inf inf inf 3], 'Datatype','single','ChunkSize', [256,256,256,3]);
    
    jobconfig_path = '/data/research/kaffeuser/lrrtm3_syn_detection/cfg_vesicle.txt';
    jobcfg = parsing_jobconfig(jobconfig_path);
    [~, fwd_tbl] = create_coordinate_table(jobcfg);
    [row, ~] = size(fwd_tbl);
    for ridx = 1:row
        tic;
        stp = fwd_tbl{ridx,4};
        enp = fwd_tbl{ridx,5};
        num_elem = enp - stp + 1;
        fwd_vol = h5read(fwd_assembly_path, '/main', stp, num_elem); 
        
        affinity = zeros([size(fwd_vol) 3], 'single');
        affinity(:,:,:,1) = fwd_vol;
        affinity(:,:,:,2) = fwd_vol;
        affinity(:,:,:,3) = fwd_vol;
        
        stp2 = [stp 1];
        num_elem2 = [num_elem 3];
        
        h5write(affinity_path, '/main', affinity, stp2, num_elem2);
        toc;
        fprintf('%d\n', ridx);
    end    
end