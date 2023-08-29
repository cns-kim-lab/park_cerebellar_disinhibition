% Assemble boundary cubes

% Place all subvolumes you want to assemble in a single directory.
% This code assembles cubes one by one, merging segments.
% During the addition of cubes, it will find segment-collision pairs.
% A segment that intersects border N times will appear in collision
% pairs N times.
% If a collision size is above threshold for a given pair, it will join the two segments. 

function assemble_boundary_cubes(path, cube_size, overlaps, assembly_size)
addpath /data/research/cjpark147/code/hdf5_ref

default_path = '/data/lrrtm3_wt_syn/';
assembly_path = [default_path, 'assembly/assembly_boundary.h5'];
cube_files = dir([path,'*.h5']);
nfiles = numel(cube_files);
minp = [1,1,1];

ChunkSize = [512,512,128];
if ~isfile(assembly_path)
    h5create(assembly_path, '/main', assembly_size, 'Datatype', 'uint32', 'ChunkSize', ChunkSize);
    h5write(assembly_path, '/main', zeros(assembly_size, 'uint32'));
end

%{
for i = 1:nfiles
    tic;
    cube_e = h5read([path, cube_files(i).name],'/main');
    cidx = regexp(cube_files(i).name,'\d*', 'Match');
    cidxx = str2double(cidx{1}); cidxy = str2double(cidx{2}); cidxz = str2double(cidx{3});
    stp = minp + (cube_size - overlaps) .* [cidxx-1, cidxy-1, cidxz-1];
    enp = min(stp + cube_size - [1,1,1], assembly_size);
    num_elem = enp - stp + [1,1,1];
    cube_s = h5read(assembly_path, '/main', stp, num_elem);       % slot cube            
    cube_e = cube_e .* uint32(cube_s == 0);
    cube_e = uint32(cube_e>0);
    h5write(assembly_path, '/main', cube_e, stp, num_elem);
    disp(['assembled ', num2str(i), ' /', num2str(nfiles), ' boundary cubes']);
    toc;
end
%}


max_id = 0;
thresh_col = 15;

for i = 1:nfiles
    cube_e = h5read([path, cube_files(i).name],'/main');
    cidx = regexp(cube_files(i).name,'\d*', 'Match');
    cidxx = str2double(cidx{1}); cidxy = str2double(cidx{2}); cidxz = str2double(cidx{3});
    stp = minp + (cube_size - overlaps) .* [cidxx-1, cidxy-1, cidxz-1];
    enp = min(stp + cube_size - [1,1,1], assembly_size);
    num_elem = enp - stp + [1,1,1];
    cube_s = h5read(assembly_path, '/main', stp, num_elem);       % slot cube    
    [cpairs, ~] = get_collision_pairs(cube_s, cube_e, thresh_col);    
         
    if numel(cpairs) == 0

        cube_e = cube_e + (max_id * uint32(cube_e~=0));
        cube_e = cube_e + (cube_s .* uint32(cube_e == 0));        % union of slot_cube and entering cube
        converted = cube_e;
        max_id = max(cube_e, [], 'all');
                
    else
 
        cpairs(:,2) = cpairs(:,2) + max_id;
        entering_ids = unique(cpairs(:,2));
        slot_ids = unique(cpairs(:,1));
        sfreq = histc(cpairs(:,1), slot_ids);
        efreq = histc(cpairs(:,2), entering_ids);        
        converted = cube_e + (max_id * uint32(cube_e~=0));
        converted = converted +(cube_s .* uint32(cube_e == 0));      % union slot_cube and entering cube        
        
        
        % 1-to-1 collision: convert an entering seg id to an existing id        
        one2one = ismember(cpairs(:,1), slot_ids(sfreq==1)) & ismember(cpairs(:,2), entering_ids(efreq==1));
        cid = cpairs(one2one, :);        
        for j = 1:numel(cid(:,1))
            converted((converted==cid(j,2))) = cid(j,1);
            cpairs(cpairs(:,2)==cid(j,2),2) = cid(j,1);     % update collision pair table
        end
    end
    h5write(assembly_path, '/main', converted, stp, num_elem);
    disp(['assembled ', num2str(i), ' /', num2str(nfiles), ' boundary cubes']); 
    
end
%}

end



% return an array containing collision pairs between "slot cube" and "entering cube". 
function [pairs, discarded] = get_collision_pairs(slot_cube, entering_cube, thresh_col)
    collision = find((slot_cube .* entering_cube));
    slot_seg = slot_cube(collision);  
    entering_seg = entering_cube(collision);
    cpairs = unique([slot_seg, entering_seg], 'rows');
    pairs = [];   discarded = [];
    for i=1:size(cpairs,1)
        id = cpairs(i,1);
        a = entering_cube(slot_cube==id);
        csize = length(find(a==cpairs(i,2)));
        if csize > thresh_col
            pairs = [pairs; cpairs(i,1), cpairs(i,2), csize];        
        else
            discarded = [discarded; cpairs(i,1), cpairs(i,2), csize];    
        end
    end
end


