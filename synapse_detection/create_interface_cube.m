function create_interface_cube(default_path, seg_tile_path, cube_idx, stp, enp, get_bndry)
    %default_path = /data/lrrtm3_wt_syn/interface/;
    % Generate interfaces

    addpath /data/research/cjpark147/code/hdf5_ref
    addpath /data/research/cjpark147/code/ref/
    addpath /data/lrrtm3_wt_code/matlab/mysql/
    addpath /data/research/cjpark147/code/watershed_new/
    
    cube_files = dir('/data/lrrtm3_wt_syn/interface/interface_relevant/*.h5');
    done = cell(numel(cube_files,1));
    for i = 1:numel(cube_files)
        cidx =  regexp(cube_files(i).name,'\d*', 'Match');
        cidxs = [cidx{1}, '_', cidx{2}, '_', cidx{3}];
        done{i} = cidxs;
    end
    
    cstr = [num2str(cube_idx(1)), '_', num2str(cube_idx(2)), '_', num2str(cube_idx(3))];
    if ~ismember(1,strcmp(cstr, done))       
            
    interface_relevant_path = [default_path, 'interface_relevant/'];
    interface_path = '/interface/relevant';
    interface_name = sprintf('interface_x%d_y%d_z%d', cube_idx);
    interface_relev_name = sprintf('relevant_interface_x%d_y%d_z%d', cube_idx);
    bndry_name = sprintf('boundary/bndry_x%d_y%d_z%d', cube_idx);
    num_elem = enp-stp +1;
    load_seg_vol = h5read(seg_tile_path, '/main', stp, num_elem);

    % seg-match table
    seg_match_tbl = []; %org seg id, new seg id
    % re-assign segment id (serial)
    %seg_vol = zeros(size(load_seg_vol), 'uint32');
    seg_vol = load_seg_vol;
    all_ids = unique(load_seg_vol(:));
    all_ids(all_ids==0) = [];
    
    max_id = max(load_seg_vol, [], 'all');
    map = zeros(max_id+1,1);
    new_id = [1:numel(all_ids)]';
    map(all_ids) = new_id;
    map = [0; map];
    seg_vol = map(seg_vol + 1);
    seg_match_tbl = [all_ids, new_id];
    valid_intf_list = [];
  
    %}
    
    if get_bndry

        % interface & bndry
        [IDx1, IDx2, BNDRYx] = getContactSurface_thickness2(seg_vol, 'x');
        [IDy1, IDy2, BNDRYy] = getContactSurface_thickness2(seg_vol, 'y');
        [IDz1, IDz2, BNDRYz] = getContactSurface_thickness2(seg_vol, 'z');
    
    else
        % interface only
        [IDx1, IDx2, ~] = getContactSurface_thickness2(seg_vol, 'x');
        [IDy1, IDy2, ~] = getContactSurface_thickness2(seg_vol, 'y');
        [IDz1, IDz2, ~] = getContactSurface_thickness2(seg_vol, 'z');    
    end    

    IDx2(IDx1<1) = 0;   %remove background-segment pair
    IDy2(IDy1<1) = 0;
    IDz2(IDz1<1) = 0; 
    
    IDx = IDx1 * 100000 + IDx2;
    IDy = IDy1 * 100000 + IDy2;
    IDz = IDz1 * 100000 + IDz2;
    
    all_interfaces = zeros(size(seg_vol));
    all_interfaces(all_interfaces<1) = IDx(all_interfaces<1);
    all_interfaces(all_interfaces<1) = IDy(all_interfaces<1);
    all_interfaces(all_interfaces<1) = IDz(all_interfaces<1);

    interface_ids = unique(all_interfaces(:));
    interface_ids(interface_ids==0) = [];

    write_id = 1;
    interface_vol = zeros(size(seg_vol));
    interface_tbl = []; %segid1*1000+segid2, intf id, segid1, segid2

 %   fprintf('ALL? %d\n', numel(interface_ids));
    
    h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
    rtn = mysql(h_sql, 'use omni_20210503');
    if rtn <= 0
        fprintf('DB connection failed.\n');
        return
    end     
  
 
    for iter=1:numel(interface_ids)    
  %      fprintf('%d: ', iter);
        
        bw = (all_interfaces == interface_ids(iter));

        cc = bwconncomp(bw, 26);
  %      fprintf('%d components.\n', cc.NumObjects);
        for i=1:cc.NumObjects
            if write_id == 6552
                disp('debug!')
            end
            if numel(cc.PixelIdxList{i}) < 20
                continue
            end

            interface_vol(cc.PixelIdxList{i}) = write_id;

            seg_ids1 = [IDx1(cc.PixelIdxList{i}); IDy1(cc.PixelIdxList{i}); IDz1(cc.PixelIdxList{i})];
            seg_ids2 = [IDx2(cc.PixelIdxList{i}); IDy2(cc.PixelIdxList{i}); IDz2(cc.PixelIdxList{i})];
            seg_ids = [seg_ids1 seg_ids2];
            seg_ids(seg_ids==0) = [];
            
            seg_ids1(seg_ids1==0) = [];
            seg_ids2(seg_ids2==0) = [];

            if numel(unique(seg_ids)) ~= 2
                dom1 = mode(seg_ids1);
                dom2 = mode(seg_ids2);

                seg_id1 = min(dom1, dom2);
                seg_id2 = max(dom1, dom2);
                clear dom1; clear dom2;
            else
                elem = unique(seg_ids);
                seg_id1 = elem(1);
                seg_id2 = elem(2);
                clear elem;
            end
            
            seg_id1 = double(seg_match_tbl(seg_id1,1));
            seg_id2 = double(seg_match_tbl(seg_id2,1));
            
            
            query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id1);
            cell_type1 = mysql(h_sql, query);            
            query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id2);
            cell_type2 = mysql(h_sql, query);            
            valid_pair = cell_type_validation_check(cell_type1, cell_type2, seg_id1, seg_id2, cube_idx);
            
            if valid_pair 
                valid_intf_list = [valid_intf_list write_id];
            end
            
            if isempty(cell_type1)
                cell_type1 = 999;
            end
            
            if isempty(cell_type2)
                cell_type2 = 999;
            end
            interface_tbl = [interface_tbl; double(interface_ids(iter)) double(write_id) seg_id1 seg_id2 cell_type1 cell_type2];

            write_id = write_id+1;
        end
    end     
    
    mysql(h_sql, 'close');    
    interface_vol = imfill(interface_vol, 26); 
 
 
    if get_bndry
        neuron_bndry = BNDRYx > 0 | BNDRYy > 0 | BNDRYz > 0;
        % save neuronal boundary map
        if ~isfile([default_path, bndry_name, '.h5'])
            h5create([default_path,  bndry_name, '.h5'], '/main', size(neuron_bndry), 'Datatype', 'uint32');
        end
        h5write([default_path, bndry_name, '.h5'], '/main', uint32(neuron_bndry));   
    end
    
    % save all interfaces 
    
    save(sprintf([default_path,'/interface_all/mat_data/interface_info_x%d_y%d_z%d.mat'], cube_idx), 'interface_tbl');
    
    if ~isfile([default_path, 'interface_all/', interface_name,'.h5'])
        h5create([default_path, 'interface_all/', interface_name, '.h5'], '/main', size(interface_vol), 'Datatype', 'uint32');
    end
    h5write([default_path, 'interface_all/', interface_name, '.h5'], '/main', uint32(interface_vol));
    %}

    intf_id_list = unique(interface_vol(:));
    intf_id_list(intf_id_list==0) = [];
    rm_list = setdiff(intf_id_list, valid_intf_list);
    idx = ismember(interface_vol, rm_list);
    interface_vol(idx) = 0;
    
    
    % save relevant interfaces 
    
    interface_relevant_tbl = interface_tbl;
    if ~isempty(interface_relevant_tbl)
        % save relevant interfaces only     
        interface_relevant_tbl(ismember(interface_relevant_tbl(:,2), rm_list), :) = [];        
        %{
        try
            interface_tbl = [interface_tbl, cell_type_list];
        catch
            disp([num2str(size(cell_type_list)), ', ' , num2str(size(interface_tbl)), ', ' , num2str(cube_idx)]); 
        end
        %}
    end
    
    save(sprintf([interface_relevant_path, 'mat_data/relevant_interface_info_x%d_y%d_z%d.mat'], cube_idx), 'interface_relevant_tbl');
    
    if ~isfile([interface_relevant_path, interface_relev_name,'.h5'])
        h5create([interface_relevant_path, interface_relev_name, '.h5'], '/main', size(interface_vol), 'Datatype', 'uint32');
    end
    h5write([interface_relevant_path, interface_relev_name, '.h5'], '/main', uint32(interface_vol));    
    
    end
    

    
