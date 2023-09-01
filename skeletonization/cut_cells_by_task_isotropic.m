function cut_cells_by_task_isotropic (omni_file_name, text_file_name, mipLevel, sample_first_or_last, dataset, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)
    
    input_mip_level = mipLevel;
    
    if ~exist('dataset', 'var')
        dataset = 1;
    end  
    
    fileID = fopen(text_file_name, 'r');
    data = textscan(fileID, '%d %d %d %s %d');
    
    omni_ids = data{1};
%     root_id = data{3};
    axon_task_ids = data{2};

    partition_types = data{4};
    cut_counts = data{5};
    
    fclose(fileID);
    
    axon_task_ids = axon_task_ids';
    
    stitch_volume_one_file_dend_or_axon(omni_file_name, input_mip_level, sample_first_or_last, omni_ids, axon_task_ids, partition_types, cut_counts, dataset, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
    
end

%%
function stitch_volume_one_file_dend_or_axon(omni_file_name, input_mip_level, sample_first_or_last, omni_ids, axon_task_ids, partition_types, cut_counts, dataset, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

    %%
    addpath ./hdf5/
    addpath ./mysql/

    [param,dataset] = lrrtm3_get_global_param(dataset);

    home_vols = param.home_vols;
    home_reconstruction = '/data/lrrtm3_wt_reconstruction/';
    seg_hdf5_file_name = sprintf('%s%s.h5', home_reconstruction, omni_file_name);
    mip_level = input_mip_level;
    mip_factor = 2^mip_level;
    size_of_chunk = param.size_of_chunk;
    scaling_factor = param.scaling_factor;
    path_file_segmentation = sprintf('.files/segmentations/segmentation1/%d/volume.uint32_t.raw',mip_level-2);


    out_vol_size = param.size_of_data;


    out_vol_mip_size = ceil(out_vol_size./(mip_factor./scaling_factor));
    out_vol_mip_size_in_chunk = ceil(out_vol_mip_size./size_of_chunk);
    out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;

    prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, size_of_chunk, seg_hdf5_file_name);

    %%
    global h_sql

    try
        h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
    catch

        fprintf('stat - already db open, close and reopen\n');

        mysql(h_sql, 'close');
        h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
    end

    rtn = mysql(h_sql, sprintf('use %s',mysql_db_name));
    if rtn <= 0
        fprintf('db connection fail\n');
        return;
    end

    %%
    fprintf('reading database ...\n');

    [volume_list, cell_trace_data] = get_cell_trace_data(omni_ids, axon_task_ids, partition_types, cut_counts);

    mysql(h_sql,'close');
    fprintf('done\n');

    %%
    num_vols = numel(volume_list);

    for j = 1:num_vols

        pos = strfind(volume_list{j},'_');
        net_id = volume_list{j}(1:pos-1);
        vol_id = volume_list{j}(pos+1:end);

        fprintf('* (%d/%d) volume %s ... ', j, num_vols, volume_list{j});

        cell_id_of_supervoxel = get_cell_id_of_supervoxel(volume_list{j}, cell_trace_data);
        if ~any(cell_id_of_supervoxel)
            fprintf('no data\n');
            continue;
        end

        [path_of_vol_in_home, vol_coord_info] = lrrtm3_get_vol_info(home_vols, net_id, vol_id, 2^(mip_level-2), dataset); 
        %% obtain volume range info in mip2 version
        [~, vol_coord_info2] = lrrtm3_get_vol_info2(home_vols, net_id, vol_id, mip_factor); 
        %%
        file_path = sprintf('%s%s%s',home_vols, path_of_vol_in_home, path_file_segmentation);
        if isempty(vol_coord_info); continue; end
        chunk = lrrtm3_get_vol_segmentation(file_path, vol_coord_info, dataset);
        fprintf('read, '); 

        max_supervoxel_id = max(chunk(:));
        if numel(cell_id_of_supervoxel) < max_supervoxel_id+1
            cell_id_of_supervoxel(max_supervoxel_id+1)=0;
        end
        chunk = cell_id_of_supervoxel(chunk+1);
        fprintf('converted supervoxels into cell_ids\n');
        if (chunk==0)
            fprintf('    >> chunk blank\n');
            continue;
        end

        % coordinates to write chunks
    %     st=((vol_coord_info.vol_bbox(1:3)-1)./scaling_factor)./mip_factor+1;
    %     ed=min(st+vol_coord_info.mip_vol_size-1,out_vol_mip_size);    

        %% downsampled coordinates to write downsampled chunks
        st = ((vol_coord_info.vol_bbox(1:3)-1)./scaling_factor)./ (mip_factor./scaling_factor) + 1;
                %                           coord -> mip0 voxel position -> mip2 -> iso mip2
        ed = min(st+vol_coord_info2.mip_vol_size-1,out_vol_mip_size);

        %% downsample chunks
        if sample_first_or_last
            chunk = chunk(1:mip_factor:end,1:mip_factor:end,:);
        else
            chunk = chunk(mip_factor:mip_factor:end,mip_factor:mip_factor:end,:);
        end

        %%        
        chunk=chunk(1:ed(1)-st(1)+1,1:ed(2)-st(2)+1,1:ed(3)-st(3)+1);
        fprintf('    >> (%d~%d, %d~%d, %d~%d) ',[st; ed]);
        chunk_out_vol = uint32(h5read(seg_hdf5_file_name, '/main', st, ed-st+1));
        fprintf('existing chunk at target location read, ');
        chunk_out_vol = chunk_out_vol + uint32(chunk).*uint32(chunk_out_vol==0); %"under"write
        h5write(seg_hdf5_file_name, '/main', uint32(chunk_out_vol), st, ed-st+1);
        fprintf('output written\n');

    end

end

%%
function cell_id_of_supervoxel = get_cell_id_of_supervoxel(vol_id, cell_trace_data)

cell_id_of_supervoxel = 0;

idx_trace_data = find(strcmp(cell_trace_data.volume_id, vol_id))';

for idx = idx_trace_data
    
    seg_list = str2double(split(strtrim(cell_trace_data.consensus_segments{idx})))'; 
    seg_list(isnan(seg_list)) = [];
    if isempty(seg_list)
        continue;
    end
    cell_id_of_supervoxel(seg_list+1) = cell_trace_data.cell_id(idx); 

end

end

%%
function [volume_list, cell_trace_data] = get_cell_trace_data(omni_ids, axon_task_ids, partition_types, cut_counts)

    global h_sql

    num_ait = numel(partition_types);

    all_cells_query = ['select t.id, t.cell_id, cm.omni_id, concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name, s.segments, ' ...
        't.left_edge as left_edge, t.right_edge as right_edge, t.depth as depth ' ...
        'from tasks t ' ...
        'inner join cells c on t.cell_id= c.id ' ...
        'inner join cell_metadata cm on cm.id = c.meta_id '...
        'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version ' ...
        'inner join volumes v on t.volume_id = v.id '...
        'where c.id in (select c.id from cells c inner join cell_metadata cm on cm.id = c.meta_id where c.status<>2 and cm.omni_id is not null)' ...
        'and t.status not in (1, 4)'];

    [all_task_id, all_cell_id, all_omni_id, all_volume_id, all_consensus_segments, all_left_edge, all_right_edge, all_depth] = mysql(h_sql, all_cells_query);

    all_omni_id = all_omni_id * 100;

    for idx = 1:num_ait   

        cur_omni_id = omni_ids(idx);
        cur_ait_idx = find(all_task_id == axon_task_ids(idx));
    %     fprintf('current : %d, %d \n',cur_omni_id, cur_ait_idx);

        cur_cell_id = all_cell_id(cur_ait_idx);
        cur_leftEdge = all_left_edge(cur_ait_idx);
        cur_rightEdge = all_right_edge(cur_ait_idx);
        cur_depth = all_depth(cur_ait_idx);

        try
           axon_arr = find(cur_omni_id == (all_omni_id / 100) & cur_cell_id == all_cell_id & all_left_edge >= cur_leftEdge & all_right_edge <= cur_rightEdge & all_depth >= cur_depth);
        catch
            fprintf('err - array info of %d omni.ID is empty, current AIT skip!\n', cur_omni_id);   
            continue;
        end 

        err_code = isempty(axon_arr);
        try
           assert(err_code == 0, 'stat - taskID array is empty, so program exit\n');        
        catch
            mysql(h_sql,'close');
            error('stat - taskID array is empty, so program exit\n');       
        end

        if strcmp(partition_types(idx), 'axon') == 1
           axon_arr = setdiff( find(cur_omni_id == (all_omni_id / 100) & cur_cell_id == all_cell_id),axon_arr);
        end

        all_omni_id(axon_arr) = all_omni_id(axon_arr) + double(cut_counts(idx));

    end

    cell_trace_data.task_id             = all_task_id;
    cell_trace_data.cell_id             = all_omni_id;
    cell_trace_data.volume_id           = all_volume_id;
    cell_trace_data.consensus_segments  = all_consensus_segments;

    volume_list = unique(cell_trace_data.volume_id);

end


%%
function prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, size_of_chunk, seg_hdf5_file_name)

    out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;

    h5create(seg_hdf5_file_name,'/main',out_vol_mip_size,'ChunkSize',size_of_chunk,'Datatype','uint32');
    chunk=zeros(size_of_chunk,'uint32');

    for x = 1:out_vol_mip_size_in_chunk(1)
       for y = 1:out_vol_mip_size_in_chunk(2)
           for z = 1:out_vol_mip_size_in_chunk(3)
               st=([x y z]-1).*size_of_chunk+1;
               ed=[x y z].*size_of_chunk;
               fprintf('filling up [%d %d %d]\n',x,y,z);
               h5write(seg_hdf5_file_name,'/main',chunk,st,ed-st+1); 
           end
       end
    end    

