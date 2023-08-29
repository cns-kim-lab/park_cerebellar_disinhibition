% This code converts the type of a given h5 file from int32 to uint32.
% Usage example:
% The output from makeUnique.exe is of type int32. 
% We want to convert it to uint32 for omni.

input_path = '/data/lrrtm3_wt_syn/assembly/xxlws_segu.h5';
output_path = '/data/lrrtm3_wt_syn/assembly/xxlws_segu_uint32.h5';

addpath /data/research/cjpark147/code/hdf5_ref
[~, input_size, ~] = get_hdf5_size(input_path, '/main');

ChunkSize = [512, 512, 128];
h5create(output_path, '/main', input_size, 'Datatype', 'uint32', 'ChunkSize', ChunkSize);

block_size = [4096, 4096, 1024];

for x = 1:block_size(1):input_size(1)
    for y = 1:block_size(2):input_size(2)
        for z = 1:block_size(3):input_size(3)
            stp = max([1,1,1], [x,y,z]); 
            enp = min(input_size, [x,y,z] + block_size - 1);
            num_elem = enp - stp + [1,1,1];
            v = h5read(input_path, '/main', stp, num_elem);
            h5write(output_path, '/main', uint32(v), stp, num_elem);
        end
    end
end
