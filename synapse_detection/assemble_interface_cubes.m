

% Place cube files in a single directory. It will assemble cubes one by one.
% During the addition of each cube, it looks at colliding segment id pairs.
% If a collision size is above threshold for a given pair, it will join the two segments. 
% After assembling all cubes, you must re-assign segment ids by running 'reassign_interface_id()' function. 


function assemble_interface_cubes(path, save_name, cube_size, overlaps, assembly_size)

addpath /data/research/cjpark147/code/hdf5_ref

default_path ='/data/lrrtm3_wt_syn/interface/';
assembly_path = ['/data/lrrtm3_wt_syn/assembly/', save_name, '.h5'];
cube_files = dir([path,'*.h5']);
nfiles = numel(cube_files);
max_id = 0;
thresh_col = 64;
interface_info = [];  
minp = [1,1,1];
processed_count = 1;
ChunkSize = [512,512,128];

if isfile(assembly_path)
    fprintf('%s%s\n', assembly_path, ' file already exists');
    answer = input('you wanna delete the file and create new one? (true/false)');
    if answer == 1
        h5write(assembly_path, '/main', zeros(assembly_size, 'uint32'));
    else
        return;
    end
else
    h5create(assembly_path, '/main', assembly_size, 'Datatype', 'uint32', 'ChunkSize', ChunkSize);
%    h5write(assembly_path, '/main', zeros(assembly_size, 'uint32'));
end
%}

%% If assembling is killed and you do not want to start from the beginning
% comment out the above "if else" command block and edit the followings:
%{
processed_count = 2;
load([path,'mat_data/', save_name, '_info.mat']);
max_id = 5883;
%}
%% Add cube one by one

for i = processed_count:nfiles
    tic;
    cidx = regexp(cube_files(i).name,'\d*', 'Match');                                           % cube index
    cidxx = str2double(cidx{1}); cidxy = str2double(cidx{2}); cidxz = str2double(cidx{3});
    info_name = cube_files(i).name(1: find(cube_files(i).name=='x') - 2);        
    load(sprintf([path,'mat_data/', info_name, '_info_x%d_y%d_z%d.mat'],[cidxx,cidxy,cidxz]));  % load interface_info.mat of the entering cube

    % interface_tbl contains {old intf_id(no need), local intf id, seg id1, seg id2, celltype1, celltype2}.
    if strcmp(info_name, 'relevant_interface')
        interface_tbl = interface_relevant_tbl;
    end

    % If the cube has at least one interface
    if ~isempty(interface_tbl)                
       
        cube_e = h5read([path, cube_files(i).name],'/main');                           % entering cube        
        stp = minp + (cube_size - overlaps) .* [cidxx-1, cidxy-1, cidxz-1];            % start coord
        enp = min(stp + cube_size - [1,1,1], assembly_size);                           % end coord
        num_elem = enp - stp + [1,1,1];
        cube_s = h5read(assembly_path, '/main', stp, num_elem);                        % slot cube
        stp_e = max( minp, stp - [100,100,25]);                                        % extended start coord
        enp_e = min( assembly_size, enp + [100,100,25]);                               % extended end coord
        num_elem_e = enp_e - stp_e + [1,1,1];
        extension = h5read(assembly_path, '/main', stp_e, num_elem_e);                 % extended cube
