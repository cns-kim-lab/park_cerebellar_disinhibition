function input_size = xxlws_prepare_from_h5(input_path, savename, width)
    [~,input_size,~] = get_hdf5_size(input_path, '/main');
    
    fid_chuncksize = fopen([savename '.chunksizes'], 'w+');
    fid_affinityData = fopen([savename '.affinity.data'], 'w+');
    dirname = [savename '.chunks'];
    [~,~,~] = mkdir( dirname );
    
    x_idx = 0;
    for x=1:width:input_size(1)
        [~,~,~] = mkdir( sprintf('%s/%d', dirname, x_idx) );
        y_idx = 0;
        for y=1:width:input_size(2)
            [~,~,~] = mkdir( sprintf('%s/%d/%d', dirname, x_idx, y_idx) );
            z_idx = 0;
            for z=1:width:input_size(3)
                [~,~,~] = mkdir( sprintf('%s/%d/%d/%d', dirname, x_idx, y_idx, z_idx) );
                
                end_point = min([x,y,z] + width, input_size(1:3));
                start_point = max([1,1,1], [x,y,z]-1);
                
                fwrite(fid_chuncksize, end_point-start_point+1, 'int32');
                partial_data = get_hdf5_file(input_path, '/main', [start_point, 1], [end_point, 3]);
                fwrite(fid_affinityData, single(partial_data), 'float');
                
                z_idx = z_idx +1;
            end
            y_idx = y_idx +1;
        end
        x_idx = x_idx +1;
    end
    
    metax = [32, 32, x_idx, y_idx, z_idx];
    fid_meta = fopen([savename '.metadata'], 'w+');
    fwrite(fid_meta, metax, 'int32');
    
    fclose(fid_meta);
    fclose(fid_chuncksize);
    fclose(fid_affinityData);
       