end


function [path_of_vol_in_home,vol_coord_info]=lrrtm3_get_vol_info2(vol_home,net_id,vol_id,mip_factor)

    scaling_factor = [1 1 4];
    default_vol_size = [512 512 128];
    default_vol_overlap = [32 32 8];
    size_of_chunk = [128 128 128];

    path_of_vol_in_home=[];
    xyz=sscanf(vol_id,'x%02d_y%02d_z%02d');
    
    search_pattern=sprintf('%s/z%02d/y%02d/Net_%s_%s*.omni',vol_home,xyz(3),xyz(2),net_id,vol_id);
    t=dir(search_pattern);
    if isempty(t)
        return
    end
    
    name_of_vol=t.name;
    path_of_vol_in_home=sprintf('z%02d/y%02d/%s',xyz(3),xyz(2),name_of_vol);
    id_st_sz=textscan(name_of_vol,'Net %s x%d y%d z%d st %d %d %d sz %d %d %d','delimiter','_');
    
    vol_size=double([id_st_sz{8:10}]);
    vol_size=ceil(vol_size./size_of_chunk).*size_of_chunk; %numbers in file name only considers data size. omni pads zeros to meet chunked size.
    
    ijk = double([id_st_sz{2:4}]); 
    offset = (ijk-1).*(default_vol_size-default_vol_overlap).*scaling_factor; 
    
    vol_bbox=[offset+1 offset+vol_size];
    
    mip_st = ceil(vol_bbox(1:3)./(mip_factor./scaling_factor));
    mip_vol_size = ceil(vol_size./(mip_factor./scaling_factor));
    mip_vol_bbox = [mip_st mip_st+mip_vol_size-1];
    
    vol_coord_info.vol_size=vol_size;
    vol_coord_info.vol_bbox=vol_bbox;
    vol_coord_info.mip_vol_size=mip_vol_size;
    vol_coord_info.mip_vol_bbox=mip_vol_bbox;
    
end

