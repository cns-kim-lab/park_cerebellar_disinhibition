function doprune = check_prune_tasks(vol_id1, vol_id2, seg_list1, seg_list2)

global mip_level mip_factor scaling_factor default_vol_overlap default_vol_size h_sql

doprune = false;

mip_level=1;
mip_factor=[2 2 2].^mip_level;
scaling_factor=[1 1 4];
default_vol_overlap = [32 32 8];
default_vol_size = [512 512 128];

% get this vol segmentation file name, coordinate and size 
[spawned_vol_path,spawned_vol_size] = get_volume_info(vol_id1);
spawned_vol_seg_path = sprintf(...
    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',spawned_vol_path,mip_level);
spawned_vol_mip_size = spawned_vol_size./mip_factor;
spawned_volc=read_volume(spawned_vol_seg_path,spawned_vol_mip_size);

bw_traced_in_spawned_volc = ismember(spawned_volc, seg_list1);

[child_vol_path,child_vol_size] = get_volume_info(vol_id2);
child_vol_seg_path = sprintf(...
    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',child_vol_path,mip_level);
child_vol_mip_size = child_vol_size./mip_factor;
child_volc=read_volume(child_vol_seg_path,child_vol_mip_size);

bw_traced_in_child_volc = ismember(child_volc, seg_list2);

bw_corresponded = bw_traced_in_spawned_volc.* bw_traced_in_child_volc;
seg_corresponded = bw_corresponded.*child_volc;

fraction_threshold=0.5;
size_threshold=100;
        
%if a segment is included in branch more than x% and is larger than y, put this segment to result
num_total_voxels_of_seg_in_volume = arrayfun( @(x) sum(child_volc(:)==x), seg_list2 );
num_duppl_voxels_of_seg_in_volume = arrayfun( @(x) sum(seg_corresponded(:)==x), seg_list2 );
ratio = num_duppl_voxels_of_seg_in_volume./num_total_voxels_of_seg_in_volume;
            
idx = ratio > fraction_threshold & num_total_voxels_of_seg_in_volume>size_threshold; 
seg_list2_thresh = seg_list2(idx);
        
if isempty(seg_list2_thresh)
    doprune = true;
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



























































