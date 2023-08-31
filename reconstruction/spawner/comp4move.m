function rtn_comparison = comp4move(cell_id)
addpath /data/research/bahn/code/mysql/
mysql('close');
global h_sql system_user_id fid

%{
h_sql = mysql('open','10.1.26.181','root','1234');
%h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
mysql(h_sql, 'use omni');
%}
connsql();

system_user_id = mysql(h_sql, sprintf('select id from users where name="%s";', 'system'));

log_dir = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_migration/';
%log_dir = '/data/research/bahn/code/log/';
clck=floor(clock);
log_file_name = sprintf('comp4move_cell%d_%d-%d-%d',cell_id,clck(1:3));
log_path = [log_dir log_file_name];
fid = fopen(log_path,'a+');
clcks=sprintf('%04d/%02d/%02d. %02d:%02d:%02d ',clck);
fprintf(fid,'\n\n\ntest time : %s\n',clcks);
fprintf('\n\n\ntest time : %s\n',clcks);

isdone = false;
n=0;
while isdone==false
    n=n+1
    fprintf(fid,'\n\n\ntime : %s\n',clcks);
    fprintf('\n\n\ntime : %s\n',clcks);

    [task_id, pth, validation_id, user_id, segments] = mysql(h_sql, ...
        sprintf('call spwn_get_vals4cmp4cmp(%d);',cell_id));
    if isempty(task_id)
        isdone = true;
        fprintf(fid,'\nno more validation pair to compare');
        fprintf('\nno more validation pair to compare');
        continue;
    end
    
    task_id = task_id(1); 
    pth = char(pth(1));
    for i=1:numel(segments)
        segments{i} = regexp(segments{i}, '\d*', 'Match');
        segments{i} = cellfun(@str2num,segments{i});
    end

    [rtn_cpr, rst_cell] = compare_tasks(task_id, pth, validation_id, user_id, segments);
    mysql(h_sql,'start transaction;');
    rtn_add = add_comparison_task(task_id, rst_cell);
    mysql(h_sql,'commit;');
    
end
rtn_comparison=1;
disp('done comparison')

num_task = mysql(h_sql,sprintf('select count(id) from tasks where cell_id=%d;',cell_id));
num_comp = mysql(h_sql,sprintf('select count(v.id) from comparisons as v join tasks as t on v.task_id=t.id where t.cell_id=%d;',cell_id));
num_x_cons = mysql(h_sql, sprintf(['select count(v.id) from consensuses as v join tasks as t on v.task_id=t.id ' ...
    'where v.comparison_group_id=0 && cell_id=%d;'],cell_id));
num_x_task = mysql(h_sql, sprintf('select count(id) from tasks where comparison_group_id=0 && cell_id=%d;',cell_id));

fprintf(fid,'\nnumber of tasks = %d\n',num_task);
fprintf(fid,'number of comparisons = %d\n',num_comp);
fprintf(fid,'number of tasks not linked = %d\n',num_x_task);
fprintf(fid,'number of consensuses not linked = %d\n',num_x_cons);

mysql(h_sql,'close');
end
%%
function [rtn, rst_cell] = compare_tasks(task_id, pth, validation_id, user_id, segments)

%rtn 0:not comparison task, 1:agreed&error. 2:perfect
rtn = 0; rst_cell = cell(4,3);

global size_of_chunk size_of_uint32 size_of_chunk_linear fid
size_of_uint32=4;
size_of_chunk=[128 128 128];
size_of_chunk_linear=prod(size_of_chunk);
mip_level=1;
mip_factor=2^mip_level;

%[pth, validation_id, user_id, segments] = get_task_information(task_id);
nums = regexp(char(pth), '\d*', 'Match');
vol_size = cellfun(@str2num,nums(end-2:end));

user1 = num2str(user_id(1));
user2 = num2str(user_id(2));

