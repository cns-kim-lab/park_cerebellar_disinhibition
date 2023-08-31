function rtn_spawn = spawn_test(test_cell, gthresh, max_add_task,test_task_id,force2)

switch nargin
    case 3
        test_mode = 1;
    case 4
        test_mode = 2;
        force2=0;
    case 5
        test_mode = 2;
    otherwise
        test_mode = 0;
end

addpath /data/research/bahn/code/mysql/
mysql('close'); 
global h_sql global_thresh system_user_id count_new fid
%{
h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
%h_sql = mysql('open','10.1.26.181','root','1234');
%mysql(h_sql, 'use omni0714');
mysql(h_sql, 'use omni');
%}
connsql();

system_user_id = mysql(h_sql, sprintf('select id from users where name="%s";', 'system'));

log_dir = '/data/lrrtm3_wt_omnivol/cell_trace_data/log/';
%log_dir = '/data/research/bahn/homework/code/spawn/log/';
clck=floor(clock);
log_file_name = sprintf('spawn_test_cell%d_%d-%d-%d',test_cell,clck(1:3));
log_path = [log_dir log_file_name];
fid = fopen(log_path,'a+');
%fid=1;
clcks=sprintf('%04d/%02d/%02d. %02d:%02d:%02d ',clck);
fprintf(fid,'\ntest time : %s\n',clcks);
%fprintf('\n\n\ntest time : %s\n',clcks);

count_new = 0;

