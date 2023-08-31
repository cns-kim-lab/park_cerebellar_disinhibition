function done = task_replacer_for_pf(tgt_net,tid)
if nargin < 2 
    done = false;
    return
end

global mip_level mip_factor scaling_factor default_vol_overlap default_vol_size h_sql

mysql('close');
connsql();

mip_level=1;
mip_factor=[2 2 2].^mip_level;
scaling_factor=[1 1 4];
default_vol_overlap = [32 32 8];
default_vol_size = [512 512 128];

fraction_threshold=0.8;
size_threshold=100;

done = true;

[task_id, cell_id, volume_id, dpth, lft, rgt, notes, prgrs, stts, coordi] = mysql(h_sql, sprintf(...
    ['select id, cell_id, volume_id, depth, left_edge, right_edge, notes, progress, status, spawning_coordinate ' ...
    'from tasks where id=%d;'], tid));
count = 0;

for i=1:length(notes)
    [vx,vy,vz] = mysql(h_sql, sprintf(['select vx,vy,vz from volumes where id=%d'],volume_id(i)));
    new_vol  = mysql(h_sql, sprintf(['select id from volumes ' ...
        'where vx=%d && vy=%d && vz=%d && net_id="%s";'],vx,vy,vz,tgt_net));
    
    is_exist_tgt_net = ~isempty(new_vol);
    if ~is_exist_tgt_net        
        done = false;
        continue
    end
    
    segs = mysql(h_sql, sprintf(['select c.segments from consensuses as c join tasks as t ' ...
        'on t.id=c.task_id && c.version = t.latest_consensus_version where t.id=%d;'], task_id(i)));
    
    vol_id = volume_id(i);
    segments{1} = regexp(segs{1}, '\d*', 'Match');
    segments{1} = cellfun(@str2num,segments{1});
    seg_list = segments{1};
    
    % get this vol segmentation file name, coordinate and size 
    [this_vol_path,this_vol_size] = get_volume_info(vol_id);
    this_vol_seg_path = sprintf(...
        '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',this_vol_path,mip_level);
    this_vol_mip_size = this_vol_size./mip_factor;
    this_volc=read_volume(this_vol_seg_path,this_vol_mip_size);
    bw_traced_in_this_volc = ismember(this_volc, seg_list);
    
    [new_vol_path,new_vol_size] = get_volume_info(new_vol);
    new_vol_seg_path = sprintf(...
        '%s.files/segmentations/segmentation1/%d/volume.uint32_t.raw',new_vol_path,mip_level);
    new_vol_mip_size = new_vol_size./mip_factor;
    new_volc = read_volume(new_vol_seg_path, new_vol_mip_size);
    
    seg_corresponded = bw_traced_in_this_volc.*new_volc;
    new_seg = setdiff(seg_corresponded, 0);
    
    num_total_voxels_of_seg_in_volume = arrayfun( @(x) sum(new_volc(:)==x), new_seg );
    num_nwvol_voxels_of_seg_in_volume = arrayfun( @(x) sum(seg_corresponded(:)==x), new_seg );
    ratio = num_nwvol_voxels_of_seg_in_volume./num_total_voxels_of_seg_in_volume;
            
    idx = ratio > fraction_threshold & num_total_voxels_of_seg_in_volume>size_threshold; 
    new_seg2 = new_seg(idx);
    new_seg2_str = sprintf('%d ',new_seg2);
    
    rtn_step = mysql(h_sql, sprintf(['insert into tasks ' ...
        '(cell_id,volume_id,seeds,depth,left_edge,right_edge,created,progress,status,spawning_coordinate,notes) ' ...
        'values(%d, %d, "%s", %d, %d, %d, %s, %d, %d, "%s", "%s");'] ...
        ,cell_id(i), new_vol, new_seg2_str, dpth(i), lft(i), rgt(i), 'CURRENT_TIMESTAMP',0,stts(i),char(coordi(i)),['replaced_' tgt_net]));
    last_id = mysql(h_sql,'select last_insert_id();');
    write_log(sprintf('      create new task [%d] cell %d', last_id, cell_id(i)));
    
    rtn_step = mysql(h_sql, sprintf(['insert into consensuses ' ...
        '(task_id, user_id, comparison_group_id, segments, inspected, status) ' ...
        'values(%d, %d, %d, "%s", %d, %d);'] ...
        ,last_id, 5, 0, new_seg2_str, 0, 2));
    
    last_id_cons = mysql(h_sql,'select last_insert_id();');
    
    write_log(sprintf('      task [%d] cell %d is buried', task_id(i), cell_id(i)));
    
    rtn_step = mysql(h_sql, sprintf(['update tasks set status=4 where id=%d;'],task_id(i)));
    
    if stts(i)==2
        
        [rtn_exist,dup_seg_list] = find_exist_tasks_this(last_id, new_vol, new_seg2);
        [did, d_status, task1, task2, cns1, cns2, dup_segs] = isdup(task_id(i));
        
        for didi=1:length(did)
            
            if task1(didi)==task_id(i)
                
                cons_id1 = last_id_cons;
                cons_id2 = cns2(didi);
                
                if isempty(dup_seg_list)
                    new_dup_segs = '';
                else
                    rtn_i = find(dup_seg_list{3}==task2(didi));                    
                    new_dup_segs = dup_seg_list{4}{rtn_i};
                    new_dup_segs= sprintf('%d ', new_dup_segs);
                end
            
            elseif task2(didi)==task_id(i)
                
                cons_id1 = cns1(didi);
                cons_id2 = last_id_cons;
                
                [new_vol_rel, new_seg2_rel] = mysql(h_sql, sprintf(['select t.volume_id, c.segments ' ...
                    'from tasks as t join consensuses as c on ' ...
                    't.latest_consensus_version = c.version && t.id = c.task_id ' ...
                    'where t.id=%d;'], task1(didi)));
                
                new_seg2_rel{1} = regexp(new_seg2_rel{1}, '\d*', 'Match');
                new_seg2_rel{1} = cellfun(@str2num,new_seg2_rel{1});
                new_seg2_rel = new_seg2_rel{1};
                
                [rtn_exist_rel, dup_seg_list_rel] = find_exist_tasks_this(task1(didi), new_vol_rel, new_seg2_rel);
                
                if ~isempty(dup_seg_list_rel)
                    rtn_i = find(dup_seg_list_rel{3}==last_id);
                    new_dup_segs = dup_seg_list_rel{4}{rtn_i};
                    new_dup_segs = sprintf('%d ', new_dup_segs);
                end
                
            end
            
            rtn_step = mysql(sprintf('update duplications set status=2 where id=%d',did(didi)));
            rtn_step = mysql(h_sql,sprintf(['insert into duplications (consensus_id_1, ' ...
                'consensus_id_2, duplicated_segments, status) ' ...
                'values(%d,%d,"%s",%d)'],cons_id1,cons_id2,new_dup_segs,d_status(didi)));
        end
    end
    
    count = count + 1;
end
if done == false
    write_log(sprintf('      merged task exist, but %s volume for the task not exists.', tgt_net), 1);
end

write_log(sprintf('      %d tasks replaced (target=%s)', count, tgt_net));
mysql(h_sql, 'close');
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
