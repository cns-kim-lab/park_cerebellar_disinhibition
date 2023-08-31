function [isdone, count_new, count_all, stitched_ids] = spawn_for_agglomerator(test_cell, gthresh, max_add_task, test_task_id, force2)
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
    if nargin > 3 
        write_log(sprintf('      [spawner] cell %d, task %d, force %d', test_cell, test_task_id, force2));
    else
        write_log(sprintf('      [spawner] cell %d', test_cell));
    end

    mysql('close');

    global h_sql global_thresh system_user_id tstcell
    tstcell = test_cell;    
    global_thresh = gthresh;
    connsql();
    system_user_id = mysql(h_sql, sprintf('select id from users where name="%s";', 'system'));

    count_new = 0;
    count_all = 0;
    isdone = false;
    stitched_ids = [];
    
%% while
while isdone==false && count_new<max_add_task
    if(test_mode==2)
        if force2==1
            rtn = mysql(h_sql, sprintf('update consensuses as c join tasks as t on c.task_id=t.id && c.version=t.latest_consensus_version set inspected=0 where t.id=%d;', ...
                test_task_id));
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
            'order by id desc limit 1;'], ...
            test_cell,test_task_id));
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
            'order by id desc limit 1;'], ...
            test_cell));
    end

    [didr,dstr,tskr1,tskr2] = isdup(task_id);
    if ~isempty(find(dstr==0)) | tstatus==2
        rtn_step = mysql(h_sql,sprintf('update tasks set status=0 where id=%d;',task_id));
        for q=1:length(didr)
            rtn_step = mysql(h_sql,sprintf('update duplications set status=1 where id=%d;', didr(q)));
        end
    end
    
    if isempty(cons_id)
        isdone = true;
        write_log('       no more consensuses to spawn');
        continue
    end
    
    segments{1} = regexp(segments{1}, '\d*', 'Match');
    segments{1} = cellfun(@str2num,segments{1});
    segments = segments{1};
    
    write_log(sprintf('     %d: spawning.. ', task_id));
    
    %check duplication this task
    [rtn_exist,dup_seg_list] = find_exist_tasks_this(task_id, volume_id, segments);
    if rtn_exist~=0
        rtn_step = mysql(h_sql, sprintf('update tasks,consensuses set tasks.status=2, consensuses.inspected=1 where tasks.id=%d and consensuses.id=%d;', ...
                task_id, cons_id));            
        rtn_step = mysql(h_sql, sprintf('update tasks set status=2 where id=%d;',task_id));        
        
        for i=1:numel(dup_seg_list{1})
            write_log(sprintf('[%d] (cell_id:%d) duplication', dup_seg_list{3}(i),dup_seg_list{1}(i)));
            
            cons_id1 = cons_id;
            cons_id2 = dup_seg_list{2}(i);
            task_id1 = task_id;
            task_id2 = dup_seg_list{3}(i);
            dup_segs = sprintf('%d ',dup_seg_list{4}{i});
            [did1, did1_stt, ~, ~, did1_cons1, did1_cons2, ~] = isdup(task_id1);
            [did2, did2_stt] = isdup(task_id2);
            [did, didj] = intersect(did1,did2);
            
            if ~isempty(did)
                for j=1:length(didj)
                    if all(sort([did1_cons1(didj(j)),did1_cons2(didj(j))]) == sort([cons_id1, cons_id2]))
                        rtn_step = mysql(h_sql,sprintf(['update duplications set status=0 ' ...
                            ' where id=%d;'],did(j)));
                    elseif did1_stt(didj(j))~=2
                        rtn_step = mysql(h_sql,sprintf(['update duplications set status=2 ' ...
                            ' where id=%d;'],did(j)));
                        insert_into_dup(cons_id1,cons_id2,dup_segs);
                    end
                end    
                rtn_step = mysql(h_sql,sprintf(['update tasks set status=2 where id=%d'],dup_seg_list{3}(i)));
                
            else
                insert_into_dup(cons_id1,cons_id2,dup_segs);
                rtn_step = mysql(h_sql,sprintf(['update tasks set status=2 where id=%d'],dup_seg_list{3}(i)));
            end
        end
        rtn_step = mysql(h_sql, 'commit;');
        continue;
    elseif ~isempty(setdiff([tskr1(find(dstr==0));tskr2(find(dstr==0))],task_id))
        
        dind1 = find(dstr==0 & tskr1~=task_id );
        dind2 = find(dstr==0 & tskr2~=task_id );
        duple_recoded_task = [tskr1(dind1);tskr2(dind2)];
        duple_recoded_did = [didr(dind1);didr(dind2)];
        
        is_realy_solved = 1;
        for drtsk=1:length(duple_recoded_task)
            
            task_id_mc = duple_recoded_task(drtsk);
            did_mc = duple_recoded_did(drtsk);
            [cell_id_mc,volume_id_mc, status_mc] = mysql(h_sql, sprintf(['select cell_id, volume_id, status from tasks where id=%d'],task_id_mc));
            segments_mc = mysql(h_sql, sprintf(['select c.segments from consensuses as c join tasks as t on ' ...
                't.latest_consensus_version=c.version && c.task_id=t.id where t.id=%d;'],task_id_mc));
            
            segments_mc{1} = regexp(segments_mc{1}, '\d*', 'Match');
            segments_mc{1} = cellfun(@str2num,segments_mc{1});
            segments_mc = segments_mc{1};
            
            [rtn_exist_mc, dup_seg_list_mc] = find_exist_tasks_this(task_id_mc, volume_id_mc, segments_mc);
            if ~isempty(dup_seg_list_mc)
                if ismember(task_id, dup_seg_list_mc{3}) && status_mc~=1 && status_mc~=3
                    is_realy_solved = 0;
                    
                    write_log(sprintf('       %d (cell_id:%d) duplication from related task',task_id_mc, cell_id_mc));
                    
                    rtn_step = mysql(h_sql,sprintf('update duplications set status=0 where id=%d;', did_mc));
                    rtn_step = mysql(h_sql,sprintf('update tasks set status=2 where id=%d;', task_id_mc));
                end
            end
        end
        
        if is_realy_solved==0
            rtn_step = mysql(h_sql,sprintf('update tasks set status=2 where id=%d;',task_id));
        end
    end  
    
    [rtn_status, vol_seg_list, drct_vols_ijkid] = task_find_children(volume_id, segments);

    drct_str = ["+x" "-x" "+y" "-y" "+z" "-z"];
    for drct=1:6
        if ~isempty(drct_vols_ijkid{drct})
            ijkid = drct_vols_ijkid{drct}{1};
            [vx,vy,vz] = mysql(h_sql, sprintf('select vx,vy,vz from volumes where id=%d;', ijkid(4)));
            
            [child_id, child_dth, child_left, child_right, child_vol]  = ...
                mysql(h_sql,sprintf( ...
                ['select tasks.id,tasks.depth,tasks.left_edge,tasks.right_edge, tasks.volume_id ' ...
                'from tasks join volumes on tasks.volume_id=volumes.id ' ...
                'where tasks.cell_id=%d && tasks.status!=1 && tasks.status!=4 && ' ...
                'tasks.depth=%d && tasks.left_edge>%d && tasks.right_edge<%d ' ...
                '&& volumes.vx=%d && volumes.vy=%d && volumes.vz=%d;'], ...
                test_cell,t_depth+1,t_left,t_right,vx,vy,vz));
            
            n_exits = numel(vol_seg_list{drct});
             
            for ii=1:numel(child_id)
                
                doprune=[];
                child_seg = mysql(h_sql,sprintf('select c.segments from consensuses as c join tasks as t on t.id=c.task_id && t.latest_consensus_version=c.version where t.id=%d;', ...
                    child_id(ii)));
                ch_sds = regexp(child_seg, '\d*', 'Match');
                ch_sds = cellfun(@str2num,ch_sds{1});
                
                if n_exits==0
                   doprune=1; 
                end
                
                for iii=1:n_exits
                    spawned = vol_seg_list{drct}{iii}.seg_list;
                    if child_vol(ii)==vol_seg_list{drct}{iii}.vol
                        if numel(intersect(spawned,ch_sds))==0
                            doprune(iii) = true;
                        else
                            doprune(iii) = false;
                        end
                    else
                        doprune(iii) = check_prune_tasks(vol_seg_list{drct}{iii}.vol, child_vol(ii), spawned, ch_sds);
                    end
                end
                if all(doprune)
                    rtn_step = mysql(h_sql, sprintf('update tasks set status=1 where cell_id=%d && depth>=%d && left_edge>=%d && right_edge<=%d;', ...
                        cell_id,child_dth(ii), child_left(ii),child_right(ii)));
                    
                    write_log(sprintf('       %d (%s) pruned',child_id(ii),drct_str(drct)));
                end
            end
            
        end
        
        if rtn_status{drct}==0
            n_exits = numel(vol_seg_list{drct});
        else
            continue
        end
        
        for i=1:n_exits
            %//check duflication
            [rtn_exist, dup_seg_list] = find_exist_tasks(vol_seg_list{drct}{i}.vol, ...
                vol_seg_list{drct}{i}.seg_list, vol_seg_list{drct}{i}.seg_size);
            
            
            if rtn_exist==0
                seeds = sprintf('%d ',vol_seg_list{drct}{i}.seg_list);
                excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);                
                
                rtn_step = mysql(h_sql, sprintf('call spwn_add_new_task(%d,%d,"%s",%d,%d,"%s")', task_id, vol_seg_list{drct}{i}.vol, seeds, 0,system_user_id,excoord));
                
                last_id = mysql(h_sql,'select last_insert_id();');
                last_id = mysql(h_sql, sprintf('select task_id from consensuses where id=%d;',last_id));
                    
                write_log(sprintf('       %d (%s) spawned',last_id,drct_str(drct)));
                
                count_new = count_new+1;
                count_all = count_all+1;                
            else
                if any((dup_seg_list{1}(:)==test_cell) .* (dup_seg_list{6}(:)~=1) .* (dup_seg_list{6}(:)~=4))
