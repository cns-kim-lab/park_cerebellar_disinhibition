%standardize h5 file, and save
%mode: 2d=each slice, 3d=whole cube
function standardize(path, mode, savename)
    if ~isdeployed
        addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
    end
    mode = lower(mode);
    
    data_loc = '/main';
    [numdims, dims, ~] = get_hdf5_size(path, data_loc);
    
    %exception
    if numdims > 3 
        disp('@not supported dimension');
        return
    end
    
    if isequal(mode, '3d') 
        disp('standardize whole cube, this could takes long time.');
        data = hdf5read(path, data_loc);
        ret = standardize_data(data);
        h5create(savename, data_loc, dims);
        h5write(savename, data_loc, ret);
    elseif isequal(mode, '2d') 
       if numdims == 3 
           h5create(savename, data_loc, dims);
           for slice=1:dims(end)
               data = get_hdf5_file(path, data_loc, [1 1 slice], [dims(1) dims(2) slice]);
               ret = standardize_data(data);
               h5write(savename, data_loc, ret, [1 1 slice], [dims(1) dims(2) 1]);
               disp(['slice: ' num2str(slice) '/' num2str(dims(end))]);
           end
       elseif numdims < 3
            data = hdf5read(path, data_loc);
            ret = standardize_data(data);
            h5create(savename, data_loc, dims);
            h5write(savename, data_loc, ret);
       end
    else
        disp('@not supported mode');
        return
    end