isdone = false;
while isdone==false && count_new<max_add_task
    
    fprintf(fid,'\ntime : %s\n',clcks);
    %fprintf('\n\n\ntime : %s\n',clcks);
    
    if(test_mode==2)
        if force2==1
            rtn = mysql(h_sql, sprintf(['update consensuses as c join tasks as t ' ...
                'on c.task_id=t.id && c.version=t.latest_consensus_version ' ...
                'set inspected=0 where t.id=%d;'], test_task_id));
            force2=0;
        end
        %get consensus to spawn
        [cons_id, task_id,cell_id,task_prg,volume_id,segments,t_depth,t_left,t_right,tstatus] = mysql(h_sql, ...
            sprintf(['select consensuses.id, consensuses.task_id, tasks.cell_id, ' ...
            'tasks.progress, tasks.volume_id, consensuses.segments, ' ...
            'tasks.depth, tasks.left_edge, tasks.right_edge, tasks.status ' ...
            'from consensuses join tasks ' ...
            'on consensuses.task_id = tasks.id ' ...
            '&& consensuses.version = tasks.latest_consensus_version ' ...
            'where consensuses.inspected=0 && (tasks.status=0 || tasks.status=2) && tasks.cell_id=%d && tasks.id=%d ' ...
            'order by id desc limit 1;'],test_cell,test_task_id));
    else
        %get consensus to spawn
        [cons_id, task_id,cell_id,task_prg,volume_id,segments,t_depth,t_left,t_right,tstatus] = mysql(h_sql, ...
            sprintf(['select consensuses.id, consensuses.task_id, tasks.cell_id, ' ...
            'tasks.progress, tasks.volume_id, consensuses.segments, ' ...
            'tasks.depth, tasks.left_edge, tasks.right_edge, tasks.status ' ...
            'from consensuses join tasks ' ...
            'on consensuses.task_id = tasks.id ' ...
            '&& consensuses.version = tasks.latest_consensus_version ' ...
            'where consensuses.inspected=0 && (tasks.status=0 || tasks.status=2) && tasks.cell_id=%d ' ...
            'order by id desc limit 1;'],test_cell));
    end
    %{
    if(tstatus==2)
        rtn_step = mysql(h_sql,sprintf('update tasks set status=0 where id=%d;',task_id));
        rtn_step = mysql(h_sql,sprintf('update duplications set status=1 where consensus_id_1=%d || consensus_id_2=%d;',cons_id,cons_id));
    end
    %}
    did = isdup(task_id);
    if ~isempty(did)
        rtn_step = mysql(h_sql,sprintf('update tasks set status=0 where id=%d;',task_id));
        for q=1:length(did)
            rtn_step = mysql(h_sql,sprintf('update duplications set status=1 where id=%d;', did(q)));
        end
    end
    
    if isempty(cons_id)
        isdone = true;
        fprintf(fid,'\nno more consensuses to spawn');
        fprintf('\nno more consensuses to spawn');
        continue;
    end
    
    segments{1} = regexp(segments{1}, '\d*', 'Match');
    segments{1} = cellfun(@str2num,segments{1});
    segments = segments{1};
    
    fprintf(fid,'\n[%d] spawning ... \n',task_id);
    fprintf('\n[%d] spawning ... \n',task_id);
    
    %check duplication this task
    [rtn_exist,dup_seg_list] = exist_this_task2(task_id, volume_id, segments);
    if rtn_exist~=0
        rtn_step = mysql(h_sql, sprintf(...
            ['update tasks,consensuses ' ...
                'set tasks.status=2, consensuses.inspected=1 ' ...
                'where tasks.id=%d and consensuses.id=%d;'],...
                task_id, cons_id));
        rtn_step = mysql(h_sql, sprintf(['update tasks set status=2 where id=%d;'],task_id));
        
        
        for i=1:numel(dup_seg_list{1})
            fprintf(fid,'\t[%d] (cell_id:%d) duplication\n', ...
                dup_seg_list{3}(i),dup_seg_list{1}(i));
            fprintf('\t[%d] (cell_id:%d) duplication\n', ...
                dup_seg_list{3}(i),dup_seg_list{1}(i));
            
            cons_id1 = cons_id;
            cons_id2 = dup_seg_list{2}(i);
            task_id1 = task_id;
            task_id2 = dup_seg_list{3}(i);
            dup_segs = sprintf('%d ',dup_seg_list{4}{i});
            did1 = isdup(task_id1);
            did2 = isdup(task_id2);
            did = intersect(did1,did2);
            
            if ~isempty(did)
                rtn_step = mysql(h_sql,sprintf(['update duplications set status=0 ' ...
                    ' where id=%d;'],did(1)));
                rtn_step = mysql(h_sql,sprintf(['update tasks set status=2 where id=%d'],dup_seg_list{3}(i)));
            else
                rtn_step = mysql(h_sql,sprintf(['insert into duplications (consensus_id_1, ' ...
                            'consensus_id_2, duplicated_segments) ' ...
                            'values(%d,%d,"%s")'],cons_id1,cons_id2,dup_segs));
                rtn_step = mysql(h_sql,sprintf(['update tasks set status=2 where id=%d'],dup_seg_list{3}(i)));
            end
        end
        rtn_step = mysql(h_sql,'commit;');
        continue;
    end    
    
    global_thresh = gthresh;
    
    [rtn_status, vol_seg_list, drct_vols_ijkid] = task_find_children(volume_id, segments);
    %{
    nexit = sum(ismember(cell2mat(rtn_status),0));
    fprintf(fid,'find %d direction exits\n',nexit);
    fprintf('find %d direction exits\n',nexit);
    %}
    step_rtn = mysql(h_sql,'start transaction;');
    drct_str = [string('+x'),string('-x'),string('+y'),string('-y'),string('+z'),string('-z')];
    for drct=1:6
        
        %fprintf(fid,'   To %s direction: \n',drct_str(drct));
        %fprintf('   To %s direction: \n',drct_str(drct));
        
        ijkid = drct_vols_ijkid{drct};
        if ~isempty(ijkid)
            spawned = [];
            for i=1:numel(vol_seg_list{drct})
                spawned = [spawned vol_seg_list{drct}{i}.seg_list];
            end
            
            [child_id, child_dth, child_left, child_right]  = ...
                mysql(h_sql,sprintf( ...
                ['select tasks.id,tasks.depth,tasks.left_edge,tasks.right_edge ' ...
                'from tasks join volumes on tasks.volume_id=volumes.id ' ...
                'where tasks.cell_id=%d && volumes.id=%d && tasks.status!=1 && ' ...
                'tasks.depth=%d && tasks.left_edge>%d && tasks.right_edge<%d;'], ...
                test_cell,ijkid(4),t_depth+1,t_left,t_right));
            for ii=1:numel(child_id)
                
                child_seg = mysql(h_sql,sprintf(['select c.segments from consensuses as c ' ...
                    'join tasks as t on t.id=c.task_id && t.latest_consensus_version=c.version ' ...
                    'where t.id=%d;'], child_id(ii)));
                
                ch_sds = regexp(child_seg, '\d*', 'Match');
                ch_sds = cellfun(@str2num,ch_sds{1});
                if numel(intersect(spawned,ch_sds))==0
                    rtn_step = mysql(h_sql, sprintf(...
                        ['update tasks set status=1 ' ...
                        'where cell_id=%d && depth>=%d && left_edge>=%d && right_edge<=%d;'],...
                        cell_id,child_dth(ii), child_left(ii),child_right(ii)));
                    fprintf(fid,'\t[%d] (%s) pruned\n',child_id(ii),drct_str(drct));
                    fprintf('\t[%d] (%s) pruned\n',child_id(ii),drct_str(drct));
                end
            end
            
        end
        
        if rtn_status{drct}==0
            n_exits = numel(vol_seg_list{drct});
        else
            continue;
        end
        
        for i=1:n_exits
            
            %fprintf(fid,'\texit%d: ',i);
            %fprintf('\texit%d: ',i);

            %//check duflication
            [rtn_exist, dup_seg_list] = exist_task2(vol_seg_list{drct}{i}.vol, ...
                vol_seg_list{drct}{i}.seg_list, vol_seg_list{drct}{i}.seg_size);
            
            if rtn_exist==0
                seeds = sprintf('%d ',vol_seg_list{drct}{i}.seg_list);
                excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);                
                
                rtn_step = mysql(h_sql, ... 
                sprintf(['call spwn_add_new_task(%d,%d,"%s",%d,%d,"%s")'], ...
                    task_id, vol_seg_list{drct}{i}.vol, seeds, 0,system_user_id,excoord));
                
                last_id = mysql(h_sql,'select last_insert_id();');
                last_id = mysql(h_sql,sprintf('select task_id from consensuses where id=%d;',last_id));
                    
                fprintf(fid,'\t[%d] (%s) spawned\n', last_id,drct_str(drct));
                fprintf('\t[%d] (%s) spawned\n', last_id,drct_str(drct));
                count_new = count_new+1;
                
            else
                if any((dup_seg_list{1}(:)==test_cell) .* (dup_seg_list{6}(:)~=1))
                    dup_task = dup_seg_list{3}(logical((dup_seg_list{1}(:)==test_cell) .* (dup_seg_list{6}(:)~=1)));
                    for iii=1:length(dup_task)
                        fprintf(fid,'\t[%d] (%s) already exists\n',dup_task(iii),drct_str(drct));
                        fprintf('\t[%d] (%s) already exists\n',dup_task(iii),drct_str(drct));
                    end
                    continue;
                elseif any( dup_seg_list{6}(:)==1 )
                    excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);
                    stashed_child_task_id = dup_seg_list{3}(logical(dup_seg_list{6}(:)==1));
                    for chid = 1:numel(stashed_child_task_id)
                        
                        rtn_step = mysql(h_sql, ... 
                            sprintf(['call spwn_add_from_stashed_task(%d,%d);'], ...
                            task_id, stashed_child_task_id(chid)));
                        
                        fprintf(fid,'\t[%d] (%s) stitched\n', ...
                                stashed_child_task_id(chid),drct_str(drct));
                        fprintf('\t[%d] (%s) stitched\n', ...
                                stashed_child_task_id(chid),drct_str(drct));
                        
                        rtn = mysql(h_sql, ...
                            sprintf(['update tasks set spawning_coordinate="%s" where id=%d'] ...
                            ,excoord,stashed_child_task_id(chid)));
                            
                        count_new = count_new+1;
                        
                    end
                elseif any( (dup_seg_list{1}(:)~=test_cell) .* dup_seg_list{6}(:)~=1 )
                    seeds = sprintf('%d ',vol_seg_list{drct}{i}.seg_list);
                    excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);
                    
                    rtn_step = mysql(h_sql, ... 
                    sprintf(['call spwn_add_new_task(%d,%d,"%s",%d,%d,"%s")'], ...
                        task_id, vol_seg_list{drct}{i}.vol, seeds, 2,system_user_id,excoord));
                
                    last_cons_id = mysql(h_sql,'select last_insert_id();');
                    last_task_id = mysql(h_sql,sprintf('select task_id from consensuses where id=%d;',last_cons_id));
                    
                    fprintf(fid,'\t[%d] (%s) spawned\n', last_task_id,drct_str(drct));
                    fprintf('\t[%d] (%s) spawned\n', last_task_id,drct_str(drct));
                    count_new = count_new+1;
                    
                    rtn_step = mysql(h_sql,sprintf(['update consensuses set inspected=1 where id=%d'],last_cons_id));
                    
                    for ii=1:numel(dup_seg_list{2})
                        cons_id1 = last_cons_id;
                        cons_id2 = dup_seg_list{2}(ii);
                        dup_segs = sprintf('%d ',dup_seg_list{4}{ii});
                        %dup_frct = dup_seg_list{5}(ii).*100;
                        
                        rtn_step = mysql(h_sql,sprintf(['insert into duplications (consensus_id_1, ' ...
                                'consensus_id_2, duplicated_segments) ' ...
                                'values(%d,%d,"%s")'],cons_id1,cons_id2,dup_segs));
                        rtn_step = mysql(h_sql,sprintf(['update tasks set status=2 where id=%d'],dup_seg_list{3}(ii)));
                            
                        fprintf(fid,'\t\t[%d] (cell_id:%d) duplication\n', ...
                            dup_seg_list{3}(ii),dup_seg_list{1}(ii));
                        fprintf('\t\t[%d] (cell_id:%d) duplication\n', ...
                            dup_seg_list{3}(ii),dup_seg_list{1}(ii));
                        
                    end
                else   
                    fprintf(fid,'un-expected dup case please check\n');
                    fprintf('un-expected dup case please check\n');
                end
            end
        end
    end
        
    if task_prg==5
        %
        rtn_step = mysql(h_sql, sprintf(...
            ['update tasks,consensuses ' ...
                'set tasks.progress=6, consensuses.inspected=1 ' ...
                'where tasks.id=%d and consensuses.id=%d;'],...
                task_id, cons_id));
        %}
        %fprintf(fid,'   set task progress to complete\n');
        %fprintf('   set task progress to complete\n');
    else
        rtn_step = mysql(h_sql, sprintf(...
            ['update consensuses set inspected=1,status=2 where consensuses.id=%d;'],cons_id));
    end
    rtn_step = mysql(h_sql,'commit;');
    
