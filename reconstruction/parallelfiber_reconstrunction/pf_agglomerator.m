function pf_agglomerator(cell_id_list)
    addpaths();

    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        return
    end

    if nargin < 1
        write_log('##usage: pf_agglomerator(cell_id_list); ex: pf_agglomerator([100 101])', 1);
        return
    end
    
    write_log('[PF_AGGLOMERATOR] ---------------------------------------------------------------------');
    reject_notes = ["done";"pass"];
    
    for idx=1:numel(cell_id_list)
        tic
        cell_id=cell_id_list(idx); 
        write_log(sprintf('  cell %d agglomeration start.', cell_id));
        agglomerate_cell(cell_id, reject_notes);
        check_fn(cell_id, reject_notes);        
        edt = toc;
        write_log(sprintf('  cell %d agglomeration done. (%.2f sec)', cell_id, edt), 1);        
    end
    
    write_log('  agglomerate process quit.', 1);
end

%%
function check_fn(cell_id, reject_notes)
    write_log(sprintf('  [check missing errors in cell %d]', cell_id));
    
    cell_trace_data = get_cell_trace_data_include_notes(cell_id, [0 2 3]);
    ntasks = numel(cell_trace_data.task_id);
    
    overlap = [32 32 8];
    fn_size_th = 27;
        
    minz = min(cell_trace_data.vz(:));
    maxz = max(cell_trace_data.vz(:));
        
    for itask=1:ntasks
        task_id = cell_trace_data.task_id(itask);
        
        %skip when notes field contains keyword "pass"
        if ~isempty( strfind(cell2mat(cell_trace_data.notes(itask)), reject_notes{2}) )
            continue
        end      
        msg = sprintf('   (%d/%d) TASK ID : %d', itask, ntasks, task_id);
    
        %skip when notes field do not contains keyword "done"
        if isempty( strfind(cell_trace_data.notes(itask), reject_notes{1}) )
            write_log(sprintf('%s, skipped task, do not check.', msg));
            continue
        end
                
        segment_str = cell2mat(cell_trace_data.segments(itask));
        %parsing seed_set
        segments = str2double(split(strtrim(segment_str)))';
        segments(isnan(segments)) = [];
        
        if isempty(segments)
            write_log(sprintf('%s, no segments.', msg));
            update_notes(task_id, 'pass');
            continue
        end
        
        write_log(sprintf('%s', msg));
        
        vol_name = cell2mat(cell_trace_data.volume_name(itask));
        vol_idx = [cell_trace_data.vx(itask) cell_trace_data.vy(itask) cell_trace_data.vz(itask)];
        %parsing volume info 
        pos = strfind(vol_name, '_');
        net_prefix = vol_name(1:pos(1)-1);
        
        %read segmentation volumes
        segmentation = load_segmentation_volume(vol_idx, net_prefix);   
        
        %binarize segmentation volume
        segmentation = ismember(segmentation, segments);        

        exit_check = check_exit(segmentation, overlap, fn_size_th);
        
        isfn = false;
        nexit = sum(exit_check(:));
        if nexit < 1 %no exit
            isfn = true;
        elseif nexit < 2    %1 exit
            only_exit = check_segments_only_exit(segmentation, exit_check, overlap);
            %if segments exist only overlap region, not fp
            if nnz(only_exit) < 1   %segments exist both overlap and non-overlap region
                write_log('   segments exist both overlap, non-overlap region(but not touch edge). should check missing error.');
                isfn = true;
            end
        else %exit more than 2 points
            isleaf = is_leaf_task(task_id);
            if isleaf   %if leaf node task & tip of cell(z direction) & not end volume(z direction) then, FN
                vz = cell_trace_data.vz(itask);
                if (vz == minz || vz == maxz ) && vz > 1 && vz < 9 
                    write_log('   leaf task and tip of cell but missing parts. should check missing error.');
                    isfn = true;
                end                
            end
            if ~isfn
                [start_, end_, istart, iend] = get_edge_slices(segmentation);
                
                touch_exit = [0 0];
                %touches z exit
                if istart < overlap(1) 
                    touch_exit(1) = 1;
                end
                if iend > size(segmentation,3) - overlap(3)+1
                    touch_exit(2) = 2;
                end
                
                if sum(touch_exit(:)) < 2
                    %check start slice 
                    if nnz(start_(1:overlap(1),:)) > 0 || nnz(start_(end-overlap(1)+1:end,:)) > 0 || nnz(start_(:,1:overlap(2))) > 0 || nnz(start_(:,end-overlap(2)+1:end)) > 0 
                        touch_exit(1) = 1;
                    end
                    
                    %check end slice
                    if nnz(end_(1:overlap(1),:)) > 0 || nnz(end_(end-overlap(1)+1:end,:)) > 0 || nnz(end_(:,1:overlap(2))) > 0 || nnz(end_(:,end-overlap(2)+1:end)) > 0
                        touch_exit(2) = 1;
                    end
                    
                    if sum(touch_exit(:)) < 2
                        isfn = true;
                        write_log('   segments not reach edge of volume. should check missing error.');
                    end
                end                
            end
        end      
        
        %update db
        if isfn
            update_notes(task_id, 'check missing parts');
        end
        update_notes(task_id, 'pass');
    end      
