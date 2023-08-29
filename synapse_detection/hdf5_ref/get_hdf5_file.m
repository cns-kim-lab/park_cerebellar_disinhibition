function [block] = get_hdf5_file(file, path, start_coords, end_coords)

if (isempty(path))
  path='/main';
end

dataID      = H5F.open(file,'H5F_ACC_RDONLY','H5P_DEFAULT');
datasetID   = H5D.open(dataID,path);
dataspaceID = H5D.get_space(datasetID);

block=get_hdf5(datasetID, dataspaceID, start_coords, end_coords);

H5D.close(datasetID);
H5F.close(dataID);
