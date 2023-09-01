function []=write_hdf5(datasetID, dataspaceID, start_coords, end_coords, block)

% HDF5 stores things in opposite indexing order
start_coords=flipdims(start_coords);
end_coords=flipdims(end_coords);

start_slab=start_coords-1;
count=end_coords-start_coords+1;
type=H5D.get_type(datasetID);
H5S.select_hyperslab(dataspaceID,'H5S_SELECT_SET',start_slab,ones(length(start_coords),1), count,ones(length(start_coords),1));
output_dataspace=H5S.create_simple(length(start_coords), count, count);
H5D.write(datasetID,'H5ML_DEFAULT',output_dataspace,dataspaceID,'H5P_DEFAULT', block);
