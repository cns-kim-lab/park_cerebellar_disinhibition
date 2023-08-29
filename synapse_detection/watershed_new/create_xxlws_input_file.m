function input_size = create_xxlws_input_file(input, input_type, width, xxlws_job_path)
%     addpath '/data/research/jwgim/matlab_code/hdf5_ref/';
    
    if strcmpi( input_type, 'file' )
        [~,input_size,~] = get_hdf5_size(input, '/main');
        limit_ = 300*1024*1024/4;   %load limit: 300MB
        
        %if input file is too big, do not load whole data
        if prod(input_size(:)) > limit_   
            input_size = xxlws_prepare_from_h5(input, xxlws_job_path, width);
            return
        else
            input_size = xxlws_prepare_from_h5(input, xxlws_job_path, width);
        end
    elseif strcmpi( input_type, 'matrix')
        input_size = xxlws_prepare_from_matrix(input, xxlws_job_path, width);
    end
    