fprintf(fid,'\n(task_id:%d)Comparing task for user %s&%s(id)... ',task_id,user1,user2);
fprintf('\n(task_id:%d)Comparing task for user %s&%s(id)... ',task_id,user1,user2);

rst_cell{1,3} = validation_id(1);
rst_cell{2,3} = validation_id(1);
rst_cell{3,3} = validation_id(2);
rst_cell{4,3} = validation_id(1);

seg_list_of_user1 = segments{1};
seg_list_of_user2 = segments{2};

% get overlap and the rest of it
seg_list_common=intersect(seg_list_of_user1,seg_list_of_user2);
seg_list_error1=setdiff(seg_list_of_user1,seg_list_common); % 1 only have
seg_list_error2=setdiff(seg_list_of_user2,seg_list_common); % 2 only have

%
% find conncomp of error segments for each user
if (~isempty(seg_list_error1) || ~isempty(seg_list_error2))

    path_file_segmentation=...
        sprintf('.files/segmentations/segmentation1/%d/volume.uint32_t.raw',mip_level);
    path_of_vol_seg = [pth path_file_segmentation];
    mip_vol_size = vol_size./mip_factor;
    vol_segmentation=get_vol_segmentation(path_of_vol_seg, mip_vol_size);

    list_seg_in_cc_error1 = {};
    list_seg_in_cc_error2 = {};
    if (~isempty(seg_list_error1))
        bw_err_seg1=ismember(vol_segmentation,seg_list_error1);
        cc_error1=bwconncomp(bw_err_seg1,26);
        size_cc_error1=(cellfun(@(x) numel(x),cc_error1.PixelIdxList))';
        list_seg_in_cc_error1=cellfun(@(x) unique(vol_segmentation(x)),cc_error1.PixelIdxList,'UniformOutput',false);        
    end
    
    if (~isempty(seg_list_error2))
        bw_err_seg2=ismember(vol_segmentation,seg_list_error2);
        cc_error2=bwconncomp(bw_err_seg2,26);
        size_cc_error2=(cellfun(@(x) numel(x),cc_error2.PixelIdxList))';
        list_seg_in_cc_error2=cellfun(@(x) unique(vol_segmentation(x)),cc_error2.PixelIdxList,'UniformOutput',false);                        
    end
    
    [unq,~,idq] = unique([cell2mat(list_seg_in_cc_error1(:));cell2mat(list_seg_in_cc_error2(:))]); 
    not_unique_cc_seg = unq(accumarray(idq(:),1)>1);

    size_selected_seg_user1=sum(ismember(vol_segmentation(:),seg_list_of_user1));
    size_selected_seg_user2=sum(ismember(vol_segmentation(:),seg_list_of_user2));
    size_selected_seg_common=sum(ismember(vol_segmentation(:),seg_list_common));
    size_selected_seg_total=size_selected_seg_user1+size_selected_seg_user2-size_selected_seg_common;    

end

