function [] = write_hdf5_file(file, path, start_coords, end_coords, block)

if(isempty(path))
  path='/main';
end

dataID=H5F.open(file,'H5F_ACC_RDWR','H5P_DEFAULT');
datasetID=H5D.open(dataID,path);
dataspaceID=H5D.get_space(datasetID);

% id=num2str(randsample(1e3,1));
% log_message([],['st(' id ') ' num2str(start_coords) ', ' num2str(end_coords) ', ' num2str(size(block))])
write_hdf5(datasetID, dataspaceID, start_coords, end_coords, block)

H5D.close(datasetID);
H5F.close(dataID);
