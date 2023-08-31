function cell_id_list = pf_cell_creator(net_prefix, vidx, max_cell)
    addpaths();
    
    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        cell_id_list = [];
        return
    end
    
    cell_id_list = [];
    if nargin < 2 || isempty(vidx) || isempty(net_prefix)
        write_log('##usage: pf_cell_creator(net_prefix, volume_index); ex: pf_cell_creator(''C1a'', [3 9 4]);', 1);        
        return
    end
    if nargin < 3 || isempty(max_cell) || max_cell > get_max_cell_th()
        write_log('max cell: set to default.');        
        max_cell = get_max_cell_th();
    end
    
    write_log(sprintf('[PF_CELL_CREATOR] %s_x%02d_y%02d_z%02d, %d cells ----------------------------------------', ...
        net_prefix, vidx, max_cell));        
    write_log(sprintf('  create %d cell(s) for volume %s_x%02d_y%02d_z%02d', max_cell, net_prefix, vidx));
    write_log('  Create cells.', 1);
    
    [clusters, sizes, total_sizes] = get_cluster_info(net_prefix, vidx, 0.990);        
    
    db_info = get_dbinfo();       
    handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(handle_sql, ['use ' db_info.db_name]);
    if rtn <= 0
        write_log(sprintf('@ERROR: DB open failed (host:%s, id:%s)', db_info.host, db_info.user), 1);
        return
    end
    write_log(sprintf('  DB connection established. %s:%s', db_info.host, db_info.db_name));    
    
    cell_id_list = create_cell(handle_sql, clusters, sizes, total_sizes, vidx, net_prefix, user, max_cell);        
    release_db(handle_sql);      
end    
  
%%
function cell_id_list = create_cell(handle_sql, clusters, sizes, total_sizes, vidx, net_prefix, user, max_cell)
    write_log('  [create cell]');
    volume_name = sprintf('%s_x%02d_y%02d_z%02d', net_prefix, vidx);
    cell_id_list = [];    
    
    query = sprintf('SELECT id FROM volumes WHERE net_id=''%s'' AND vx=%d AND vy=%d AND vz=%d;', net_prefix, vidx(1), vidx(2), vidx(3));
    vid = mysql(handle_sql, query);
    if isempty(vid)
        write_log(sprintf('@ERROR: can''t find volume information for %s.', volume_name), 1);
        return
    end    
    
    ncells = numel(total_sizes);    
    for idx=1:ncells
        if total_sizes(idx) > 200000 || total_sizes(idx) < 40000
            continue
        end
        
        %check duplication
        [exist_flag, info] = find_exist_tasks_for_creator(handle_sql, vid, str2num(clusters{idx}), str2num(sizes{idx}));
        if exist_flag == 1
            %consider duplication when tasks.status is in normal, duplicated, frozen
            if sum((info{6}(:)==0 | info{6}(:)==2 | info{6}(:)==3 )) > 0
                continue
            end
            %consider duplication when root tasks.status is stashed and created by cell creator
            if sum(info{6}(:) == 1 & info{7}(:)==0 & contains(info{8}(:), ',C1a_')) > 0
                write_log(sprintf('  %dth cluster already dropped by user. skip.', idx));
                continue
            end
        end       

        write_log(sprintf('(%d/%d)', numel(cell_id_list)+1, max_cell));       
        %add cell_metadata, cell        
        msg = '   insert cell_metadata, cell info, ';
        query = sprintf('SELECT MAX(omni_id) FROM cell_metadata;');
        omni_id = mysql(handle_sql, query);
        if isempty(omni_id)
            omni_id = 0;
        else
            omni_id = omni_id+1;
        end
        
        query = sprintf('INSERT INTO cell_metadata (omni_id,name,notes) VALUES (%d,''%s'',''%s'');', ...
            omni_id, sprintf('cell_%05d', omni_id), sprintf('%s,%s', user, volume_name));
        if mysql(handle_sql, query) < 0            
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: query failed(%s)', query),1);
            continue
        end
        
        query = sprintf('SELECT LAST_INSERT_ID();');
        meta_id = mysql(handle_sql, query);
        query = sprintf('INSERT INTO cells (meta_id,dataset_id,display) VALUES (%d,1,0);', meta_id);
        if mysql(handle_sql, query) < 0
            write_log(sprintf('@ERROR: query failed(%s)', query),1);
            continue
        end        
        
        query = sprintf('SELECT LAST_INSERT_ID();');
        cell_id = mysql(handle_sql, query);
        write_log(sprintf('%s >> done. cell id is %d.', msg, cell_id));
        
        cell_id_list = [cell_id_list cell_id];
        
        msg = sprintf('   insert task record for segments %s, ', clusters(idx));
        query = sprintf('INSERT INTO tasks (cell_id,volume_id,left_edge,right_edge,spawning_coordinate,notes,seeds) VALUES (%d,%d,1,2,'' '',''size %d'',''%s'');', ...
            cell_id, vid, total_sizes(idx), clusters(idx));
        if mysql(handle_sql, query) < 0 
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: query failed(%s)', query),1);
            continue
        end
        write_log(sprintf('%s >> done. ', msg));
        
        query = sprintf('SELECT LAST_INSERT_ID();');
        tid = mysql(handle_sql, query);
        
        msg = '   insert consensus record, ';
        query = sprintf('INSERT INTO consensuses (task_id,user_id,comparison_group_id,status,segments) VALUES (%d,5,0,2,''%s'');', ...
            tid, clusters(idx));        
        if mysql(handle_sql, query) < 0 
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: query failed(%s)', query),1);
            continue
        end        
        write_log(sprintf('%s >> done.', msg));             
        
        if numel(cell_id_list) >= max_cell
            write_log('   enough cell found. quit creator.');
            return
        end    
    end
    
    if numel(cell_id_list) < max_cell
        write_log('   no more available fragments to create cell in this volume. quit creator.', 1);
    end