if (~isempty(seg_list_error1) || ~isempty(seg_list_error2))
    
    rst_cell{1,2} = [rst_cell{1,2} sprintf('%.2f ', ...
        (size_selected_seg_common/size_selected_seg_total)*100)];
    rst_cell{1,1} = [rst_cell{1,1} sprintf('%d ',seg_list_common)];

    i2=1;i3=1;i4=1;
    dust_size = 0;
    dust_voxel_thresh = 8;
    dust_fraction_thresh = 0.1;
    if (exist('size_cc_error1','var'))
        [~,idx_cc_error1_sorted_by_size]=sort(size_cc_error1,'descend');
        for i=1:numel(size_cc_error1)
            seg_cc_voxels = size_cc_error1(idx_cc_error1_sorted_by_size(i));
            seg_cc_size = seg_cc_voxels/size_selected_seg_total*100;
            if seg_cc_size > dust_fraction_thresh && seg_cc_voxels > dust_voxel_thresh
                if i2~=1 rst_cell{2,1} = [rst_cell{2,1} sprintf('; ')];
                    rst_cell{2,2} = [rst_cell{2,2} sprintf('; ')]; end
                rst_cell{2,2} = [rst_cell{2,2} sprintf('%.2f ',size_cc_error1(idx_cc_error1_sorted_by_size(i))/size_selected_seg_total*100)];
                rst_cell{2,1} = [rst_cell{2,1} sprintf('%d ',list_seg_in_cc_error1{idx_cc_error1_sorted_by_size(i)})];
                i2 = i2+1;
            else
                dust_seg = list_seg_in_cc_error1{idx_cc_error1_sorted_by_size(i)};
                [~,ll] = intersect(dust_seg,not_unique_cc_seg);
                dust_seg(ll) = [];
                if numel(dust_seg)>0
                    rst_cell{4,1} = [rst_cell{4,1} sprintf('%d ', dust_seg)];
                    dust_size = dust_size + seg_cc_size;
                end
                i4 = i4 +1;
            end
        end
    end

    if (exist('size_cc_error2','var'))
        [~,idx_cc_error2_sorted_by_size]=sort(size_cc_error2,'descend');
        for i=1:numel(size_cc_error2)
            seg_cc_voxels = size_cc_error2(idx_cc_error2_sorted_by_size(i));
            seg_cc_size = seg_cc_voxels/size_selected_seg_total*100;
            if seg_cc_size > dust_fraction_thresh && seg_cc_voxels > dust_voxel_thresh
                if i3~=1 rst_cell{3,1} = [rst_cell{3,1} sprintf('; ')];
                    rst_cell{3,2} = [rst_cell{3,2} sprintf('; ')]; end
                rst_cell{3,2} = [rst_cell{3,2} sprintf('%.2f ',size_cc_error2(idx_cc_error2_sorted_by_size(i))/size_selected_seg_total*100)];
                rst_cell{3,1} = [rst_cell{3,1} sprintf('%d ',list_seg_in_cc_error2{idx_cc_error2_sorted_by_size(i)})];
                i3=i3+1;
            else
                dust_seg = list_seg_in_cc_error2{idx_cc_error2_sorted_by_size(i)};
                [~,ll] = intersect(dust_seg,not_unique_cc_seg);
                dust_seg(ll) = [];
                if numel(dust_seg)>0
                    rst_cell{4,1} = [rst_cell{4,1} sprintf('%d ', dust_seg)];
                    dust_size = dust_size + seg_cc_size;
                end
                i4=i4+1;
            end
        end
    end
    
    rst_cell{4,2} = [rst_cell{4,2} sprintf('%.2f ', dust_size)];
    if isempty(rst_cell{2,1}) && isempty(rst_cell{3,1}) && isempty(rst_cell{4,1})
        rst_cell{1,2} = [sprintf('%.2f ', 100)];
        rst_cell{1,1} = [sprintf('%d ',seg_list_common)];
        rst_cell{2,2} = [sprintf('%.2f ', 0)];
        rst_cell{3,2} = [sprintf('%.2f ', 0)];
        rst_cell{4,2} = [sprintf('%.2f ', 0)];
        rtn = 2;
        fprintf(fid,'Agreed %.2f %%\n\n', 100);
        fprintf('Agreed %.2f %%\n\n', 100);
    
    else
        rtn = 1;
        fprintf(fid,'Agreed %.2f %%\n\n',(size_selected_seg_common/size_selected_seg_total)*100);
        fprintf('Agreed %.2f %%\n\n',(size_selected_seg_common/size_selected_seg_total)*100);
    end
else
    rst_cell{1,2} = [rst_cell{1,2} sprintf('%.2f ', 100)];
    rst_cell{1,1} = [rst_cell{1,1} sprintf('%d ',seg_list_common)];
    rst_cell{2,2} = [rst_cell{2,2} sprintf('%.2f ', 0)];
    rst_cell{3,2} = [rst_cell{3,2} sprintf('%.2f ', 0)];
    rst_cell{4,2} = [rst_cell{4,2} sprintf('%.2f ', 0)];
    rtn = 2;
    fprintf(fid,'Agreed %.2f %%\n\n', 100);
    fprintf('Agreed %.2f %%\n\n', 100);
