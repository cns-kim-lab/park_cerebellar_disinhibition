function [numdims dims maxdims] = get_hdf5_size(file, path)

if(isempty(path))
  path='/main';
end

% open handle to file
dataID=H5F.open(file,'H5F_ACC_RDONLY','H5P_DEFAULT');
% open handle to dataset within file
datasetID=H5D.open(dataID,path);
% open handle to dataspace
dataspaceID=H5D.get_space(datasetID);

[numdims dims maxdims]=H5S.get_simple_extent_dims(dataspaceID);

H5D.close(datasetID);
H5F.close(dataID);


dims=flipdims(dims);
maxdims=flipdims(maxdims);