end

%%
function [first_slice, last_slice, first_idx, last_idx] = get_edge_slices(segmentation)
    size_ = size(segmentation);
    first_idx = 2;
    last_idx = size_(3)-1;
    
    for islice=2:size_(3)-1
        if nnz(segmentation(:,:,islice)) > 0
            first_idx = islice;
            break
        end
    end   
    for islice=size_(3)-1:-1:2
        if nnz(segmentation(:,:,islice)) > 0
            last_idx = islice;
            break
        end
    end
    first_slice = segmentation(:,:,first_idx);
    last_slice = segmentation(:,:,last_idx);   
end

%%
function isleaf = is_leaf_task(task_id)
    isleaf = false;
    
    con_info = get_dbinfo();
    h_sql = mysql('open', con_info.host, con_info.user, con_info.passwd);
    rtn = mysql(h_sql, ['use ' con_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: is_leaf_task: DB open failed (host:%s, id:%s)', ...
            con_info.host, con_info.user),1 );
        return
    end
    
    query = sprintf('SELECT cell_id,depth,left_edge,right_edge FROM tasks WHERE id=%d;', task_id);
    [cell_id,depth,left_edge,right_edge] = mysql(h_sql, query);   
    
    query = sprintf('SELECT id FROM tasks WHERE cell_id=%d AND depth>%d AND left_edge>%d AND right_edge<%d;', ...
        cell_id, depth, left_edge, right_edge);
    
    child_id = mysql(h_sql, query);   
    if isempty(child_id)
        isleaf = true;
    end
    
    mysql(h_sql, 'close');
end

%%
function rsl = check_segments_only_exit(segmentation, exit_, overlap)
    rsl = zeros([1 6], 'logical');
    total_pixels = nnz(segmentation);
    
    if exit_(1)     %x(-)
        pixels = nnz(segmentation(1:overlap(1),:,:));
        rsl(1) = isequal(total_pixels, pixels);
    end
    if exit_(2)     %x(+)
        pixels = nnz(segmentation(end-overlap(1)+1,:,:));
        rsl(2) = isequal(total_pixels, pixels);
    end
    if exit_(3)     %y(-)
        pixels = nnz(segmentation(:,1:overlap(2),:));
        rsl(3) = isequal(total_pixels, pixels);
    end    
    if exit_(4)     %y(+)
        pixels = nnz(segmentation(:,end-overlap(2)+1:end,:));
        rsl(4) = isequal(total_pixels, pixels);
    end    
    if exit_(5)     %z(-)
        pixels = nnz(segmentation(:,:,1:overlap(3)));
        rsl(5) = isequal(total_pixels, pixels);
    end
    if exit_(6)     %z(+)
        pixels = nnz(segmentation(:,:,end-overlap(3)+1:end));
        rsl(6) = isequal(total_pixels, pixels);
    end        
end

