function assemble_ws_outputs(vol_path, savename, stp, enp, assembly_size)

addpath /data/research/cjpark147/code/hdf5_ref

assembly_path = ['/data/lrrtm3_wt_syn/assembly/assembly_', savename, '.h5'];
vol_files = dir([vol_path, '*.h5']);
nfiles = numel(vol_files);
max_id = 0;
minp = [1,1,1];
thresh_col = 0;


if isfile(assembly_path)
    fprintf('%s%s\n', assembly_path, ' file already exists');
    answer = input('you wanna overwrite the file? (true/false)');
    if answer == 1
        h5write(assembly_path, '/main', zeros(assembly_size, 'uint32'));
    else
        return;
    end
else

    h5create(assembly_path, '/main', assembly_size, 'Datatype', 'uint32');
    h5write(assembly_path, '/main', zeros(assembly_size, 'uint32'));
end
write_count = 1;


%% non-overlappers first

disp('t')
tic;
for i = 1:nfiles    
    cidx = regexp(vol_files(i).name,'\d*', 'Match');                                               % cube index
    cidxx = str2double(cidx{1}); cidxy = str2double(cidx{2}); cidxz = str2double(cidx{3}); 
    if rem(cidxx, 2) == 1 && rem(cidxy, 2) == 1 && rem(cidxz, 2) == 1
        cube_e = h5read([vol_path, vol_files(i).name], '/main');
        cube_e = cube_e + (max_id * uint32(cube_e~=0));
        max_id = max(cube_e, [], 'all');
        num_elem = enp{cidxx, cidxy} - stp{cidxx, cidxy} + [1,1,1];
        h5write(assembly_path, '/main', cube_e, stp{cidxx,cidxy}, num_elem, cube_e);
        disp(['assembled ', num2str(write_count), ' / ', num2str(nfiles), ' ws outputs']); 
        write_count = write_count + 1;
    end
end
toc;

%}

%% remainders
for i = 1:nfiles
    cidx = regexp(vol_files(i).name,'\d*', 'Match');                                               % cube index
    cidxx = str2double(cidx{1}); cidxy = str2double(cidx{2}); cidxz = str2double(cidx{3});
 
    if rem(cidxx,2) == 0 || rem(cidxy,2) == 0 || rem(cidxz,2) == 0                              % remaining cubes
        tic;
        disp('t0')
        cube_e = h5read([vol_path, vol_files(i).name], '/main');
        num_elem = enp{cidxx, cidxy} - stp{cidxx, cidxy} + [1,1,1];        
        cube_s = h5read(assembly_path, '/main', stp{cidxx,cidxy}, num_elem);
        stp_e = max(minp, stp{cidxx, cidxy} - [100,100,50]);
        enp_e = min(assembly_size, enp{cidxx, cidxy} + [100, 100, 50]);
        num_elem_e = enp_e - stp_e + [1,1,1];
        extension = h5read(assembly_path, '/main', stp_e, num_elem_e);
        toc;
        disp('t1')
        tic;
        cpairs = get_collision_pairs(cube_s, cube_e, thresh_col);
        toc;
        
        if numel(cpairs) == 0
            cube_e = cube_e + (max_id * uint32(cube_e~=0));
        else
            disp('t2')
            tic;
            cpairs(:,2) = cpairs(:,2) + double(max_id);
            entering_ids = unique(cpairs(:,2));
            slot_ids = unique(cpairs(:,1));
            sfreq = histc(cpairs(:,1), slot_ids);                                                  
            efreq = histc(cpairs(:,2), entering_ids);                                             
            cube_e = cube_e + (max_id * uint32(cube_e~=0));                                    
            cube_e = cube_e +(cube_s .* uint32(cube_e == 0));                                            
        
            one2one = ismember(cpairs(:,1), slot_ids(sfreq==1)) & ismember(cpairs(:,2), entering_ids(efreq==1));    
            cid = cpairs(one2one,:);
            for j = 1:numel(cid(:,1))
                cube_e((cube_e==cid(j,2))) = cid(j,1);
                cpairs(cpairs(:,2)==cid(j,2),2) = cid(j,1);
            end
            toc;
            
            
            disp('t3')
            tic;
            many2one = ismember(cpairs(:,2), entering_ids(efreq > 1));              
            cid = cpairs(many2one,:);
            entering_cid = unique(cid(:,2));
            for j = 1:numel(entering_cid)
                new_id = cid(find(cid(:,2) == entering_cid(j), 1), 1);
                cube_e(cube_e == entering_cid(j)) = new_id;
                N = cid(cid(:,2) == entering_cid(j), 1);                
                [grow, direction] = intf_beyond_extension(N,extension);
                if grow
                    disp('grow extension')
                    [extension, stp_e, enp_e] = grow_extension(grow, extension, direction, stp_e, enp_e, N, assembly_path, assembly_size);
                end
                
                extension(ismember(extension, N)) = new_id;
                cube_e(ismember(cube_e, N)) = new_id;
                cpairs(cpairs(:,2)==entering_cid(j),:) = new_id;
            end
            toc;
            
            
            disp('t4')
            tic;
            one2many = ismember(cpairs(:,1), slot_ids(sfreq > 1));
            cid = cpairs(one2many, :);
            slot_cid = unique(cid(:,1));
            for j = 1:numel(slot_cid)
                new_id = slot_cid(j);
                N = cid(cid(:,1) == slot_cid(j)  , 2);                 
                [grow, direction] = intf_beyond_extension(N,extension);
                if grow
                    disp('grow extension')
                    [extension, stp_e, enp_e] = grow_extension(grow, extension, direction, stp_e, enp_e, N, assembly_path, assembly_size);
                end        
        
                cube_e(ismember(cube_e, N)) = new_id;
                extension(ismember(extension, N)) = new_id;
                cpairs(cpairs(:,1) == new_id, :) = new_id;
                
            end
            toc;
        
        end
        
        disp('t5')
        tic;
        max_id = max(cube_e, [], 'all');
        stpl = minp + (stp{cidxx,cidxy}- stp_e);
        enpl = stpl + size(cube_e) - minp;
        extension(stpl(1):enpl(1), stpl(2):enpl(2), stpl(3):enpl(3)) = cube_e;
        h5write(assembly_path, '/main', extension, stp_e, num_elem_e);
        disp(['assembled ', num2str(write_count), ' / ', num2str(nfiles), ' ws outputs']); 
        write_count = write_count + 1;  
        toc;
    end
    
    
    
    
