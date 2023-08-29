% During the process of interface assembling, some interface IDs are
% dropped and left unused.
% This code reassigns interface id of a given volume starting from 1, increasing incrementally.
% e.g.  input id: {1 2 4 7 8 10 15 16}  mapped to id: { 1 2 3 4 5 6 7 8}
% You must run this code before classifying interfaces.

function reassign_interface_id(assembly_path, write_path)
addpath /data/research/cjpark147/code/hdf5_ref

%write_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_reassigned_210503.h5';
[~,assembly_size,~] = get_hdf5_size(assembly_path, '/main');
id_list = [];
ChunkSize = [512, 512, 128];
h5create(write_path, '/main', assembly_size, 'Datatype', 'uint32', 'ChunkSize', ChunkSize);

subvol_size = [1024, 1024, 256];
minp = [1,1,1];
maxp = [14592, 10240, 1024];
last_cubeidx = [15,10,4];

tic;

for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + [1,1,1]);
            enp = min(maxp, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            subvol = h5read(assembly_path, '/main', stp, num_elem);
            id_list = [id_list; unique(subvol)];
            fprintf('%d, %d, %d\n', x,y,z);
            
        end
    end
end

save('/data/lrrtm3_wt_syn/assembly/id_list.mat', 'id_list');


clear subvol
id_list = unique(id_list);
id_list(id_list==0) = [];
max_id = max(id_list);

map = zeros(max_id+1,1);
new_id = [1:numel(id_list)]';
map(id_list) = new_id;
map = [0; map];

for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + [1,1,1]);
            enp = min(maxp, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            vol = h5read(assembly_path, '/main', stp, num_elem);
            vol = map(vol+1);
            h5write(write_path, '/main', uint32(vol), stp, num_elem);
            fprintf('%d, %d, %d\n', x, y, z);
        end
    end
end


toc;