%%
function exit_ = check_exit(segmentation, overlap, size_th)
    %check every exit
    exit_ = zeros([1 6], 'single');
    msg = '    exit? ';
    if nnz(segmentation(1:overlap(1),:,:)) > size_th            %x(-)
        msg = sprintf('%s -x', msg);
        exit_(1) = 1;
    end
    if nnz(segmentation(end-overlap(1)+1:end,:,:)) > size_th    %x(+)
        msg = sprintf('%s +x', msg);
        exit_(2) = 1;
    end
    if nnz(segmentation(:,1:overlap(2),:)) > size_th            %y(-)
        msg = sprintf('%s -y', msg);
        exit_(3) = 1;
    end
    if nnz(segmentation(:,end-overlap(2)+1:end,:)) > size_th    %y(+)
        msg = sprintf('%s +y', msg);
        exit_(4) = 1;
    end
    if nnz(segmentation(:,:,1:overlap(3))) > size_th            %z(-)
        msg = sprintf('%s -z', msg);
        exit_(5) = 1;
    end
    if nnz(segmentation(:,:,end-overlap(3)+1:end)) > size_th    %z(+)
        msg = sprintf('%s +z', msg);
        exit_(6) = 1;
    end
    
    if sum(exit_(:)) < 1
        msg = sprintf('%s none', msg);
    end    
    write_log(sprintf('%s', msg));
end


%%
function agglomerate_cell(cell_id, reject_notes)
    write_log('  [agglomerate cell] ');
    
    ntask_th = 100; %org:30
    task_id_finished = [];
    
    iter_cnt = 0;
    ntasks_prev = 0;    
    while 1
        cell_trace_data = get_cell_trace_data_include_notes(cell_id, [0 2 3]);
        ntasks = numel(cell_trace_data.task_id);
        if ntasks < 1 
            write_log(sprintf('   [%d] no task exists for this cell.', iter_cnt+1));
            break
        end
        if ntasks == ntasks_prev
            write_log(sprintf('   [%d] no more new tasks for this cell(%d), quit.', iter_cnt+1, cell_id));
            break
        end
        
        %add reject task into finished list
        task_id_finished = modify_finished_id(cell_trace_data, reject_notes, task_id_finished);
        
        ntasks_prev = ntasks;
        write_log(' ');
        write_log(sprintf(' --- %dth try >> %d task(s)', iter_cnt+1, ntasks));
        if ntasks > ntask_th
            write_log(sprintf('   too many tasks(%d) exist for this cell, stop agglomeration.', ntasks));
            break
        end
        
        new_all = 0;
        for task_iter=1:ntasks 
            task_id = cell_trace_data.task_id(task_iter);
            if find(task_id_finished==task_id, 1)   %finished task                 
                continue
            end
            
            msg = sprintf('     (%d/%d) TASK ID: %d', task_iter, ntasks, task_id);            
            %read task status from DB (to consider updated tasks)
            task_status = get_task_status(task_id);
            if task_status == 3 %frozen task
                write_log(sprintf('%s, frozen, skip.', msg));
                continue
            elseif task_status == 2 %duplicated task
                write_log(sprintf('%s, duplicated, skip.', msg));
                continue
            elseif task_status == 1 %stashed task
                write_log(sprintf('%s, stashed, skip.', msg));
                continue
            elseif task_status == 4 %buried task
                write_log(sprintf('%s, buried, skip.', msg));
                continue
            end
            
            write_log(sprintf('%s', msg));
            write_log(sprintf('     task %d: agglomeration start.', task_id));
            
            [final_segments, flag_fp, flag_size_exceed] = agglomerate_in_volume_based_mexa(cell2mat(cell_trace_data.volume_name(task_iter)), ...
                [cell_trace_data.vx(task_iter) cell_trace_data.vy(task_iter) cell_trace_data.vz(task_iter)], ...
                cell2mat(cell_trace_data.segments(task_iter)));
            
            if isempty(final_segments) && ~flag_fp 
                write_log(sprintf('     volume %s has not changed.', cell2mat(cell_trace_data.volume_name(task_iter))));
            else
                %write new segment set to DB
                update_db(task_id, final_segments, flag_fp);                
            end 
            update_notes(task_id, 'done');
            
            %do not spawn when cons is too big
            if ~flag_size_exceed                    
                [flag_done, cnt_new, cnt_all, sids] = spawn_task(cell_id, task_id); %spawning
                if ~isempty(sids)                    
                    for istitched=1:numel(sids)
                        write_log(sprintf('     clean up notes field of stitched task %d.', sids(istitched)));
                        update_notes(sids(istitched), ' ');
                    end
                end

                if cnt_new > 4 || cnt_all > 6 || ~flag_done 
                    write_log(sprintf('     too many neighbor tasks of this task(%d), freeze tasks.', task_id));
                    freeze_task_and_its_children(task_id, cell_id);	%freeeze task
                    continue
                end
            else
                write_log(sprintf('     too big consensus, freeze and do not spawn this task(%d).', task_id));
                cnt_new = 0;                
                freeze_task_and_its_children(task_id, cell_id);	%freeeze task
            end
            new_all = new_all + cnt_new;

            %check done
            task_id_finished = [task_id_finished task_id];
            write_log(sprintf('     task %d: agglomeration end.', task_id));
            
            if ntasks + new_all > ntask_th    %added for quick quit 
                write_log(sprintf('     too many tasks exist for this cell(%d+%d), stop agglomeration.', ntasks, new_all));
                return
            end
        end %end of for loop 'task'
        
        iter_cnt = iter_cnt+1;
        if iter_cnt > 15
            write_log('   @too many iteration(>15), quit this cell.');
            break
        end            
    end      