end
end


% return an array containing collision pairs between "slot cube" and "entering cube". 
function pairs = get_collision_pairs(slot_cube, entering_cube, thresh_col)
    collision = (slot_cube .* entering_cube) > 0;
    slot_seg = slot_cube(collision);  
    entering_seg = entering_cube(collision);
    cpairs = unique([slot_seg, entering_seg], 'rows');
    pair = zeros(size(cpairs,1),3); 
    parfor i=1:size(cpairs,1)
        id = cpairs(i,1);
        a = entering_cube(slot_cube==id);
        csize = sum((a ==cpairs(i,2)) >0,'all');
        if csize > thresh_col
            pair(i,:) = [cpairs(i,1), cpairs(i,2), csize];   
        end
    end
    
    pairs = pair(any(pair,2),:);
end
function [large,direction] = intf_beyond_extension(ids, vol)
    large = 0;
    dir_x = 0; dir_y = 0; dir_z = 0;
    
    a = vol(1,:,:);
    b = vol(end,:,:);
    c = vol(:,1,:);
    d = vol(:,end,:);
    e = vol(:,:,1);
    f = vol(:,:,end);
    
    m1 = ismember(ids, a);
    m2 = ismember(ids, b);
    m3 = ismember(ids, c);
    m4 = ismember(ids, d);
    m5 = ismember(ids, e);
    m6 = ismember(ids, f);
    
    idx_x = m1 | m2;
    idx_y = m3 | m4;
    idx_z = m5 | m6;
    
    if sum(idx_x) > 0
        large = 1;    
        dir_x = 1;
    end
    if sum(idx_y) > 0
        large = 1;
        dir_y = 1;
    end
    if sum(idx_z) > 0
        large = 1;
        dir_z = 1;
    end        
    direction = [ dir_x, dir_y, dir_z];
end

            
function [new_extension, stp_e, enp_e] = grow_extension(grow, extension, direction, stp_e, enp_e, ids, assembly_path, assembly_size)
    minp = [1,1,1];
    if grow
        stp_e = max( minp, stp_e - ([100,100,25].* direction));
        enp_e = min( assembly_size, enp_e + ([100,100,25] .* direction));
        num_elem_e = enp_e - stp_e + [1,1,1];
        new_extension = h5read(assembly_path, '/main', stp_e, num_elem_e);    
        [grow,direction] = intf_beyond_extension(ids, new_extension);
        grow_extension(grow, new_extension, direction, stp_e, enp_e, ids, assembly_path, assembly_size);
        
    else 
        new_extension = extension;
    end
end
            