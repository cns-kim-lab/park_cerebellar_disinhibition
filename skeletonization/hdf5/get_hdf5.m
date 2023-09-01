function [block]=get_hdf5(datasetID, dataspaceID, start_coords, end_coords)

% HDF5 stores things in opposite indexing order
start_coords=flipdims(start_coords);
end_coords=flipdims(end_coords);


% HDF5 indexing conventions
start_slab=start_coords-1;
count=end_coords-start_coords+1;

% select region of dataspace to read
H5S.select_hyperslab(dataspaceID,'H5S_SELECT_SET',start_slab,ones(length(start_coords),1), count,ones(length(start_coords),1));
% dataspace to read into
output_dataspace=H5S.create_simple(length(start_coords),count, count);
% read it
block=H5D.read(datasetID,'H5ML_DEFAULT',output_dataspace,dataspaceID,'H5P_DEFAULT');