end

%%
function status = get_task_status(task_id)
    con_info = get_dbinfo();
    
    h_sql = mysql('open', con_info.host, con_info.user, con_info.passwd);
    rtn = mysql(h_sql, ['use ' con_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: get_task_status: DB open failed (host:%s, id:%s)', ...
            con_info.host, con_info.user), 1);
        return
    end
    
    query = sprintf('SELECT status FROM tasks WHERE id=%d;', task_id);
    status = mysql(h_sql, query);   
    
    mysql(h_sql, 'close');
end

%%
function fin_id = modify_finished_id(cell_trace_data, reject_notes, fin_id)
    ntasks = numel(cell_trace_data.task_id);
    for itask=1:ntasks
        all_ = arrayfun(@(x) strfind(cell2mat(cell_trace_data.notes(itask)), x), reject_notes, 'uni', false);
        if sum([all_{:}]) > 0        
            fin_id = [fin_id cell_trace_data.task_id(itask)];
        end
    end   
    fin_id = unique(fin_id);
end

%%
function update_notes(task_id, notes)
    db_info = get_dbinfo();
    
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: update_notes: DB open failed (host:%s, id:%s)', ...
            db_info.host, db_info.user),1);
        return
    end
    
    query = sprintf('SELECT notes FROM tasks WHERE id=%d;', task_id);
    notes_ = mysql(h_sql, query);
    if isempty(notes_)
        notes_ = '';
    else
        notes_ = cell2mat(notes_);
    end

    
    if strcmpi(notes, ' ')  %initialize notes
        write_log(sprintf('   notes field will be initialized for task %d.', task_id));
        query = sprintf('UPDATE tasks SET notes='' '' WHERE id=%d;', task_id);
    else    %always append to end of string with comma
        query = sprintf('UPDATE tasks SET notes=''%s,%s'' WHERE id=%d;', notes_, notes, task_id);
    end
    
    rtn = mysql(h_sql, query);
    if rtn < 0 
        write_log(sprintf('@ERROR: update_notes: query failed(%s)', query),1);
    end    
    
    mysql(h_sql, 'close');
end

%%
function freeze_task_and_its_children(task_id, cell_id)
    db_info = get_dbinfo();
    
    h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(h_sql, ['use ' db_info.db_name]);
    if rtn <= 0 
        write_log(sprintf('@ERROR: freeze_task_and_its_children: DB open failed (host:%s, id:%s)\n', ...
            db_info.host, db_info.user),1);
        return
    end
    
    write_log(sprintf('   freeze task %d and its children.', task_id));
    query = sprintf('CALL pf_freeze_task_include_children(%d,%d);', task_id, cell_id);
    try 
        rtn = mysql(h_sql, query);    
    catch err
        [err_lv, err_code, err_msg] = mysql(h_sql, query);
        write_log(sprintf('@ERROR: calling procedure failed. (%s)', query), 1);
    end
    
    mysql(h_sql, 'close');
