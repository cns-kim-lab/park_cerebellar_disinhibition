%affinity to segment
%<param>    1: input data (file path or matrix)
%           2: input data type ('file' or other)
%           3: result(watershed) save path, 4: result save flag (1 or other)
%           5: watershed threshold, 6: chunk width
%           7: number of thread for watershed
function [segu, dendu, dendv] = aff2seg(input, input_type, savename, saveflag, threshold, watershed_width, nthread)
    tic
if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/hdf5_ref/');   
    addpath('/data/research/jwgim/matlab_code/watershed_ref/');   %for makeUnique
end
    path_xxlws_exe='/data/research/jwgim/matlab_code/watershed_ref/xxlws';
    
    %exception handling
    nthread = max(1, nthread);
    watershed_width = max(128, watershed_width);
%     if nthread < 1
%         nthread = 1;
%     end
%     if watershed_width < 128 
%         watershed_width = 128;
%     end
    
    xxlws_job_path = 'tempfiles_xxlws';
    %default : dust 100, dust_low 0.30, low 0.3
%     wsparam = [' --high ' num2str(threshold) ' --dust 100 --dust_low 0.00 --low 0.0 --threads ' num2str(nthread)];
    wsparam = [' --high ' num2str(threshold) ' --dust 100 --dust_low 0.30 --low 0.3 --threads ' num2str(nthread)];
    cmd = [path_xxlws_exe ' --filename ' xxlws_job_path wsparam];
    
    %write input file of xxlws(watershed program)
    input_size = create_xxlws_input_file(input, input_type, watershed_width, xxlws_job_path);
    system(cmd);    %execute xxlws
    %read result of xxlws
    [seg, dend, dendv] = get_xxlws_result(input_size, xxlws_job_path, watershed_width);
    [segu, dendu] = makeUnique(uint32(seg), uint32(dend));
    
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
    toc
    