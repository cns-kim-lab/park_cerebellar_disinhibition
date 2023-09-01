% function cut_interneuron_cellbody (inputh5File, interneuronInfoFile)
function cut_interneuron_cellbody_by_bbox (inputh5File,interneuronInfoFile,mip_level,scaling_factor)
    
    %%  read bbox info
    interneuronInfoFilePath = sprintf('%s',interneuronInfoFile);
    fileID = fopen(interneuronInfoFilePath, 'r');
    data = textscan(fileID, '%d %d %f %f %f %f %f %f');
    
    omni_id = data{1};
    x_lower = double(data{2});
    x_upper = double(data{3});
    y_lower = double(data{4});
    y_upper = double(data{5});
    z_lower = double(data{6});
    z_upper = double(data{7});

    fclose(fileID);
    
    %% set parameters and paths
    h5Dir = '/data/lrrtm3_wt_reconstruction';
    inputh5FilePath = sprintf('%s/%s.h5',h5Dir,inputh5File);
    outputh5File = sprintf('%s.int_cb_cut', inputh5File);
    outputh5FilePath = sprintf('%s/%s.h5', h5Dir, outputh5File);
    mip_factor = 2^mip_level;
    size_of_chunk = [128 128 128];

    %% prepare h5 file
    dims = h5info(inputh5FilePath,'/main').Dataspace.Size;
    out_vol_mip_size = dims;
    out_vol_mip_size_in_chunk = ceil(out_vol_mip_size./size_of_chunk);
%     out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;
    prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, size_of_chunk, inputh5FilePath, outputh5FilePath);

    %% remove cellbodies
    for c=1:numel(omni_id)
        fprintf('Removing the cellbody of the interneuron %d\n',omni_id(c));
        st = max(round([x_lower(c) y_lower(c) z_lower(c)]./(mip_factor./scaling_factor)), [1 1 1]);
        ed = min(round([x_upper(c) y_upper(c) z_upper(c)]./(mip_factor./scaling_factor)), dims);

        chunk = uint32(h5read(outputh5FilePath, '/main', st, ed-st+1));
        chunk(chunk==omni_id(c)*100) = omni_id(c)*100 + 1;
        h5write(outputh5FilePath, '/main', uint32(chunk),st, ed-st+1);
    end

    fprintf('Done.\n');

end

function prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, size_of_chunk, inputh5FilePath, seg_hdf5_file_name)

    
    out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;
    
    h5create(seg_hdf5_file_name,'/main',out_vol_mip_size,'ChunkSize',size_of_chunk,'Datatype','uint32');
    
    for x = 1:out_vol_mip_size_in_chunk(1)
       for y = 1:out_vol_mip_size_in_chunk(2)
           for z = 1:out_vol_mip_size_in_chunk(3)
               st=([x y z]-1).*size_of_chunk+1;
               ed=[x y z].*size_of_chunk;
               chunk = uint32(h5read(inputh5FilePath,'/main',st,ed-st+1));
               fprintf('filling up [%d %d %d]\n',x,y,z);
               h5write(seg_hdf5_file_name,'/main',uint32(chunk),st,ed-st+1); 
           end
       end
    end    
    
end