end

%%
function update_db(task_id, segments, isfp)
    if isempty(segments) && ~isfp 
        write_log(sprintf('   task %d not changed.', task_id));
        return
    end    

    write_log(sprintf(' [DB write for task %d]', task_id));
    
    if isempty(segments)
        write_log('   segments is empty.');  
        update_notes(task_id, 'check merge');      
    else
        db_info = get_dbinfo();
        h_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
        rtn = mysql(h_sql, ['use ' db_info.db_name]);
        if rtn <= 0 
            write_log(sprintf('@ERROR: update_db: DB open failed (host:%s, id:%s)', ...
                db_info.host, db_info.user),1);
            return
        end

        query = sprintf('SELECT latest_consensus_version, comparison_group_id FROM tasks WHERE id=%d;', task_id);
        [cons_version, gid] = mysql(h_sql, query);

        query = sprintf('INSERT INTO consensuses (task_id,user_id,comparison_group_id,version,duration,status,segments) VALUES (%d,5,%d,%d,0,2,''%s'');', ...
            task_id, gid, cons_version+1, num2str(segments));
        rtn = mysql(h_sql, query);        
        if rtn <= 0             
            write_log(sprintf('@ERROR: update_db: query failed(%s)', query),1);            
            mysql(h_sql, 'close');
            return
        end        
        
        query = sprintf('UPDATE tasks SET latest_consensus_version=%d,seeds=''%s'' WHERE id=%d;', ...
            cons_version+1, num2str(segments), task_id);
        rtn = mysql(h_sql, query);        
        if rtn <= 0 
            write_log(sprintf('@ERROR: update_db: query failed(%s)', query),1);
        end
        mysql(h_sql, 'close');
        
        if isfp
            update_notes(task_id, 'updated,check merge');
        else
            update_notes(task_id, 'updated');
        end
    end
end

%%
function [final_segments, flag_fp, flag_size_exceed] = agglomerate_in_volume_based_mexa(vol_name, vol_idx, seeds_str)
    write_log('  [agglomerate in volume based mexa]');
    
    %parsing volume info 
    pos = strfind(vol_name, '_');
    net_prefix = vol_name(1:pos(1)-1);
    %parsing seed_set
    seed_set = str2double(split(strtrim(seeds_str)))';
    seed_set(isnan(seed_set)) = [];
    if isempty(seed_set)
        write_log('     seed is empty');
        final_segments = [];
        flag_fp = false;
        flag_size_exceed = false;
        return
    end
    
    segment_str = sprintf('%d ', seed_set);
    write_log(sprintf('     seed segment (#%d): %s', numel(seed_set), segment_str));    
    
    %read volumes (segmentation, raw image, affinity) 
    segmentation = load_segmentation_volume(vol_idx, net_prefix);    
    segment_sizes = load_segment_size(vol_idx, net_prefix, 1:max(segmentation(:)));       
    [x_affinity, y_affinity, z_affinity] = load_affinity_volume(vol_idx, net_prefix);
    
    %check size match (segmentation and affinity) to fix bug (190405)
    if ~isequal(size(segmentation), size(x_affinity))
        write_log(sprintf('     volume size does not matched. fit to affinity vol size. (%s_x%02d_y%02d_y%02d, seg=%d,%d,%d, affin=%d,%d,%d)', ...
            net_prefix, vol_idx, size(segmentation), size(x_affinity)));
        %fit to affinity size
        [size_x, size_y, size_z] = size(x_affinity);
        segmentation = segmentation(1:size_x,1:size_y,1:size_z);
    end
    
    [new_segments, isfp, istoobig] = ...
        get_agglomerated_segments(uint32(segmentation), uint32(seed_set), single(x_affinity), single(y_affinity), single(z_affinity), uint32(segment_sizes));
    
    if isempty(new_segments) || new_segments(1) < 1 || numel(seed_set) == numel(new_segments) 
        final_segments = [];
        flag_fp = false;
        flag_size_exceed = false;
        write_log('     new segment set is empty.');
        return
    end
    final_segments = new_segments;
    flag_fp = isfp;
    flag_size_exceed = istoobig;
    segment_str = sprintf('%d ', final_segments);
    write_log(sprintf('     updated segment (#%d): %s', numel(final_segments), segment_str));
