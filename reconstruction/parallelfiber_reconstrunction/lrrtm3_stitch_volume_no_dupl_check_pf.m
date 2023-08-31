function lrrtm3_stitch_volume_no_dupl_check_pf(omni_file_name, input_mip_level, cell_id_list, id_type, silent)

addpaths();

global home_vols home_reconstruction
home_vols = sprintf('/data/lrrtm3_wt_omnivol/');
home_reconstruction = sprintf('/data/lrrtm3_wt_pf_review/');
omni_exe_path = '/data/omni/omni.omnify/omni.omnify';

global mip_level mip_factor size_of_uint32 size_of_chunk_linear size_of_chunk scaling_factor path_file_segmentation seg_hdf5_file_name default_vol_size default_vol_overlap
seg_hdf5_file_name = sprintf('%s/%s.h5', home_reconstruction, omni_file_name);
mip_level = input_mip_level;
mip_factor = 2^mip_level;
size_of_chunk = [128 128 128];
size_of_chunk_linear = prod(size_of_chunk);
size_of_uint32 = 4;
scaling_factor = [1 1 4];
path_file_segmentation = sprintf('.files/segmentations/segmentation1/%d/volume.uint32_t.raw',mip_level);
default_vol_size = [512 512 128];
default_vol_overlap = [32 32 8];

out_vol_size = [14592, 10240, 1024];
out_vol_mip_size = ceil(out_vol_size/mip_factor);
out_vol_mip_size_in_chunk = ceil(out_vol_mip_size./size_of_chunk);
out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;

prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, silent); 

global h_sql
db_info = get_dbinfo();

h_sql = mysql('open',db_info.host, db_info.user, db_info.passwd);
rtn = mysql(h_sql, sprintf('use %s', db_info.db_name));
if rtn <= 0
    write_log('@ERROR: db connection failed.', 1);
    return
end

if ~exist('cell_id_list','var')
    cell_id_list = [];
end
write_log('     reading database ... ');

if nargin < 4
    id_type = 1;
    silent = 0;
%     use_cell_id = 0;
end

switch id_type
    case 1
        write_log('     reconstruction will displayed omni_id.');
    case 2
        write_log('     reconstruction will displayed cell_id.');
    case 3
        write_log('     reconstruction will displayed task_id.');
    otherwise
        write_log(sprintf('     unknown id_type(%d), reconstruction will displayed omni_id.', id_type));
        id_type = 1;
end


[volume_list, cell_trace_data] = get_cell_trace_data(cell_id_list, id_type);
mysql(h_sql,'close');
write_log('     done');

num_vols = numel(volume_list);

if silent
    write_log(sprintf('     * %d volumes will be written.', num_vols));
    
    for j = 1:num_vols

        pos = strfind(volume_list{j},'_');
        net_id = volume_list{j}(1:pos-1);
        vol_id = volume_list{j}(pos+1:end);

        cell_id_of_supervoxel = get_cell_id_of_supervoxel(volume_list{j}, cell_trace_data);
        if ~any(cell_id_of_supervoxel)
            continue
        end

        [path_of_vol_in_home, vol_coord_info] = lrrtm3_get_vol_info(home_vols, net_id, vol_id, mip_factor); 

        file_path = sprintf('%s%s%s',home_vols, path_of_vol_in_home, path_file_segmentation);
        chunk = lrrtm3_get_vol_segmentation(file_path, vol_coord_info);

        max_supervoxel_id = max(chunk(:));
        if numel(cell_id_of_supervoxel) < max_supervoxel_id+1
            cell_id_of_supervoxel(max_supervoxel_id+1)=0;
        end
        
        chunk = cell_id_of_supervoxel(chunk+1);
        if (chunk==0)
            continue
        end

        % write chunk
        st=((vol_coord_info.vol_bbox(1:3)-1)./scaling_factor)./mip_factor+1;
        ed=min(st+vol_coord_info.mip_vol_size-1,out_vol_mip_size);    

        chunk=chunk(1:ed(1)-st(1)+1,1:ed(2)-st(2)+1,1:ed(3)-st(3)+1);
        chunk_out_vol = uint32(get_hdf5_file(seg_hdf5_file_name, '/main', st, ed));
        chunk_out_vol = chunk_out_vol + uint32(chunk).*uint32(chunk_out_vol==0); %"under"write
        write_hdf5_file(seg_hdf5_file_name, '/main', st, ed, uint32(chunk_out_vol));
    end