end

    
    
%% functions

function valid = cell_type_validation_check(cell_type1, cell_type2, seg_id1, seg_id2, cube_idx)
    valid = 1;
    if isempty(cell_type1) || isempty(cell_type2)
        fprintf('read cell type information failed. check segment status in DB\n');
        fprintf('cube idx: (%d, %d, %d)  seg1 id: %d  seg2 id: %d\n', cube_idx, seg_id1, seg_id2);
        valid = 0;
        return
    end
    
%    fprintf('celltype %d(%s) - %d(%s)\n', cell_type1, cell_type_to_str(cell_type1), cell_type2, cell_type_to_str(cell_type2));    
    switch cell_type1
        case 1  %PC (accepts pf, cf, int, golgi, undecidable)
            if cell_type2 <= 1 || cell_type2 == 5 || cell_type2 == 6 
                valid = 0;
            end
        case 2  %PF (accepts pc, int, golgi, undecidable)
            if cell_type2 < 1 || cell_type2 == 2 || cell_type2 == 3 || cell_type2 == 5 || cell_type2 == 6 
                valid = 0;
            end            
        case 3  %CF (accepts pc, int, golgi, undecidable)
            if cell_type2 < 1 || cell_type2 == 2 || cell_type2 == 3 || cell_type2 == 5 || cell_type2 == 6
                valid = 0;
            end            
        case 4  %INT (accepts pc, pf, cf, int, golgi, undecidable)
            if cell_type2 < 1 || cell_type2 == 5 || cell_type2 == 6
                valid = 0;
            end            
        case 5  %glia
            valid = 0;            
        case 6  %golgi
            if cell_type2 < 1 || cell_type2 == 5 || cell_type2 == 6
                valid = 0;
            end
        case 7  % undecidable
            if cell_type2 < 1 || cell_type2 == 5 
                valid = 0;
            end
        otherwise
            valid = 0;
    end    
end

%%

function str = cell_type_to_str(cell_type)
    switch cell_type
        case 0
            str = 'unknown';
        case 1
            str = 'pc';
        case 2 
            str = 'pf';
        case 3 
            str = 'cf';
        case 4
            str = 'int';
        case 5
            str = 'glia';
        case 6
            str = 'golgi';
        case 7
            str = 'undecidable';
    end
end


