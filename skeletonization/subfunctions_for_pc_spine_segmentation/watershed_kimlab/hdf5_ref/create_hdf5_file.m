function [fileID] = create_hdf5_file(file, path, total_size, chunk_size, init_size, varargin)

if(nargin>5)
  type=varargin{1};
else
  type='float';
end


if (isequal(type, 'float'))
  hdf5_type  = 'H5T_NATIVE_FLOAT';
  init_zeros = single(zeros(init_size));
elseif (isequal(type,'int'))
  hdf5_type='H5T_NATIVE_INT';
  init_zeros=int32(zeros(init_size));
elseif (isequal(type,'uint'))
  hdf5_type='H5T_NATIVE_UINT';
  init_zeros=uint32(zeros(init_size));
end

total_size = flipdims(total_size);
chunk_size = flipdims(chunk_size);
init_size  = flipdims(init_size);

if (exist(file,'file'))
    delete(file);
end

fileID = H5F.create(file, 'H5F_ACC_EXCL', 'H5P_DEFAULT', 'H5P_DEFAULT');
cparms = H5P.create('H5P_DATASET_CREATE');
H5P.set_chunk(cparms, chunk_size);

%H5P.set_deflate(cparms, 1);

dataspace = H5S.create_simple(length(total_size), init_size, -1*ones([length(total_size)',1]));
datasetID = H5D.create(fileID, path, hdf5_type, dataspace, cparms);
memspace  = H5D.get_space(datasetID);

H5D.write(datasetID, hdf5_type, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', init_zeros);
H5D.extend(datasetID, total_size);
H5P.close(cparms);
H5D.close(datasetID);
H5F.close(fileID);