else
    for j = 1:num_vols

        pos = strfind(volume_list{j},'_');
        net_id = volume_list{j}(1:pos-1);
        vol_id = volume_list{j}(pos+1:end);

        fprintf('* (%d/%d) volume %s ... ', j, num_vols, volume_list{j});

        cell_id_of_supervoxel = get_cell_id_of_supervoxel(volume_list{j}, cell_trace_data);
        if ~any(cell_id_of_supervoxel)
            fprintf('no data\n');
            continue
        end

        [path_of_vol_in_home, vol_coord_info] = lrrtm3_get_vol_info(home_vols, net_id, vol_id, mip_factor); 

        file_path = sprintf('%s%s%s',home_vols, path_of_vol_in_home, path_file_segmentation);
        chunk = lrrtm3_get_vol_segmentation(file_path, vol_coord_info);
        fprintf('read, '); 

        max_supervoxel_id = max(chunk(:));
        if numel(cell_id_of_supervoxel) < max_supervoxel_id+1
            cell_id_of_supervoxel(max_supervoxel_id+1)=0;
        end
        chunk = cell_id_of_supervoxel(chunk+1);
        fprintf('converted supervoxels into cell_ids\n');
        if (chunk==0)
            fprintf('    >> chunk blank\n');
            continue
        end

        % write chunk
        st=((vol_coord_info.vol_bbox(1:3)-1)./scaling_factor)./mip_factor+1;
        ed=min(st+vol_coord_info.mip_vol_size-1,out_vol_mip_size);    

        chunk=chunk(1:ed(1)-st(1)+1,1:ed(2)-st(2)+1,1:ed(3)-st(3)+1);
        fprintf('    >> (%d~%d, %d~%d, %d~%d) ',[st; ed]);
        chunk_out_vol = uint32(get_hdf5_file(seg_hdf5_file_name, '/main', st, ed));
        fprintf('existing chunk at target location read, ');
        chunk_out_vol = chunk_out_vol + uint32(chunk).*uint32(chunk_out_vol==0); %"under"write
        write_hdf5_file(seg_hdf5_file_name, '/main', st, ed, uint32(chunk_out_vol));
        fprintf('output written\n');

    end
end

file_name = sprintf('%s/omnify_%s.cmd', home_reconstruction, omni_file_name);
fo = fopen(file_name,'w');
fprintf(fo,'create:%s/%s.omni\n', home_reconstruction, omni_file_name);
fprintf(fo,'loadHDF5seg:%s\n', seg_hdf5_file_name);
fprintf(fo,'setSegResolution:1,%d,%d,%d\n',mip_factor*scaling_factor);
fprintf(fo,'mesh\n');
fprintf(fo,'close\n');
fclose(fo);

if silent 
    write_log('     omnification start...', 1);
    [~, cmdout] = system([omni_exe_path ' --headless --cmdfile ' file_name]);
    write_log('     omnification result:', 1);
    if numel(cmdout) <= 500
        write_log(sprintf('%s', cmdout), 1);
    else
        write_log(sprintf('%s', cmdout(end-499:end)), 1);
    end
else
    system([omni_exe_path ' --headless --cmdfile ' file_name]);
end
    
system(sprintf('find %s/%s.omni* -type d -exec chmod 770 {} +', home_reconstruction, omni_file_name));
system(sprintf('find %s/%s.omni* -type f -exec chmod 660 {} +', home_reconstruction, omni_file_name));
end

%%
function cell_id_of_supervoxel = get_cell_id_of_supervoxel(vol_id, cell_trace_data)

