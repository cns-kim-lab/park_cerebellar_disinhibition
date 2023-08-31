function [status, next_vol_seg_list, drct_vols_ijkid] = task_find_children(vol_id, seg_list)

% status: 0-normal, 1-no volume, 2-no exit
fraction_threshold=0.9;
size_threshold=27;
ovr_size_threshold = 7000;

status=cell(6,1);
next_vol_seg_list=cell(6,1);
drct_vols_ijkid = cell(6,1);

global mip_level mip_factor scaling_factor global_thresh default_vol_overlap default_vol_size tstcell h_sql

mip_level=0;
mip_factor=[2 2 2].^mip_level;
scaling_factor=[1 1 4];
default_vol_overlap = [32 32 8];
default_vol_size = [512 512 128];

% get this vol segmentation file name, coordinate and size 
[this_vol_path, this_vol_ijk, this_vol_coord,this_vol_size] = get_volume_info(vol_id);
this_vol_seg_path = sprintf(...
    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',this_vol_path,mip_level);
this_vol_mip_size = this_vol_size./mip_factor;

is_tasks_exist_in_next = true;
%for 6 directions 1:x+1, 2:x-1, 3:y+1, 4:y-1, 5:z+1, 6:z-1 
for search_direction=1:6    
%         net_priority = lrrtm3_get_net_priority(); %for test 
        net_priority = mysql(h_sql, 'select net_id from net_priority order by priority desc;')'; 
        [next_vol_id, next_vol_path, next_vol_ijk,next_vol_coord,next_vol_size] = ...
                get_next_volume_info(this_vol_ijk,search_direction,net_priority);
        if ~isempty(next_vol_id)
           drct_vols_ijkid{search_direction,1} = {[next_vol_ijk{1} next_vol_id]};
        end
        % if no seg file exists at all, return no volume for this direction
        if isempty(next_vol_path)
            status{search_direction}=1; 
            continue;
        end
        next_vol_coord = next_vol_coord{1};
        next_vol_size = next_vol_size{1};
        next_vol_mip_size=next_vol_size./mip_factor;
    
        overlap_size = get_overlap_size(this_vol_coord,this_vol_size,next_vol_coord,next_vol_size);
        overlap_mip_size = overlap_size./mip_factor;

        overlap_this_vol=read_overlap_slab(this_vol_seg_path,this_vol_mip_size,overlap_mip_size,search_direction);
        face=find_exit_face(overlap_this_vol,overlap_mip_size,search_direction);
        
        bw_traced_in_this_overlap = ismember(overlap_this_vol, seg_list);
        
        sig=-sign(this_vol_coord-next_vol_coord); 
        sig=sig(sig~=0); % +1 directon or -1 direction

        % if any input segment isn't in face, return no exiting branch
        if ~isempty(intersect(face(:),seg_list))
            status{search_direction}=0;
        else
            status{search_direction}=2; 
            continue;
        end    
        
        next_vol_ijk=get_next_vol_cube_axis_id(this_vol_ijk,search_direction);
        [task_id_next, task_seg_next, next_vols_path, next_net_ids] = mysql(h_sql, sprintf([ ...
            'select t.id, c.segments, v.path, v.net_id from tasks as t join volumes as v ' ...
            'on t.volume_id=v.id join consensuses as c on c.task_id=t.id && t.latest_consensus_version=c.version ' ...
            'where v.vx=%d && v.vy=%d && v.vz=%d && t.cell_id=%d && t.status=0;'], ...
            next_vol_ijk(1),next_vol_ijk(2),next_vol_ijk(3),tstcell));
        
        if isempty(task_id_next)
            
            next_vol_path = next_vol_path{1};
            next_vol_seg_path = sprintf( ...
                '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',next_vol_path,mip_level);
            
            overlap_next_vol = read_overlap_slab(next_vol_seg_path, next_vol_mip_size, overlap_mip_size, search_direction+sig);
            is_tasks_exist_in_next = false;
        else
            next_vols_path_unq = unique(next_vols_path);
            for i=1:length(next_vols_path_unq)
        
                next_vol_path = next_vols_path_unq{i};
                next_vol_seg_path = sprintf( ...
                    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',next_vol_path,mip_level);
        
                %overlap_next_vol = read_overlap_slab(next_vol_seg_path, next_vol_mip_size, overlap_mip_size, search_direction+sig);
                %[bw_traced_in_this_overlap, overlap_next_vols{i}] = ... 
                %equalize_no_seg_face(bw_traced_in_this_overlap, overlap_this_vol, overlap_next_vol);
                overlap_next_vols{i} = read_overlap_slab(next_vol_seg_path, next_vol_mip_size, overlap_mip_size, search_direction+sig);
            end
            is_tasks_exist_in_next = true;
            overlap_next_vol = overlap_next_vols{1};
        end
        [bw_traced_in_this_overlap, overlap_next_vol2] = equalize_no_seg_face(bw_traced_in_this_overlap, overlap_this_vol, overlap_next_vol);

        % find seg in next vol for each branch
        n_result=0;
        CC = bwconncomp(bw_traced_in_this_overlap);
        for k=1:CC.NumObjects
            %binary matrix, that have value 1 at this branch
            bw_this_branch=zeros(size(overlap_this_vol));
            bw_this_branch(CC.PixelIdxList{k})=1;

            %if this branch isn't on the exit face, continue to next branch
            face=find_exit_face(bw_this_branch,overlap_mip_size,search_direction);
            if nnz(face)==0
                continue;
            end
            
            is_branch_exist_in_next = false;
            count_branches_net_id = 0;
            if is_tasks_exist_in_next==true
                for i=1:length(task_id_next)
                    indc = strfind(next_vols_path_unq, next_vols_path{i});
                    ind = find(not(cellfun('isempty', indc)));
        
                    segments = regexp(task_seg_next{i}, '\d*', 'Match');
                    segments = cellfun(@str2num,segments);
        
                    bw_traced_in_next_overlap = ismember(overlap_next_vols{ind}, segments);
        
                    if ~isempty( setdiff( bw_this_branch.* bw_traced_in_next_overlap ,0) )
                        is_branch_exist_in_next = true;
                        exist_net_id = next_net_ids(i);
                        count_branches_net_id = count_branches_net_id + 1;
                    end
                end
                
                if count_branches_net_id > 1
                    is_branch_exist_in_next = false;
                end
                
                 if is_branch_exist_in_next == false
                    net_priority2 = net_priority;
                 else
                    net_priority2 = exist_net_id;
                 end
            
                [next_vol_id, next_vol_path, next_vol_ijk,next_vol_coord,next_vol_size] = ...
                    get_next_volume_info(this_vol_ijk,search_direction,net_priority2);
                if ~isempty(next_vol_id)
                    drct_vols_ijkid{search_direction,1}{end+1} = {[next_vol_ijk{1} next_vol_id]};
                end
                % if no seg file exists at all, return no volume for this direction
                if isempty(next_vol_path)
                    status{search_direction}=1; 
                    continue;
                end
                
                next_vol_path = next_vol_path{1};
                next_vol_ijk = next_vol_ijk{1};
                next_vol_coord = next_vol_coord{1};
                next_vol_size = next_vol_size{1};
                next_vol_seg_path = sprintf( ...
                    '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',next_vol_path,mip_level);
                
                overlap_next_vol = read_overlap_slab(next_vol_seg_path, next_vol_mip_size, overlap_mip_size, search_direction+sig);
                [bw_traced_in_this_overlap, overlap_next_vol2] = ...
                    equalize_no_seg_face(bw_traced_in_this_overlap, overlap_this_vol, overlap_next_vol);
                
            end
            
            corresponding_voxels_next_vol = overlap_next_vol2.*bw_this_branch;
            seg_list_next_vol = setdiff(corresponding_voxels_next_vol(:),0)';

            %if a segment is included in branch more than x% and is larger than y, put this segment to result
            num_total_voxels_of_seg_in_overlap = arrayfun( @(x) sum(overlap_next_vol2(:)==x), seg_list_next_vol );
            num_found_voxels_of_seg_in_overlap = arrayfun( @(x) sum(corresponding_voxels_next_vol(:)==x), seg_list_next_vol );
            ratio = num_found_voxels_of_seg_in_overlap./num_total_voxels_of_seg_in_overlap;
            
            idx = (ratio>fraction_threshold & num_total_voxels_of_seg_in_overlap>size_threshold) ...
                | (num_found_voxels_of_seg_in_overlap > ovr_size_threshold); 
                
            if all(idx)==false
                idx( num_found_voxels_of_seg_in_overlap == max(num_found_voxels_of_seg_in_overlap)) = true;
            end
            
            seg_list_next_vol = seg_list_next_vol(idx);
            num_total_voxels_of_seg_in_overlap = num_total_voxels_of_seg_in_overlap(idx);

            [~,idx]=max(num_total_voxels_of_seg_in_overlap);
            if ~isempty(idx)
                seg_list_next_vol([1,idx]) = seg_list_next_vol([idx,1]);
                num_total_voxels_of_seg_in_overlap([1,idx]) = num_total_voxels_of_seg_in_overlap([idx,1]);
                
                if ~exist('net_priority2','var')
                    net_priority2 = {''};
                end
                
                [sl, ss] = get_seglist_at_thresh(next_vol_path, seg_list_next_vol, global_thresh, net_priority2);
                seg_list_next_vol_extra = setdiff(sl, seg_list_next_vol);
                [~, IA, IB] = intersect(sl, seg_list_next_vol_extra);
                seg_size_next_vol_extra = zeros(size(seg_list_next_vol_extra));
                seg_size_next_vol_extra(IB) = ss(IA);
                
                n_result = n_result + 1;
                next_vol_seg_list{search_direction}{n_result}.vol = next_vol_id;
                next_vol_seg_list{search_direction}{n_result}.seg_list = [seg_list_next_vol seg_list_next_vol_extra];
                next_vol_seg_list{search_direction}{n_result}.seg_size = [num_total_voxels_of_seg_in_overlap seg_size_next_vol_extra];
                               
                %entering coord
                face = logical(find_exit_face(corresponding_voxels_next_vol, overlap_mip_size, search_direction+sig));
                face_ds = [0,0,0];
                if ~nnz(face)
                    [face,face_ds] = get_real_face(corresponding_voxels_next_vol,search_direction);
                end
                next_vol_seg_list{search_direction}{n_result}.entering_coord = ...
                    get_center(face, next_vol_coord, next_vol_size, search_direction+sig) - face_ds;
            end
        end
    
end

end

%%
function [rface,rface_ds] = get_real_face(corresponding_voxels_next_vol,search_direction)

rface=[];
rface_ds=0;

if search_direction==1
    
    volsum = sum(sum(corresponding_voxels_next_vol,2),3)';
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(1);
    rface(:,:) = logical(corresponding_voxels_next_vol(rface_ind,:,:));
    rface_ds = [rface_ind 0 0];
    
elseif search_direction==2
    
    volsum = sum(sum(corresponding_voxels_next_vol,2),3)';
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(end);
    rface(:,:) = logical(corresponding_voxels_next_vol(rface_ind,:,:));
    rface_ds = [length(volsum)-(rface_ind+1)+2 0 0];
    
elseif search_direction==3
    
    volsum = sum(sum(corresponding_voxels_next_vol,1),3)';
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(1);
    rface(:,:) = logical(corresponding_voxels_next_vol(:,rface_ind,:));
    rface_ds = [0 rface_ind 0];
    
elseif search_direction==4
    
    volsum = sum(sum(corresponding_voxels_next_vol,1),3)';
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(end);
    rface(:,:) = logical(corresponding_voxels_next_vol(:,rface_ind,:));
    rface_ds = [0 length(volsum)-(rface_ind+1)+2 0];
    
elseif search_direction==5
    
    volsum = sum(sum(corresponding_voxels_next_vol,1),2);
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(1);
    rface(:,:) = logical(corresponding_voxels_next_vol(:,:,rface_ind));
    rface_ds = [0,0,rface_ind];
    
elseif search_direction==6
    
    volsum = sum(sum(corresponding_voxels_next_vol,1),2);
    non_zero_surf_ind = find(volsum~=0);
    rface_ind = non_zero_surf_ind(end);
    rface(:,:) = logical(corresponding_voxels_next_vol(:,:,rface_ind));
    rface_ds = [0,0,length(volsum)-(rface_ind+1)+2];
    
end


end


%%
function [seg_list, seg_size] = get_seglist_at_thresh(vol_path, seed_seg_id, thresh, net_id)

mst_file_name = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst_mean.data',vol_path);

%if ~exist(mst_file_name,'file') || ~isempty( strmatch(char(net_id{1}),'C1a','exact') )
%    mst_file_name = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst.data',vol_path);
%end

if ~exist(mst_file_name,'file')
    mst_file_name = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst.data',vol_path);
end

mst = omni_read_mst(mst_file_name);

mst = [[mst.node1]' [mst.node2]' [mst.affin]'];
mst = mst(mst(:,3)>thresh, 1:3);

max_node = max([mst(:,1); mst(:,2)]);
max_node = max(max_node, max(seed_seg_id));

[~,idx]=sort(mst(:,3),'descend');

cluster_id_of_node = 1:max_node;

for i=1:numel(idx)

    node1 = mst(idx(i),1);
    node2 = mst(idx(i),2);
    
    cluster1 = cluster_id_of_node(node1);
    cluster2 = cluster_id_of_node(node2);
    
    cluster_id_of_node(cluster_id_of_node==cluster2) = cluster1;
    
end
seg_list=[];
seg_size=[];
if ~isempty(cluster_id_of_node)

    cluster_id_of_seed = cluster_id_of_node(seed_seg_id);
    seg_list = find(ismember(cluster_id_of_node, cluster_id_of_seed));

    [seg_list, seg_size] = omni_read_segment_size(vol_path, seg_list);
end
    

end


%%
function next_vol_ijk=get_next_vol_cube_axis_id(this_vol_ijk,search_direction)

xid1 = this_vol_ijk(1); 
yid1 = this_vol_ijk(2);
zid1 = this_vol_ijk(3);

xid2 = xid1; yid2 = yid1; zid2 = zid1;
if search_direction==1; xid2 = xid1+1;
elseif search_direction==2; xid2 = xid1-1;
elseif search_direction==3; yid2 = yid1+1;
elseif search_direction==4; yid2 = yid1-1;
elseif search_direction==5; zid2 = zid1+1;
elseif search_direction==6; zid2 = zid1-1;
end

next_vol_ijk = [xid2,yid2,zid2];
    
end

%%    
%get mipmap information from volume_id
function [fn, ijk, loc, sz] = get_volume_info(vol_id)

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
function [next_vols_id, next_vols_path,next_vols_ijk,next_vols_coord,next_vols_size] = ...
        get_next_volume_info(this_vol_ijk,search_direction,net_priority)
global h_sql    

next_vols_path=[]; next_vols_ijk=[]; next_vols_coord=[]; next_vols_size=[];
next_vol_ijk = get_next_vol_cube_axis_id(this_vol_ijk,search_direction);

n_vols=0; 
for p=1:length(net_priority)

    net_id = net_priority{p};
    next_vols_id = mysql(h_sql, sprintf(['select id from volumes' ...
        ' where net_id="%s" && vx=%d && vy=%d && vz=%d;'], ...
        net_id, next_vol_ijk(1), next_vol_ijk(2), next_vol_ijk(3)));
    
    if ~isempty(next_vols_id)
        [fn2, ijk2,loc2, sz2]=get_volume_info(next_vols_id);
        n_vols=n_vols+1;
        next_vols_ijk{n_vols}=ijk2;
        next_vols_path{n_vols}=fn2;
        next_vols_coord{n_vols}=loc2;
        next_vols_size{n_vols}=sz2;
        break;
    end
    
end
    
end



%%
function overlap_size = get_overlap_size(this_vol_coord,this_vol_size,next_vol_coord,next_vol_size)

global scaling_factor

this_vol_size = this_vol_size.*scaling_factor;
x1 = this_vol_coord(1):(this_vol_coord(1)+this_vol_size(1)-1); 
y1 = this_vol_coord(2):(this_vol_coord(2)+this_vol_size(2)-1); 
z1 = this_vol_coord(3):(this_vol_coord(3)+this_vol_size(3)-1); 

next_vol_size = next_vol_size.*scaling_factor;
x2 = next_vol_coord(1):(next_vol_coord(1)+next_vol_size(1)-1); 
y2 = next_vol_coord(2):(next_vol_coord(2)+next_vol_size(2)-1); 
z2 = next_vol_coord(3):(next_vol_coord(3)+next_vol_size(3)-1); 

overlap_size = [ numel(intersect(x1,x2)), numel(intersect(y1,y2)), numel(intersect(z1,z2))]./scaling_factor;

end


%%
function face = find_exit_face(slab, szm, drct)

if drct==1 
    face = slab(szm(1),:,:);
    if all(~face)
        face = slab(szm(1)-1,:,:); 
    end            
elseif drct==2 
    face = slab(1,:,:);
    if all(~face)
        face = slab(2,:,:); 
    end 
elseif drct==3 
    face = slab(:,szm(2),:);
    if all(~face)
        face = slab(:,szm(2)-1,:); 
    end 
elseif drct==4 
    face = slab(:,1,:);
    if all(~face)
        face = slab(:,2,:); 
    end
elseif drct==5 
    face = slab(:,:,szm(3));
    if all(~face)
        face = slab(:,:,szm(3)-1); 
    end
elseif drct==6 
    face = slab(:,:,1);
    if all(~face)
        face = slab(:,:,2); 
    end
end

face=squeeze(face);
    
end

%%
function ovc = read_overlap_slab(filename,sz,ovs,drct)

cs = 128;
ovc = zeros([ovs(1) ovs(2) ovs(3)]);

fid = fopen(filename,'r');
xth = sz(1)/cs; yth = sz(2)/cs;

if drct==1
    n=1;
    for j=1:yth
        for z=1:ovs(3)
            for y=1:cs
                ofs = (j-1)*xth*(cs^3) + (cs^3)*(xth-1) + ...
                    (z-1)*(cs^2) + (y-1)*cs + (cs-ovs(1));
                fseek(fid,ofs*4,-1);
                rowarr = fread(fid,ovs(1),'uint32');
                ovc(:,cs*(j-1)+y,z) = rowarr;
                n=n+1;
            end
        end
    end
elseif drct==2
    n=1;
    for j=1:yth
        for z=1:ovs(3)
            for y=1:cs
                ofs = (j-1)*xth*(cs^3) + ...
                    (z-1)*(cs^2) + (y-1)*cs;
                fseek(fid,ofs*4,-1);
                rowarr = fread(fid,ovs(1),'uint32');
                ovc(:,cs*(j-1)+y,z) = rowarr;
                n=n+1;
            end
        end
    end
elseif drct==3
    n=1;
    for i=1:xth
        for z=1:ovs(3)
            ofs = (yth-1)*(xth)*(cs^3) + (i-1)*(cs^3) + ...
                (z-1)*(cs^2) + cs*(cs-ovs(2));
            fseek(fid,ofs*4,-1);
            rowarr = fread(fid,cs*ovs(2),'uint32');
            ovc((i-1)*cs+1:i*cs,:,z) = reshape(rowarr,[cs,ovs(2),1]);
            n=n+1;
        end
    end
elseif drct==4
    n=1;
    for i=1:xth
        for z=1:ovs(3)
            ofs = (i-1)*(cs^3) + ...
                (z-1)*(cs^2);
            fseek(fid,ofs*4,-1);
            rowarr = fread(fid,cs*ovs(2),'uint32');
            ovc((i-1)*cs+1:i*cs,:,z) = reshape(rowarr,[cs,ovs(2),1]);
            n=n+1;
        end
    end
elseif drct==5
    n=1;
    for j=1:yth
        for i=1:xth
            fseek(fid,((n-1)*(cs*cs*cs) + cs*cs*(sz(3)-ovs(3)))*4,-1);
            rowarr = fread(fid,cs*cs*ovs(3),'uint32');
            ovc(1+cs*(i-1):cs*i,1+cs*(j-1):cs*j,:) = reshape(rowarr,[cs,cs,ovs(3)]);
            n=n+1;
        end
    end
elseif drct==6
    n=1;
    for j=1:yth
        for i=1:xth
            fseek(fid,(n-1)*(cs*cs*cs)*4,-1);
            rowarr = fread(fid,cs*cs*ovs(3),'uint32');
            ovc(1+cs*(i-1):cs*i,1+cs*(j-1):cs*j,:) = reshape(rowarr,[cs,cs,ovs(3)]);
            n=n+1;
        end
    end

end
fclose(fid);

end
%%
function center = get_center(face, next_vol_coord, next_vol_size, search_direction)

if ~nnz(face)
    center = [0, 0, 0];
    return;
end
    
global scaling_factor mip_factor 

face_center = regionprops(face, 'Centroid'); 
face_area = struct2array(regionprops(face, 'Area'));
[~,max_area_idx]=max(face_area);      
face_center = flip(round(face_center(max_area_idx).Centroid));

%for 6 directions 1:x+1, 2:x-1, 3:y+1, 4:y-1, 5:z+1, 6:z-1 
switch search_direction
    case 1
        center = next_vol_coord + [next_vol_size(1)-1, 0, 0] + [0, face_center(1), face_center(2)].*scaling_factor.*mip_factor;
    case 2
        center = next_vol_coord + [0                 , 0, 0] + [0, face_center(1), face_center(2)].*scaling_factor.*mip_factor;
    case 3
        center = next_vol_coord + [0, next_vol_size(2)-1, 0] + [face_center(1), 0, face_center(2)].*scaling_factor.*mip_factor;
    case 4
        center = next_vol_coord + [0, 0,                  0] + [face_center(1), 0, face_center(2)].*scaling_factor.*mip_factor;
    case 5
        center = next_vol_coord + [0, 0, next_vol_size(3)-1] + [face_center(1), face_center(2), 0].*scaling_factor.*mip_factor;
    case 6
        center = next_vol_coord + [0, 0,                  0] + [face_center(1), face_center(2), 0].*scaling_factor.*mip_factor;
end
                
end

%%
function [bw_traced_in_this_overlap,overlap_next_vol2]=equalize_no_seg_face(bw_traced_in_this_overlap,overlap_this_vol,overlap_next_vol)

overlap_next_vol2 = overlap_next_vol;

if all(all(overlap_this_vol(1,:,:)==0)) || all(all(overlap_next_vol(1,:,:)==0))
    bw_traced_in_this_overlap(1,:,:)=0; 
    overlap_next_vol2(1,:,:)=0; 
end

if all(all(overlap_this_vol(end,:,:)==0)) || all(all(overlap_next_vol(end,:,:)==0))
    bw_traced_in_this_overlap(end,:,:)=0; 
    overlap_next_vol2(end,:,:)=0; 
end

if all(all(overlap_this_vol(:,1,:)==0)) || all(all(overlap_next_vol(:,1,:)==0))
    bw_traced_in_this_overlap(:,1,:)=0; 
    overlap_next_vol2(:,1,:)=0; 
end

if all(all(overlap_this_vol(:,end,:)==0)) || all(all(overlap_next_vol(:,end,:)==0))
    bw_traced_in_this_overlap(:,end,:)=0; 
    overlap_next_vol2(:,end,:)=0; 
end

if all(all(overlap_this_vol(:,:,1)==0)) || all(all(overlap_next_vol(:,:,1)==0))
    bw_traced_in_this_overlap(:,:,1)=0; 
    overlap_next_vol2(:,:,1)=0; 
end

if all(all(overlap_this_vol(:,:,end)==0)) || all(all(overlap_next_vol(:,:,end)==0))
    bw_traced_in_this_overlap(:,:,end)=0; 
    overlap_next_vol2(:,:,end)=0; 
end

end
