function [rtn_exist, dup_seg_list] = find_exist_tasks(vol_id, seg_list, seg_size)

global mip_level mip_factor scaling_factor default_vol_overlap default_vol_size h_sql

rtn_exist=0;
dup_seg2=[];

[sv_cell, sv_con_id, sv_task_id, sv_seg, task_st] = mysql(h_sql, sprintf([...
    'select tasks.cell_id, consensuses.id, consensuses.task_id, consensuses.segments, tasks.status ' ...
    'from consensuses join tasks on consensuses.task_id=tasks.id && ' ...
    'consensuses.version=tasks.latest_consensus_version ' ...
    'where tasks.volume_id=%d;' ...
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
    end
end

[vx,vy,vz] = mysql(h_sql, sprintf(['select vx,vy,vz from volumes where id=%d;'],vol_id));
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
[this_vol_path,this_vol_size] = get_volume_info(vol_id);
this_vol_seg_path = sprintf(...
    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',this_vol_path,mip_level);
this_vol_mip_size = this_vol_size./mip_factor;

this_volc=read_volume(this_vol_seg_path,this_vol_mip_size);

bw_traced_in_this_volc = ismember(this_volc, seg_list);
vol_id_diff = mysql(h_sql, sprintf(['select id from volumes where vx=%d && vy=%d && vz=%d && id!=%d'],vx,vy,vz,vol_id));

fraction_threshold=0.8;
size_threshold=12;

for vv=1:numel(vol_id_diff)

    [sv_cell, sv_con_id, sv_task_id, sv_seg, task_st] = mysql(h_sql, sprintf([...
        'select tasks.cell_id, consensuses.id, consensuses.task_id, consensuses.segments, tasks.status ' ...
        'from consensuses join tasks on consensuses.task_id=tasks.id && ' ...
        'consensuses.version=tasks.latest_consensus_version ' ...
        'where tasks.volume_id=%d;' ...
        ],vol_id_diff(vv)));
    
    if isempty(sv_task_id)
        continue 
    end
    
    sv_seg = regexp(sv_seg, '\d*', 'Match');
    
    [dup_vol_path,dup_vol_size] = get_volume_info(vol_id_diff(vv));
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
        end
            
    end
    
end

if ~isempty(dup_seg_list)
    rtn_exist = 1;
end

end

%%    
%get mipmap information from volume_id
function [fn, sz] = get_volume_info(vol_id)

fn=[]; loc=[]; sz=[];

global scaling_factor default_vol_overlap default_vol_size h_sql

%need path,vx,vy,vz
[pth,vx,vy,vz] = mysql(h_sql, sprintf('select path,vx,vy,vz from volumes where id=%d',vol_id));

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
%%


























































