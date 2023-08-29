function [segu, dendu, dendv] = aff2seg_detail(input, input_type, savename, saveflag, param_set)
%if ~isdeployed
    addpath('/data/research/cjpark147/code/hdf5_ref/');   
    addpath('/data/research/cjpark147/code/watershed_ref/');   %for makeUnique
%end
     path_xxlws_exe='/data/research/cjpark147/code/watershed_ref/xxlws';
%    path_xxlws_exe='/data/research/jwgim/matlab_code/watershed_ref/xxlws_mean_all';
    
    high = getfield(param_set, 'high');
    low = getfield(param_set, 'low');
    dust = getfield(param_set, 'dust');
    dust_low = getfield(param_set, 'dust_low');
    nthread = getfield(param_set, 'threads');
    width = getfield(param_set, 'width');
    
    %exception handling
    nthread = max(1, nthread);
    width = max(128, width);
    
    xxlws_job_path = 'tempfiles_xxlws';
    wsparam = [' --high ' num2str(high) ' --dust ' num2str(dust) ' --dust_low ' num2str(dust_low) ' --low ' num2str(low) ' --threads ' num2str(nthread)];
    cmd = [path_xxlws_exe ' --filename ' xxlws_job_path wsparam];
    
    %write input file of xxlws(watershed program)
    
    input_size = create_xxlws_input_file(input, input_type, width, xxlws_job_path);
    system(cmd);    %execute xxlws
    %read result of xxlws
    [seg, dend, dendv] = get_xxlws_result(input_size, xxlws_job_path, width);
    [segu, dendu] = makeUnique(seg, uint32(dend));
    
    % cjpark
    % If the input size is too large
    if prod(input_size) > 14592*10240*1024/6    % > 100 GB
        clear seg;
        h5create('./xxlws_segu.h5', '/main', input_size, 'Datatype', 'int32', 'ChunkSize', [512,512,128]);
        h5write('./xxlws_segu.h5', '/main', segu);
        h5create('./xxlws_segu_uint32.h5', '/main', input_size, 'Datatype', 'uint32', 'ChunkSize', ChunkSize);
        block_size = [2048, 2048, 512];
        % convert type.
        for x = 1:block_size(1):input_size(1)
            for y = 1:block_size(2):input_size(2)
                for z = 1:block_size(3):input_size(3)
                    stp = max([1,1,1], [x,y,z]);
                    enp = min(input_size, [x,y,z] + block_size - 1);
                    num_elem = enp - stp + [1,1,1];
                    v = h5read(input_path, '/main', stp, num_elem);
                    h5write(output_path, '/main', uint32(v), stp, num_elem);
                end
            end
        end        
        segu = h5read('./xxlws_segu_uint32.h5', '/main');
    end
        
    %remove temp files
    cmd = ['rm -rf ./' xxlws_job_path '*'];
    system(cmd);
        
    %save
    if saveflag 
        if isempty(savename)
            savename = './watershed_result.h5';
        end    
        save_watershed(savename, segu, dendu, dendv);
    end
end