%                     dup_task = dup_seg_list{3}(logical((dup_seg_list{1}(:)==test_cell) .* (dup_seg_list{6}(:)~=1)));
                    %jwgim fix bug (do not consider when status in (1,4))
                    dup_task = dup_seg_list{3}(logical((dup_seg_list{1}(:)==test_cell) .* (dup_seg_list{6}(:)~=1) .* (dup_seg_list{6}(:)~=4) )); 
                    for iii=1:length(dup_task)
                        write_log(sprintf('       %d (%s) already exists',dup_task(iii),drct_str(drct)));
                        count_all = count_all+1;    %jwgim 180511
                    end
                    continue;
                elseif any( dup_seg_list{6}(:)==1 )
                    excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);
                    stashed_child_task_id = dup_seg_list{3}(logical(dup_seg_list{6}(:)==1));
                    for chid = 1:numel(stashed_child_task_id)
                        
                        rtn_step = mysql(h_sql, sprintf('call spwn_add_from_stashed_task(%d,%d);', task_id, stashed_child_task_id(chid)));                        
                        
                        write_log(sprintf('       %d (%s) stitched',stashed_child_task_id(chid),drct_str(drct)));
                        
                        count_new = count_new+1;    %jwgim 180426
                        count_all = count_all+1;
                        
                        stitched_ids = [stitched_ids stashed_child_task_id(chid)];
                        
                        rtn = mysql(h_sql, sprintf('update tasks set spawning_coordinate="%s" where id=%d;', excoord,stashed_child_task_id(chid)));                        
                    end
                elseif any( (dup_seg_list{1}(:)~=test_cell) .* (dup_seg_list{6}(:)~=1) .* (dup_seg_list{6}~=4) )
                    seeds = sprintf('%d ',vol_seg_list{drct}{i}.seg_list);
                    excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);
                    
                    rtn_step = mysql(h_sql, sprintf('call spwn_add_new_task(%d,%d,"%s",%d,%d,"%s")', task_id, vol_seg_list{drct}{i}.vol, seeds, 2,system_user_id,excoord));
                
                    last_cons_id = mysql(h_sql,'select last_insert_id();');
                    last_task_id = mysql(h_sql,sprintf('select task_id from consensuses where id=%d;',last_cons_id));
                    
                    write_log(sprintf('       %d (%s) spawned',last_task_id,drct_str(drct)));
                    
                    count_new = count_new+1;
                    count_all = count_all+1;
                    
                    rtn_step = mysql(h_sql,sprintf('update consensuses set inspected=1 where id=%d;', last_cons_id));
                    
                    for ii=1:numel(dup_seg_list{2})
                        cons_id1 = last_cons_id;
                        cons_id2 = dup_seg_list{2}(ii);
                        dup_segs = sprintf('%d ',dup_seg_list{4}{ii});
                        %dup_frct = dup_seg_list{5}(ii).*100;
                        
                        insert_into_dup(cons_id1,cons_id2,dup_segs);
                        rtn_step = mysql(h_sql,sprintf('update tasks set status=2 where id=%d', dup_seg_list{3}(ii)));
                            
                        write_log(sprintf('         %d (cell_id:%d) duplication',dup_seg_list{3}(ii),dup_seg_list{1}(ii)));
                    end
                elseif any( (dup_seg_list{1}(:)~=test_cell) .* dup_seg_list{6}(:)~=1 )
                    seeds = sprintf('%d ',vol_seg_list{drct}{i}.seg_list);
                    excoord = sprintf('%d,%d,%d',vol_seg_list{drct}{i}.entering_coord);
                    
                    rtn_step = mysql(h_sql, sprintf('call spwn_add_new_task(%d,%d,"%s",%d,%d,"%s")', task_id, vol_seg_list{drct}{i}.vol, seeds, 0,system_user_id,excoord));
                
                    last_cons_id = mysql(h_sql,'select last_insert_id();');
                    last_task_id = mysql(h_sql,sprintf('select task_id from consensuses where id=%d;',last_cons_id));
                    
                    write_log(sprintf('       %d (%s) spawned',last_task_id,drct_str(drct)));
                    count_new = count_new+1;
                    count_all = count_all+1;
                    
                else   
                    write_log('@ERROR: un-expected dup case please check.', 1);
                end
            end
        end
    end %end of for "drct"
        
    if task_prg==5
        rtn_step = mysql(h_sql, sprintf('update tasks,consensuses set tasks.progress=6, consensuses.inspected=1 where tasks.id=%d and consensuses.id=%d;', ...
                task_id, cons_id));
    else
        rtn_step = mysql(h_sql, sprintf('update consensuses set inspected=1,status=2 where consensuses.id=%d;', cons_id));
    end
    
end

%%
    mysql(h_sql,'close');
%     write_log('     end of spawner.');
end
