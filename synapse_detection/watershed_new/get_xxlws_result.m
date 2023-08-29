function [seg, dend, dendv] = get_xxlws_result(input_size, xxlws_job_path, width)

seg = zeros( input_size(1:3), 'uint32' );
    
    x_idx = 0;
    for x=1:width:input_size(1)
        y_idx = 0;
        for y=1:width:input_size(2)
            z_idx = 0;
            for z=1:width:input_size(3)
                end_point = min([x,y,z]+width, input_size(1:3));
                start_point = max([1,1,1], [x,y,z]-1);
                
                fname = sprintf('%s.chunks/%d/%d/%d/.seg', xxlws_job_path, x_idx, y_idx, z_idx);
                fid = fopen(fname, 'r');
                
                chunk_size = end_point-start_point+1;
                try
                    chunk = reshape( fread(fid, prod(chunk_size), 'int32'), chunk_size );
                catch 
                    warning('Problem in file reading?');
                    fprintf('%d %d %d', x, y, z);
                end
                chunk = chunk(2:end-1, 2:end-1, 2:end-1);
                seg( start_point(1)+1:end_point(1)-1, start_point(2)+1:end_point(2)-1, start_point(3)+1:end_point(3)-1 ) = chunk;
                fclose(fid);
                fprintf('x_%dy_%dz_%d \n', x_idx, y_idx, z_idx);
                
                z_idx = z_idx+1;
            end
            y_idx = y_idx+1;
        end
        x_idx = x_idx+1;
    end
    
    fid = fopen([xxlws_job_path '.dend_values'], 'r');
    dendv = single( fread(fid, 1000000000, 'float') );
    fclose(fid);
    
    fid = fopen([xxlws_job_path '.dend_pairs'], 'r');
    dend = zeros(2, size(dendv,1));
    dend(:) = fread(fid, size(dendv)*2, 'uint32');
    dend = uint32(dend');
    fclose(fid);
    