%        temp_info = [interface_tbl(:, 2:6), zeros(size(interface_tbl,1),7)];          % will keep: {local intf id, seg1 id, seg2 id, type1, type2, boundingbox x1, y1, z1, x2, y2, z2, size}
        temp_info = [interface_tbl(:, 2:6), zeros(size(interface_tbl,1),1)];
        [cpairs, cube_e, temp_info] = get_collision_pairs(cube_s, cube_e, thresh_col, temp_info);        % get collision id pairs between slot and entering cubes
        divided_id_list = [];                
        temp_info(:,1) = temp_info(:,1) + double(max_id);
        
  
        if numel(cpairs) == 0
            cube_e = cube_e + (max_id * uint32(cube_e~=0));                            % make entering interface id unique
            cube_e = cube_e + (cube_s .* uint32(cube_e == 0));
            max_id = max(cube_e,[],'all');
            [cube_e, temp_info] = drop_small_intf(cube_e, temp_info, thresh_col);      % remove interfaces smaller than thresh_col            
            converted = cube_e;
            
        else                                                                           % if there are collisions
            cpairs(:,2) = cpairs(:,2) + double(max_id);                                % cpairs columns:    [ slot id, entering id, collision size]
            entering_ids = unique(cpairs(:,2));
            slot_ids = unique(cpairs(:,1));
            sfreq = histc(cpairs(:,1), slot_ids);                                      % collision frequency
            efreq = histc(cpairs(:,2), entering_ids);                                  % collision frequency
            converted = cube_e + (max_id * uint32(cube_e~=0));                         % change entering interface id from local to global
            converted = converted +(cube_s .* uint32(cube_e == 0));
            [converted, temp_info] = drop_small_intf(converted, temp_info, thresh_col);        % remove tiny interfaces and record interface size
            max_id = max(converted,[],'all');
            
            % 1-to-1 collision: convert an entering seg id to an existing id
            one2one = ismember(cpairs(:,1), slot_ids(sfreq==1)) & ismember(cpairs(:,2), entering_ids(efreq==1));
            cid = cpairs(one2one, :);                                               % one2one id pairs
            for j = 1:numel(cid(:,1))
                converted((converted==cid(j,2))) = cid(j,1);                        % let entering id = slot id
                temp_info(temp_info(:,1)==cid(j,2), :) = [];                        % delete entering id records
                cpairs(cpairs(:,2)==cid(j,2),2) = cid(j,1);                         % update collision pair table
            end
            divided_id_list = [divided_id_list; cid(:,1)];                          % record divided id history
            
            
            % N-to-1 collision: If an entering segment collides with N segments in slots,
            % convert an entering id to one of N existing ids, say 'new_id', and convert the other N-1 slot ides to 'new_id'.
            many2one = ismember(cpairs(:,2), entering_ids(efreq > 1));
            cid = cpairs(many2one, :);                                              % many2one id pairs
            entering_cid = unique(cid(:,2));
            
            for j = 1:numel(entering_cid)
                new_id = cid(find(cid(:,2) == entering_cid(j)  , 1) , 1);           % new_id = one of N existing ids
                converted(converted == entering_cid(j)) = new_id;                   % let entering id --> new _id
                N = cid(cid(:,2) == entering_cid(j), 1);                            % N existing id
                N(N==new_id) = [];                                                  % (N -1) existing id excluding new_id
                
                [expand,direction] = goes_beyond_extension(N,extension);            % returns true if at least one of N interfaces are too big to be contained within the extension cube.
                if expand
                    disp('expanding vol');
                    [extension,stp_e,enp_e] = expand_volume(expand, extension, direction, stp_e, enp_e, N, assembly_path, assembly_size);       % new larger extension
                end
                
                extension(ismember(extension, N)) = new_id;                         % let (N -1) existing id --> new_id
                converted(ismember(converted, N)) = new_id;                         % let (N -1) existing id introduced by the union of slot % entering cube
                divided_id_list = [divided_id_list; new_id];                        % record divided history
                interface_info(ismember(interface_info(:,1),N), :) = [];            % delete (N -1) existing id records
                temp_info(temp_info(:,1)==entering_cid(j),:) = [];                  % delete entering id records
                cpairs(cpairs(:,2)==entering_cid(j),1:2) = new_id;                    % update collision pair table
                cpairs(ismember(cpairs(:,1),N),1) = new_id;
            end
            
            % 1-to-N collision: convert N entering ids to one colliding slot id.
            one2many = ismember(cpairs(:,1), slot_ids(sfreq > 1));
            cid = cpairs(one2many, :);                                              % one2many id pairs
            slot_cid = unique(cid(:,1));
            for j = 1:numel(slot_cid)
                new_id = slot_cid(j);
                N = cid(cid(:,1) == slot_cid(j)  , 2);                              % N entering ids
                
                [expand,direction] = goes_beyond_extension(N,extension);            % returns true if at least one of N interfaces are too big to be contained within the extension cube.
                if expand
                    disp('expanding vol');
                    [extension,stp_e,enp_e] = expand_volume(expand, extension, direction, stp_e, enp_e, N, assembly_path, assembly_size);
                end
                
                converted(ismember(converted, N)) = new_id;                         % let N entering id --> new_id
                extension(ismember(extension, N)) = new_id;                         % let N entering id --> new_id
                divided_id_list(ismember(divided_id_list, N)) = [];                 % delete entering id records
                divided_id_list = [divided_id_list; new_id];                        % save divided history
                cpairs(cpairs(:,1)==new_id, 1:2) = new_id;                          % update collision pair table
                cpairs(ismember(cpairs(:,2), N),2) = new_id;
                temp_info(ismember(temp_info(:,1),N),:) = [];                       % delete entering id records
            end
       %     max_id = max(converted,[],'all');
            
        end
        num_elem_e = enp_e - stp_e + [1,1,1];
        stpl = minp + (stp - stp_e);                                                % start coord of converted cube within extension cube
        enpl = stpl + size(converted) - minp;                                       % end coord of converted cube within extension cube
        extension(stpl(1):enpl(1), stpl(2):enpl(2), stpl(3):enpl(3)) = converted;   % put converted cube in extension cube
        
        
        if ~isempty(temp_info)
            ndi_list = temp_info(:,1);                                                  % non-divided ids
            interface_info = [interface_info; temp_info];                               % append temp_info to interface_info            
        end        
        
        h5write(assembly_path, '/main', extension, stp_e, num_elem_e);           % write the extension cube to file.                   

    end 
    save([path,'mat_data/', save_name, '_info.mat'],'interface_info');
    disp(['assembled ', num2str(processed_count), '/', num2str(nfiles), ' interface cubes, max_id = ', num2str(max_id)]);
    disp(['cube_file ' , 'x',cidx{1}, '_y',cidx{2}, '_z',cidx{3}]);
    processed_count = processed_count + 1;
    toc;