cell_id_of_supervoxel=[0];

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
function [volume_list, cell_trace_data] = get_cell_trace_data(cell_id_list, id_type)

global h_sql

if isempty(cell_id_list)
    query = sprintf('select id from cells where status<>2;');
    cell_id_list = mysql(h_sql, query);
end

cell_id_list_string = sprintf('%d,', cell_id_list);
cell_id_list_string = sprintf('(%s)', cell_id_list_string(1:end-1));

%{
query = ['select t.id,c.omni_id*10+t.status,concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name,s.segments ' ...    
         'from tasks t ' ...
         'inner join cells c on t.cell_id = c.id ' ...
         'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version ' ...
         'inner join volumes v on t.volume_id = v.id '...
         'where c.id in ' cell_id_list_string];         
%}
switch id_type
    case 1 %omni_id
        query = ['select t.id,m.omni_id,concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name,s.segments ' ...    
             'from tasks t ' ...
             'inner join cells c on t.cell_id = c.id ' ...
             'left join cell_metadata m on c.meta_id=m.id ' ...
             'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version ' ...
             'inner join volumes v on t.volume_id = v.id '...
             'where t.status not in (1,4) and c.id in ' cell_id_list_string];              
    case 2 %cell_id
        query = ['select t.id,c.id AS cell_id,concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name,s.segments ' ...    
             'from tasks t ' ...
             'inner join cells c on t.cell_id = c.id ' ...
             'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version ' ...
             'inner join volumes v on t.volume_id = v.id '...
             'where t.status not in (1,4) and c.id in ' cell_id_list_string];
    case 3 %task_id
        query = ['select t.id,t.id AS cell_id,concat(net_id,''_x'',lpad(vx,2,''0''),''_y'',lpad(vy,2,''0''),''_z'',lpad(vz,2,''0'')) as volume_name,s.segments ' ...    
             'from tasks t ' ...
             'inner join cells c on t.cell_id = c.id ' ...
             'inner join consensuses s on t.id = s.task_id and t.latest_consensus_version = s.version ' ...
             'inner join volumes v on t.volume_id = v.id '...
             'where t.status not in (1,4) and c.id in ' cell_id_list_string];        
end

[task_id, cell_id, volume_id, consensus_segments] = mysql(h_sql,query);

cell_trace_data.task_id = task_id;
cell_trace_data.cell_id = cell_id;
cell_trace_data.volume_id = volume_id;
cell_trace_data.consensus_segments = consensus_segments;

volume_list = unique(cell_trace_data.volume_id);    
end

%%
function prepare_seg_hdf5_file(out_vol_mip_size_in_chunk, silent)

global size_of_chunk seg_hdf5_file_name

out_vol_mip_size = out_vol_mip_size_in_chunk.*size_of_chunk;

create_hdf5_file(seg_hdf5_file_name,'/main',out_vol_mip_size,size_of_chunk,[0 0 0],'uint');
chunk=zeros(size_of_chunk,'uint32');

if silent
    write_log('     filling start.');
    for x = 1:out_vol_mip_size_in_chunk(1)
       for y = 1:out_vol_mip_size_in_chunk(2)
           for z = 1:out_vol_mip_size_in_chunk(3)
               st=([x y z]-1).*size_of_chunk+1;
               ed=[x y z].*size_of_chunk;               
               write_hdf5_file(seg_hdf5_file_name,'/main',st,ed,chunk); 
           end
       end
    end
    write_log('     filling done.');
else
    for x = 1:out_vol_mip_size_in_chunk(1)
       for y = 1:out_vol_mip_size_in_chunk(2)
           for z = 1:out_vol_mip_size_in_chunk(3)
               st=([x y z]-1).*size_of_chunk+1;
               ed=[x y z].*size_of_chunk;
               write_log(sprintf('     filling up [%d %d %d]',x,y,z));
               write_hdf5_file(seg_hdf5_file_name,'/main',st,ed,chunk); 
           end
       end
    end
end

end