end
%{
fprintf(fid,'\nreached to mat_add_task count.\n');
fprintf(fid,'\change all remained consensuses.inspected to 1\n');
%}
mysql(h_sql,'close');
rtn_spawn=1;
fprintf(fid,'\ndone');
fprintf('\ndone');
%fclose(fid);

end
%}

%%
function [rtn_exist, dup_seg_list] = exist_task2(vol_id, seg_list, seg_size)
global h_sql 
rtn_exist=0;

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
        dup_seg_list{1,5}(n)=sum(seg_size(ismember(seg_list,dup_seg)))/total_size;
        dup_seg_list{1,6}(n) = task_st(i);
    end
end

if ~isempty(dup_seg_list)
    rtn_exist = 1;
end

end


%%
function [rtn_exist, dup_seg_list] = exist_this_task2(task_id, vol_id, seg_list)
global h_sql 
rtn_exist=0;

[sv_cell, sv_con_id, sv_task_id, sv_seg] = mysql(h_sql, sprintf([...
    'select tasks.cell_id, consensuses.id, consensuses.task_id, consensuses.segments ' ...
    'from consensuses join tasks on consensuses.task_id=tasks.id && ' ...
    'consensuses.version=tasks.latest_consensus_version ' ...
    'where tasks.volume_id=%d && consensuses.task_id!=%d && ' ...
    '(tasks.status=0||tasks.status=2) && consensuses.status!=3;' ...
    ],vol_id,task_id));

sv_seg = regexp(sv_seg, '\d*', 'Match');
dup_seg_list = [];

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
    end
end

%check whether new task's seed is crashed with segments of other cells.
if ~isempty(dup_seg_list)
    rtn_exist = 1;
end

end


%%


































