end
 
%interface_info = interface_info(:,2:end);                                       % columns: seg1, seg2, type1, type2, boundingbox stp_x, stp_y, stp_z, width_x, width_y, w_z  
save([path,'mat_data/', save_name, '_info.mat'],'interface_info');

end


% return an array containing collision pairs between "slot cube" and "entering cube". 
function [pairs, entering_cube, intf_info] = get_collision_pairs(slot_cube, entering_cube, thresh_col, intf_info)
    collision = (slot_cube .* entering_cube) > 0;
    slot_seg = slot_cube(collision);  
    entering_seg = entering_cube(collision);
    cpairs = unique([slot_seg, entering_seg], 'rows');
    pair = zeros(size(cpairs,1),3); 
    discard = zeros(size(cpairs,1),1);
    for i=1:size(cpairs,1)      % don't use parfor here; for is much faster
        id = cpairs(i,1);
        a = entering_cube(slot_cube==id);
        csize = sum((a ==cpairs(i,2)) >0,'all');        
        if csize > thresh_col
            pair(i,:) = [cpairs(i,1), cpairs(i,2), csize];  
        else
            discard(i) = cpairs(i,2);
        end
    end    
    discard = discard(discard > 0);
    % don't discard interface if it is stored in variable "pair"
    idx = ismember(discard, pair(:,1:2));
    discard(idx) = [];
    entering_cube(ismember(entering_cube, discard)) = 0;
    intf_info(ismember(intf_info(:,1), discard),:) = [];
    pairs = pair(any(pair,2),:);

end


% remove interface with size smaller than thresh_col
function [cube, info_update] = drop_small_intf(cube, intf_info, thresh_col)
    binc = 0;
    binc = [binc; unique(intf_info(:,1))];
    counts_size = histc(cube(:), binc);
    binc(binc==0) = []; counts_size(1) = [];    
    intf_info(ismember(intf_info(:,1), binc),6 ) = counts_size;    
    will_be_removed = binc(counts_size <= thresh_col);
    intf_info(ismember(intf_info(:,1), will_be_removed),:) = [];
    cube(ismember(cube, will_be_removed)) = 0;
    info_update = intf_info;
end 
%}

function [large,direction] = goes_beyond_extension(ids, vol)
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

% If there is a large interface that goes over the 'extension', grow the extension volume until it
% contains the entire interface. 
function [new_extension, stp_e, enp_e] = expand_volume(grow, extension, direction, stp_e, enp_e, ids, assembly_path, assembly_size)
    minp = [1,1,1];
    if grow
        stp_e = max( minp, stp_e - ([100,100,25] .* direction));
        enp_e = min( assembly_size, enp_e + ([100,100,25] .* direction));
        num_elem_e = enp_e - stp_e + [1,1,1];
        new_extension = h5read(assembly_path, '/main', stp_e, num_elem_e);    
        [grow,direction] = goes_beyond_extension(ids, new_extension);
        expand_volume(grow, new_extension, direction, stp_e, enp_e, ids, assembly_path, assembly_size);
        
    else 
        new_extension = extension;
    end
end

%{
% function get_bbox_of_intf is not verified.
function info = get_bbox_of_intf(vol, stp, intf_id_list, info, divided)

    temp = stp(1);
    stp(1) = stp(2);
    stp(2) = temp;
    
    result = zeros(numel(intf_id_list),6);
    
    parfor j = 1:numel(intf_id_list)
        bw = (vol==intf_id_list(j));
        bbox = regionprops3(bw, 'BoundingBox').BoundingBox;
        bbox = round(bbox);
        num_box = size(bbox,1);
        
        % This part has a bug! for loop is missing in num_box > 1 scope.
        if num_box > 1
            bbox_enp = bbox(1:3) + bbox(4:6) - 1;
            bbox_stp = bbox(1:3);
            bbox(1,1:3) = min(bbox_stp);
            bbox(1,4:6) = max(bbox_enp) - min(bbox_stp) + 1;
        elseif num_box == 0
            bbox = [0,0,0,0,0,0];
        end
            
        bbox(1,1:3) = bbox(1,1:3) + stp - 1;
        result(j,:) = bbox(1,1:6);
            %{
        try
            if divided
                info(info(:,1) == intf_id_list(j), 6:8) =  bbox(1,1:3) + stp - 1;
                info(info(:,1) == intf_id_list(j), 9:11) = bbox(1,4:6);
            else
                info(j,6:8) = bbox(1,1:3) + stp - 1;
                info(j,9:11) = bbox(1,4:6);
            end
        catch
            disp('error')
        end
            %}
    end
    
    if divided
        
        [ind,loc] = ismember(info(:,1), intf_id_list);
        loc(loc==0) = [];
        info(ind,6:11) = result(loc,:);        
        
    else
        info(:,6:11) = result(:,:);
    end
   
end
%}