end




end

%%
function vol = get_vol_segmentation(path_vol_segmentation, mip_vol_size)

global size_of_chunk size_of_uint32 size_of_chunk_linear fid

mip_vol_size_in_chunks=ceil(mip_vol_size./size_of_chunk);
mip_vol_size=mip_vol_size_in_chunks.*size_of_chunk;
vol=zeros(mip_vol_size,'uint32');

fp=fopen(path_vol_segmentation,'r');

for x=1:mip_vol_size_in_chunks(1)
    for y=1:mip_vol_size_in_chunks(2)
        for z=1:mip_vol_size_in_chunks(3)
            sub=[x y z];
            idx_chunk=sub2ind(mip_vol_size_in_chunks,sub(1),sub(2),sub(3));
            offset=(size_of_uint32*(idx_chunk-1)*size_of_chunk_linear);
            fseek(fp,offset,'bof');
            chunk=reshape(fread(fp,size_of_chunk_linear,'*uint32'),size_of_chunk);
            st=([x y z]-1).*size_of_chunk+1;
            ed=([x y z]).*size_of_chunk;
            vol(st(1):ed(1),st(2):ed(2),st(3):ed(3))=chunk;
        end
    end
end
fclose(fp);

vol = vol(1:mip_vol_size(1), 1:mip_vol_size(2), 1:mip_vol_size(3));

end

%%
function rtn = add_comparison_task(task_id, rst_cell)
global h_sql fid
rtn=0;


num_seg_group=4;

idmx = mysql(h_sql, sprintf('select max(id) from comparisons;'));
if isnan(idmx)==1
    group_id=0;
else
    group_id=idmx+1;
end

rtn_step = mysql(h_sql, sprintf(['update tasks set progress=5, comparison_group_id=%d where id=%d;'], group_id,task_id));
rtn_step = mysql(h_sql, sprintf(['update consensuses set comparison_group_id=%d where task_id=%d;'], group_id,task_id));

for i=1:num_seg_group
    
    if i==1; type=0; elseif i==4; type=2; else; type=1; end
    rtn_add_comp = mysql(h_sql, ... 
        sprintf(['insert into comparisons ' ...
            '(task_id, group_id, validations_id,segment_groups,segment_group_sizes,type) '...
            'values(%d,%d,%d,"%s","%s",%d);'], ...
            task_id,group_id,rst_cell{i,3}, rst_cell{i,1}, rst_cell{i,2}, type)); 

    if rtn_add_comp==1
        
        last_id = mysql(h_sql,'select last_insert_id();');
        
        fprintf(fid,'(comp_id:%d)insert into comparisons for task_id=%d, validation_id=%d, type=%d\n', ...
            last_id,task_id, rst_cell{i,3}, type);
        fprintf('(comp_id:%d)insert into comparisons for task_id=%d, validation_id=%d, type=%d\n', ...
            last_id,task_id, rst_cell{i,3}, type);
    else
        fprintf(fid,'can not insert into comparisons for task_id=%d, validation_id=%d, type=%d\n', ...
            task_id, rst_cell{i,3}, type);
        fprintf('can not insert into comparisons for task_id=%d, validation_id=%d, type=%d\n', ...
            task_id, rst_cell{i,3}, type);
        %set task progress to 2 (trace done)
        rtn_step = mysql(h_sql, sprintf(['update tasks set progress=2 && status=1 where id=%d;'],task_id));
        return
    end
    
end

rtn_step = mysql(h_sql, sprintf(['update validations set inspected=1 where task_id=%d;'],task_id));
rtn = 1;

end


%%
