end

%%
function [flag_done, cnt_new, cnt_all, stitched_ids] = spawn_task(cell_id, task_id)
    [flag_done, cnt_new, cnt_all, stitched_ids] = spawn_for_agglomerator(cell_id, 0.993, 10, task_id, 1);
end

%%
function [xidx, yidx, zidx] = extract_edge_affinity_idx(segmentation, segment1, segment2)
    size_ = size(segmentation);
    
    [x,y,z] = ind2sub(size_, find(segmentation==segment1));
    idx_seg1 = [x y z];
    [x,y,z] = ind2sub(size_, find(segmentation==segment2));
    idx_seg2 = [x y z];
    
    %compute neighbor indexes and then get contacted indexes
    %for affinity indexing
    neighbor = idx_seg1 - [1 0 0];
    bd_seg_x = intersect(neighbor, idx_seg2, 'rows');
    xidx = bd_seg_x;
    neighbor = idx_seg1 - [0 1 0];
    bd_seg_y = intersect(neighbor, idx_seg2, 'rows');
    yidx = bd_seg_y;
    neighbor = idx_seg1 - [0 0 1];
    bd_seg_z = intersect(neighbor, idx_seg2, 'rows');
    zidx = bd_seg_z;
    
    clear bd_seg_x; clear bd_seg_y; clear bd_seg_z; clear neighbor;

    neighbor = idx_seg2 - [1 0 0];
    bd_seg_x = intersect(neighbor, idx_seg1, 'rows');
    xidx = [xidx; bd_seg_x];
    neighbor = idx_seg2 - [0 1 0];
    bd_seg_y = intersect(neighbor, idx_seg1, 'rows');
    yidx = [yidx; bd_seg_y];
    neighbor = idx_seg2 - [0 0 1];
    bd_seg_z = intersect(neighbor, idx_seg1, 'rows');
    zidx = [zidx; bd_seg_z];
    
    clear bd_seg_x; clear bd_seg_y; clear bd_seg_z; clear neighbor;           

    %convert to linear index
    xidx = sub2ind(size_, xidx(:,1), xidx(:,2), xidx(:,3));
    yidx = sub2ind(size_, yidx(:,1), yidx(:,2), yidx(:,3));
    zidx = sub2ind(size_, zidx(:,1), zidx(:,2), zidx(:,3));
end

%%
function [neighbors, segmentation, seed_size] = get_neighbor_segments(segmentation, seed_set)
    %marking seed_set special number 
    seed = max(segmentation(:)) +1;
    for idx = 1:numel(seed_set)        
        segmentation(segmentation==seed_set(idx)) = seed;
    end    
    size_ = size(segmentation);
    
    %extract neighbor segments list
    lind = find(segmentation==seed);
    [x,y,z] = ind2sub(size_, lind);
    
    subind = [x y z];
    
    expand_subind = [];
    expand_subind = [expand_subind; subind-[1 0 0]];
    expand_subind = [expand_subind; subind-[0 1 0]];
    expand_subind = [expand_subind; subind-[0 0 1]];
    
    expand_subind = [expand_subind; subind+[1 0 0]];
    expand_subind = [expand_subind; subind+[0 1 0]];
    expand_subind = [expand_subind; subind+[0 0 1]];
   
    lind_neighbor = sub2ind(size_, expand_subind(:,1), expand_subind(:,2), expand_subind(:,3));
    common_lind = intersect(lind, lind_neighbor);
    lind_neighbor = setxor(lind_neighbor, common_lind);
    
    neighbors = segmentation(lind_neighbor);
    neighbors(neighbors==0) = [];
    neighbors = unique(neighbors);
    
    seed_size = numel(lind);
end