end

%%
function [clusters, sizes, total_sizes] = get_cluster_info(net_prefix, vidx, thresh)
    write_log('  [get cluster info]');
    
    global home_vols
    home_vols = sprintf('/data/lrrtm3_wt_omnivol/');

    [vol_path_in_home, ~] = ...
        lrrtm3_get_vol_info(home_vols, net_prefix, sprintf('x%02d_y%02d_z%02d', vidx), 2^0);
    vol_path = sprintf('%s/%s%s', home_vols, vol_path_in_home);
    mst_fname = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst.data',vol_path);
    mst = omni_read_mst(mst_fname);
    mst = [[mst.node1]' [mst.node2]' [mst.affin]'];

    mst = mst(mst(:,3)>thresh, 1:3);
    max_node = max([mst(:,1); mst(:,2)]);

    [~,idx]=sort(mst(:,3),'descend');
    cluster_id_of_node = 1:max_node;
    for i=1:numel(idx)
        node1 = mst(idx(i),1);
        node2 = mst(idx(i),2);

        cluster1 = cluster_id_of_node(node1);
        cluster2 = cluster_id_of_node(node2);

        cluster_id_of_node(cluster_id_of_node==cluster2) = cluster1;
    end
    
    [~, seg_size] = omni_read_segment_size(vol_path, 1:max_node);
    
    cluster_id = unique(cluster_id_of_node);
    ncluster = numel(cluster_id);
    
    clusters = [];
    sizes = [];
    total_sizes = [];
    for cidx=1:ncluster
        seg_list = find(cluster_id_of_node==cluster_id(cidx));
        
        seg_list_str = sprintf('%d ', seg_list);
        seg_list_str(end) = [];        
        clusters = [clusters; sprintf("%s", seg_list_str)];
        
        sizes_str = sprintf('%d ', seg_size(seg_list));
        sizes_str(end) = [];
        sizes = [sizes; sprintf("%s", sizes_str)];
        
        total_sizes = [total_sizes; sum(seg_size(seg_list))];        
    end
    write_log(sprintf('  %d clusters found.', size(clusters,1)));
end

%%
function release_db(handle)
    mysql(handle, 'close');
    write_log('  DB connection released.');
end




%% from spawner code
function [rtn_exist, dup_seg_list] = find_exist_tasks_for_creator(handle_sql, vol_id, seg_list, seg_size)

global mip_level mip_factor scaling_factor default_vol_overlap default_vol_size 

rtn_exist=0;
dup_seg2=[];

[sv_cell, sv_con_id, sv_task_id, sv_seg, task_st, task_depth, meta_notes] = mysql(handle_sql, sprintf([...
    'select t.cell_id, c.id, c.task_id, c.segments, t.status, t.depth, m.notes ' ...
    'from tasks t ' ...
    'inner join cells cell on cell.id=t.cell_id ' ...
    'inner join cell_metadata m on m.id=cell.meta_id ' ...
    'left join consensuses c on c.task_id=t.id and c.version=t.latest_consensus_version and c.status=2 ' ...
    'where t.volume_id=%d;' ...
    ],vol_id));
sv_seg = regexp(sv_seg, '\d*', 'Match');
dup_seg_list = [];
total_size=sum(seg_size(:));

n=0;
for i=1:numel(sv_con_id)
    sv_seg{i} = cellfun(@str2num, sv_seg{i});
    dup_seg = sv_seg{i}(ismember(sv_seg{i},seg_list));
    if ~isempty(dup_seg)
        n=n+1;
        dup_seg_list{1,1}(n) = sv_cell(i); 
        dup_seg_list{1,2}(n) = sv_con_id(i);
        dup_seg_list{1,3}(n) = sv_task_id(i);
        dup_seg_list{1,4}{n} = dup_seg;
        dup_seg_list{1,5}(n) = sum(seg_size(ismember(seg_list,dup_seg)))/total_size;
        dup_seg_list{1,6}(n) = task_st(i);
        dup_seg_list{1,7}(n) = task_depth(i);
        dup_seg_list{1,8}(n) = meta_notes(i);
    end
end

[vx,vy,vz] = mysql(handle_sql, sprintf(['select vx,vy,vz from volumes where id=%d;'],vol_id));
is_other_volume_tasks_exist = mysql(sprintf(['select t.id from tasks as t join volumes as v on t.volume_id = v.id ' ...
    'where v.vx=%d && v.vy=%d && v.vz=%d && t.volume_id!=%d';],vx,vy,vz,vol_id));

if isempty(is_other_volume_tasks_exist)
    if ~isempty(dup_seg_list)
        rtn_exist = 1;
    end
    return
end

mip_level=2;
mip_factor=[2 2 2].^mip_level;
scaling_factor=[1 1 4];
default_vol_overlap = [32 32 8];
default_vol_size = [512 512 128];

% get this vol segmentation file name, coordinate and size 
[this_vol_path,this_vol_size] = get_volume_info(handle_sql, vol_id);
this_vol_seg_path = sprintf(...
    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',this_vol_path,mip_level);
this_vol_mip_size = this_vol_size./mip_factor;

this_volc=read_volume(this_vol_seg_path,this_vol_mip_size);

bw_traced_in_this_volc = ismember(this_volc, seg_list);
vol_id_diff = mysql(handle_sql, sprintf(['select id from volumes where vx=%d && vy=%d && vz=%d && id!=%d'],vx,vy,vz,vol_id));

fraction_threshold=0.8;
size_threshold=12;

for vv=1:numel(vol_id_diff)

    [sv_cell, sv_con_id, sv_task_id, sv_seg, task_st, task_depth, meta_notes] = mysql(handle_sql, sprintf([...
    'select t.cell_id, c.id, c.task_id, c.segments, t.status, t.depth, m.notes ' ...
    'from tasks t ' ...
    'inner join cells cell on cell.id=t.cell_id ' ...
    'inner join cell_metadata m on m.id=cell.meta_id ' ...
    'left join consensuses c on c.task_id=t.id and c.version=t.latest_consensus_version and c.status=2 ' ...
    'where t.volume_id=%d;' ...
    ],vol_id_diff(vv)));

    if isempty(sv_task_id)
        continue 
    end
    
    sv_seg = regexp(sv_seg, '\d*', 'Match');
    
    [dup_vol_path,dup_vol_size] = get_volume_info(handle_sql, vol_id_diff(vv));
    dup_vol_seg_path = sprintf(...
        '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',dup_vol_path,mip_level);
    dup_vol_mip_size = dup_vol_size./mip_factor;
    dup_volc = read_volume(dup_vol_seg_path, dup_vol_mip_size);
    
    for ii=1:numel(sv_task_id)
        dup_seg = cellfun(@str2num, sv_seg{ii});
        bw_traced_in_dup_volc = ismember(dup_volc, dup_seg);
        bw_corresponded = bw_traced_in_this_volc.* bw_traced_in_dup_volc;
        seg_corresponded = bw_corresponded.*dup_volc;
        
        %if a segment is included in branch more than x% and is larger than y, put this segment to result
        num_total_voxels_of_seg_in_volume = arrayfun( @(x) sum(dup_volc(:)==x), dup_seg );
        num_duppl_voxels_of_seg_in_volume = arrayfun( @(x) sum(seg_corresponded(:)==x), dup_seg );
        ratio = num_duppl_voxels_of_seg_in_volume./num_total_voxels_of_seg_in_volume;
            
        idx = ratio > fraction_threshold & num_total_voxels_of_seg_in_volume>size_threshold; 
        dup_seg2 = dup_seg(idx);
        
        if ~isempty(dup_seg2)
            n=n+1;
            dup_seg_list{1,1}(n) = sv_cell(ii); 
            dup_seg_list{1,2}(n) = sv_con_id(ii);
            dup_seg_list{1,3}(n) = sv_task_id(ii);
            dup_seg_list{1,4}{n} = dup_seg2;
            dup_seg_list{1,5}(n) = 0;
            dup_seg_list{1,6}(n) = task_st(ii);
            dup_seg_list{1,7}(n) = task_depth(ii);
            dup_seg_list{1,8}(n) = meta_notes(ii);
        end
            
    end
    
end

if ~isempty(dup_seg_list)
    rtn_exist = 1;
end

end

%%    
%get mipmap information from volume_id
function [fn, sz] = get_volume_info(handle_sql, vol_id)

fn=[]; loc=[]; sz=[];

global scaling_factor default_vol_overlap default_vol_size

%need path,vx,vy,vz
[pth,vx,vy,vz] = mysql(handle_sql, sprintf('select path,vx,vy,vz from volumes where id=%d',vol_id));

pth = char(pth);
fn = pth;

ijk = [vx,vy,vz];
offset = (ijk-1).*(default_vol_size-default_vol_overlap).*scaling_factor; 
loc = offset + 1;

nums = regexp(pth, '\d*', 'Match');
sz = [str2num(nums{end-2}),str2num(nums{end-1}),str2num(nums{end})];

end

%%
function volc = read_volume(filename,sz)

cs = 128;
fid = fopen(filename,'r');
xth = sz(1)/cs; yth = sz(2)/cs;
n=1;

for j=1:yth
    for i=1:xth
        rowarr = fread(fid,cs*cs*cs,'uint32');
        volc(1+cs*(i-1):cs*i,1+cs*(j-1):cs*j,:) = reshape(rowarr,[cs,cs,cs]);
        n=n+1;
    end
end

fclose(fid);

end

