function [ret_ok, new_cell_id_list] = pf_cell_review_manager(cell_id_list, make_volume, suppress_report)
    addpaths();
    
    persistent review_version;
    ret_ok = 1;
    
    if nargin < 2 
        make_volume = 1;
        suppress_report = 0;
    end
    
    review_volume_under = '/data/lrrtm3_wt_pf_review/';
    user = account();
    if isempty(user)
        fprintf('Login please.\n');
        new_cell_id_list = [];
        return
    end
    
    new_cell_id_list = [];    
    if isempty(cell_id_list)
        write_log('##usage: pf_cell_review_manager(cell_id_list); ex: pf_cell_review_manager([100 101])', 1);
        return
    end
    
    write_log('[PF_CELL_REVIEW_MANAGER] -----------------------------------------------------------');
    if isempty(review_version)
        review_version = 1;
%         %delete all volume of login user
%         write_log('  delete all previous volumes');
%         execute_system_cmd(sprintf('rm -rf %sreview_volume_%s_ver*.omni*', review_volume_under, user)); 
    else
        if make_volume 
            review_version = review_version+1;
        end
    end

    db_info = get_dbinfo();       
    
    handle_sql = mysql('open', db_info.host, db_info.user, db_info.passwd);
    rtn = mysql(handle_sql, ['use ' db_info.db_name]);
    if rtn <= 0
        write_log(sprintf('@ERROR: DB open failed (host:%s, id:%s)', db_info.host, db_info.user), 1);
        return
    end
    write_log(sprintf('  DB connection established. %s:%s', db_info.host, db_info.db_name));
    
    [ret_ok, ds_id] = get_dataset_id(handle_sql);
    if ret_ok ~= 1
        write_log('@ERROR: get dataset id failed, quit.', 1);
        release_db(handle_sql);
        return
    end
    
    [ret_ok, review_cell_id] = get_review_cell_id(handle_sql, ds_id, user);
    if ret_ok ~= 1
        write_log('@ERROR: get review cell id failed, quit.', 1);
        release_db(handle_sql);
        return
    end
    
    if update_cell_status(handle_sql, review_cell_id, cell_id_list, user) ~= 1
        write_log('@ERROR: update cell status failed, quit.', 1);
        release_db(handle_sql);
        return
    end
    
    [ret_ok, review_info, new_cell_id_list] = generate_review_info(handle_sql, ds_id, user, review_cell_id, cell_id_list, review_volume_under, review_version);
    if ret_ok ~= 1
        write_log('@ERROR: generate review info failed, quit.', 1);
        release_db(handle_sql);
        return
    end
    
    release_db(handle_sql);    
    
    if isempty(review_info)
        write_log('  all cells done.', 1);
    else
        if make_volume 
            write_log('  generate volume.');
            vol_fname = sprintf('review_volume_%s_ver%d', user, review_version);
            generate_stitched_volume(review_info(:,1), vol_fname, 2, review_volume_under);
        end
    end    
    
    write_log('  quit.');
    if ~isempty(new_cell_id_list) && ~suppress_report
        pf_cell_report(new_cell_id_list);    
    end
end

%%
function ret = update_cell_status(handle_sql, rcell_id, cell_id_list, username)
    ret = 1;
    CELL_STS_COMPLETED = 1;
    CELL_STS_STASHED = 2;
    
    target_cell_id_str = sprintf('%d,', cell_id_list);
    target_cell_id_str(end) = [];
    
    write_log('  [update cell status]');
    write_log(sprintf('   your target cells(#%d): %s', numel(cell_id_list), target_cell_id_str), 1);
    write_log(sprintf('   will display cell %d', rcell_id));
    
    
    query = sprintf('SELECT notes FROM cells WHERE id=%d;', rcell_id);
    notes = mysql(handle_sql, query);
    notes = cell2mat(notes);
    
    %check this is first try of these cells
    if isempty(notes)
        write_log('   notes field is empty, first try of these cells.');
        return
    else
        match_tbl = parsing_notes(notes);
        if nnz(ismember(match_tbl(:,1), cell_id_list)) < 1
            write_log('   match cell not exists in notes field, first try of these cells.');
            return
        end
    end
    
    %check 'done' cell
    if isempty(match_tbl) 
        write_log('@ERROR: not first try, but can''t get match table.');
        ret = 0;
        return
    end

    ndrops = 0;
    ncmpl = 0;
    nrows = size(match_tbl, 1);
    query = sprintf('SELECT id FROM users WHERE name="%s";', username);
    uid = mysql(handle_sql, query);
    for ridx=1:nrows
        query = sprintf('SELECT status, segments FROM (SELECT version, status, segments FROM validations WHERE task_id=%d AND user_id=%d) t ORDER BY version DESC LIMIT 1;', ...
            match_tbl(ridx,2), uid);
        [vsts, segments] = mysql(handle_sql, query);

        if isempty(vsts)
            continue
        end
        
        if vsts ~= 2 %submitted validation not exist
            continue
        end       
        
        segments = cell2mat(segments);
        if ~isempty(segments) %'done' cell            
            msg = sprintf('   completed validation record exists. ');
            
            %check #of tasks & tasks.status for exception handling
            query = sprintf('SELECT id FROM tasks WHERE cell_id=%d AND status NOT IN (0,1,4);', match_tbl(ridx,1));
            todo_tasks = mysql(handle_sql, query);
            if ~isempty(todo_tasks)
                msg = sprintf('%s but some tasks are not in appropriate status. ', msg);
                write_log(sprintf('%s', msg));
                continue
            end
            query = sprintf('SELECT count(id) FROM tasks WHERE cell_id=%d AND status NOT IN (1,4);', match_tbl(ridx,1));
            ntasks = mysql(handle_sql, query);
            if ntasks < 2
                msg = sprintf('%s but tasks are too few(%d). ', msg, ntasks);
                write_log(sprintf('%s', msg));
                continue
            end
            
            %check review tasks's notes to designate type2 (cellbody) field
            query = sprintf('SELECT notes FROM tasks WHERE id=%d;', match_tbl(ridx,2));
            review_notes = mysql(handle_sql, query);
            review_notes = cell2mat(review_notes);
            splited_notes = strsplit(review_notes, {',', ' '}, 'CollapseDelimiters', true);
            meta_type2 = 0; %set unknown
            switch numel(splited_notes)
                case 4
                    meta_type2 = 2;
                case 5
                    if strcmpi(splited_notes{end}, 'cb') || strcmpi(splited_notes{end}, 'cellbody')
                        meta_type2 = 1;
                        write_log('   cellbody included.');
                    end
            end
            
            
            msg = sprintf('change cell %d status to DONE, cell type1 to PF.', match_tbl(ridx, 1));
            query = sprintf('UPDATE cells c INNER JOIN cell_metadata m ON m.id=c.meta_id SET c.display=0,c.status=%d,c.finished=CURRENT_TIMESTAMP,m.type1=2,m.type2=%d WHERE c.id=%d;', ...
                CELL_STS_COMPLETED, meta_type2, match_tbl(ridx,1));
            if mysql(handle_sql, query) < 0
                write_log(sprintf('%s', msg));
                write_log(sprintf('@ERROR: query failed(%s)', query));
                ret = 0;
                return
            end
            write_log(sprintf('%s >> done.', msg));
            ncmpl = ncmpl +1;
        else
            msg = sprintf('   empty validation record exists. drop cell %d. stash tasks.', match_tbl(ridx, 1));
            query = sprintf('UPDATE tasks SET status=1 WHERE cell_id=%d AND status NOT IN (1,4);', match_tbl(ridx,1));
            if mysql(handle_sql, query) < 0
                write_log(sprintf('%s', msg));
                write_log(sprintf('@ERROR: query failed(%s)', query));
                ret = 0;
                return
            end            
            msg = sprintf('%s >> done. stash cell. ', msg);
            query = sprintf('UPDATE cells SET display=0,status=%d WHERE id=%d;', CELL_STS_STASHED, match_tbl(ridx,1));
            if mysql(handle_sql, query) < 0
                write_log(sprintf('%s', msg));
                write_log(sprintf('@ERROR: query failed(%s)', query));
                ret = 0;
                return
            end
            write_log(sprintf('%s >> done.', msg));
            ndrops = ndrops +1;
        end
    end    
    write_log(sprintf('  drop %d cells, complete %d cells.', ndrops, ncmpl),1);
end

%% generate cell review info (cell_id vs review_task_id, and update status)
function [ret, review_info, new_cell_id_list] = generate_review_info(handle_sql, ds_id, username, rcell_id, cell_id_list, review_volume_under, review_volume_version)
    ret = 1;    
    review_info = [];
    new_cell_id_list = [];
    
    CELL_STS_NORMAL = 0;    
    
    target_cell_id_str = sprintf('%d,', cell_id_list);
    target_cell_id_str(end) = [];
    
    write_log('  [generate review info]');
    write_log(sprintf('   your target cells(#%d): %s', numel(cell_id_list), target_cell_id_str));
    
    rsl = cleanup_records(handle_sql, rcell_id);
    if rsl ~= 1
        write_log('@ERROR: record clean up failed.');
        ret = 0;        
        return
    end

    %check cell status
    write_log('   remove non-normal status cells.');
    cell_id_str = sprintf('%d,', cell_id_list);
    cell_id_str(end) = [];
    query = sprintf('SELECT id,status FROM cells WHERE id IN (%s);', cell_id_str);
    [new_cell_id_list, csts] = mysql(handle_sql, query);
    new_cell_id_list(find(csts~=CELL_STS_NORMAL)) = [];
    if numel(cell_id_list) ~= numel(new_cell_id_list)        
        target_cell_id_str = sprintf('%d,', new_cell_id_list);
        target_cell_id_str(end) = [];
        write_log(sprintf('   your target cells are updated(#%d): %s', numel(new_cell_id_list), target_cell_id_str), 1);
    end
    
    if isempty(new_cell_id_list)
        write_log('   target cell list is empty, done.');        
        ret = 1;
        return
    end

    %get vol id
    vol_fname = sprintf('review_volume_%s_ver%d', username, review_volume_version);
    [rsl, vid] = get_volume_id(handle_sql, ds_id, username, vol_fname, review_volume_under);
    if rsl ~= 1
        write_log('@ERROR: get volume id failed, quit.');
        ret = 0;
        return
    end 

    %generate review_task
    [rsl, review_info] = generate_review_tasks(handle_sql, new_cell_id_list, vid, rcell_id);
    if rsl~= 1
        write_log('@ERROR: generate review tasks failed.');
        ret = 0;
        return
    end

    if isempty(review_info)
        write_log('@ERROR: no review info.');
        ret = 0;
        return
    end

    msg = '   update cells notes field';
    notes_update_str = sprintf('%d,%d;', review_info');
    query = sprintf('UPDATE cells SET notes=''%s'' WHERE id=%d;', notes_update_str, rcell_id);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
        return
    end
    write_log(sprintf('%s >> done.', msg));
end

%%
function [ret, result_table] = generate_review_tasks(handle_sql, cell_id_list, vid, rcell_id)
    ret = 1;
    result_table = [];
    
    write_log('  [generate review tasks]');
    ncells = numel(cell_id_list);    
    for idx=1:ncells
        msg = sprintf('   add review task for cell %d', cell_id_list(idx));
        query = sprintf('CALL pf_add_review_task(%d,%d,%d);', rcell_id, cell_id_list(idx), vid);
        try
            rtn = mysql(handle_sql, query);                        
        catch err
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: calling procedure failed. (%s)', query), 1);
            write_log(sprintf('Please try this: \n\tpf_restore_root_task(%d);', cell_id_list(idx)), 1);
            ret = 0;
            return
        end
        
        if rtn < 0
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: query failed(%s)', query));
            ret = 0;
            return
        end
        write_log(sprintf('%s >> done.', msg));
        query = sprintf('SELECT MAX(id) FROM tasks WHERE cell_id=%d;', rcell_id);
        tid = mysql(handle_sql, query);
        result_table = [result_table; cell_id_list(idx) tid];        
    end    
    write_log(sprintf('%d tasks added.', size(result_table,1)));
end

%% clean up records (cells.notes, tasks, consensuses, validations)
function ret = cleanup_records(handle_sql, rcell_id)
    ret = 1;
    write_log('  [cleanup records]');
    
    msg = '   vacate notes field';
    query = sprintf('UPDATE cells SET notes='''' WHERE id=%d;', rcell_id);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
        return
    end
    write_log(sprintf('%s >> done.', msg));

    msg = '   clean up tasks, consensus, validation record';
    query = sprintf('DELETE c FROM tasks t LEFT JOIN consensuses c ON c.task_id=t.id WHERE t.cell_id=%d;', rcell_id);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
    end
    msg = sprintf('%s, del cons OK', msg);
    query = sprintf('DELETE v FROM tasks t LEFT JOIN validations v ON v.task_id=t.id WHERE t.cell_id=%d;', rcell_id);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
    end    
    msg = sprintf('%s, del val OK', msg);
    query = sprintf('DELETE FROM tasks WHERE cell_id=%d;', rcell_id);
    if mysql(handle_sql, query) < 0
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
        return
    end
    msg = sprintf('%s, del tasks OK', msg);
    write_log(sprintf('%s >> done.', msg));
end

%% parsing notes field to cell_id : review_task_id pair
% match_tbl = [cell_id review_task_id] xNrows;
function match_tbl = parsing_notes(notes)
    match_tbl = [];
    pairs = strsplit(notes, ';');
    npair = numel(pairs);
    for idx=1:npair
        if isempty(pairs{idx})
            return
        end
        split_rsl = strsplit(pairs{idx}, ',');
        match_tbl = [match_tbl; str2num(strtrim(split_rsl{1})) str2num(strtrim(split_rsl{2}))];
    end    
end


%% generates stitched volume
function generate_stitched_volume(cell_id_list, fname, mip_level, review_volume_under)
    if nargin < 3 || isempty(mip_level)
        mip_level = 2;
    end

    % generate --------------------------------------------------------
    write_log(sprintf('  [generate stitched volume (mip_level %d)]', mip_level));
    
    %use silent option
    lrrtm3_stitch_volume_no_dupl_check_pf(fname, mip_level, cell_id_list, 3, 1);
    
    write_log('   post processing start.', 1);
    %post process of stitched volume
    %cp segment_page file    
    page_file_path = sprintf('%s%s.omni.files/users/_default/segmentations/segmentation1/segments/', review_volume_under, fname);
    [~, output_] = system(sprintf('find %ssegment_page*.data.ver', page_file_path));
    page_files = strsplit(output_, '\n');
    page_num_list = [];
    msg = [];
    for iter=1:numel(page_files)
        if isempty(page_files{iter})
            continue
        end
        page_num = sscanf(page_files{iter}, [sprintf('%ssegment_page', page_file_path) '%d' '.data.ver']);
        page_num_list = [page_num_list; page_num];
        msg = sprintf('%s %d', msg, page_num);
    end
    write_log(sprintf('exist segment_page file list: %s', msg));
    
    if max(page_num_list) > 0
        cur_page = max(page_num_list);
        for iter=cur_page-1:-1:0
            exist_ = find(page_num_list==iter,1);
            if isempty(exist_) %cp page file
                execute_system_cmd(sprintf('cp %ssegment_page%d.data.ver %ssegment_page%d.data.ver', page_file_path, iter+1, page_file_path, iter));
                execute_system_cmd(sprintf('cp %ssegment_page%d.data.ver4 %ssegment_page%d.data.ver4', page_file_path, iter+1, page_file_path, iter));
                execute_system_cmd(sprintf('cp %ssegment_page%d.list_types.ver4 %ssegment_page%d.list_types.ver4', page_file_path, iter+1, page_file_path, iter));
            end            
        end        
    end   
    
    %chg file ownership    
    execute_system_cmd(sprintf('chown -R :kimlab_tracer %s%s.omni*', review_volume_under, fname));
    
    execute_system_cmd(sprintf('rm -rf %s%s.h5', review_volume_under, fname));    
    execute_system_cmd(sprintf('rm -rf %somnify_%s.cmd', review_volume_under, fname));
    
    %channel symlink
    chann_prj_path = sprintf('/data/lrrtm3_wt_reconstruction/both_mip%d_all_cells_complete.omni.files', mip_level);
    prj_path = sprintf('%s%s.omni.files', review_volume_under, fname);    
    execute_system_cmd(sprintf('ln -s %s/channels %s/', chann_prj_path, prj_path));
    
    %merge yaml
    yaml_fname = 'projectMetadata.yaml';    
    merge_metadatafile(sprintf('%s/%s', chann_prj_path, yaml_fname), sprintf('%s/%s', prj_path, yaml_fname), sprintf('%s/%s.temp', prj_path, yaml_fname));    
    execute_system_cmd(sprintf('mv %s/%s.temp -f %s/%s', prj_path, yaml_fname, prj_path, yaml_fname));
    execute_system_cmd(sprintf('chmod 660 %s/%s', prj_path, yaml_fname));
    execute_system_cmd(sprintf('chown :kimlab_tracer %s/*.yaml*', prj_path)); 
    
    write_log('   post processing done.', 1);
end

%%
function execute_system_cmd(syscmd, print_flag)
    if nargin < 2 || isempty(print_flag) || print_flag
        write_log(sprintf('     %s', syscmd));
    end
    system(syscmd);
end

%% get volume id 
function [ret, vid] = get_volume_id(handle_sql, ds_id, username, vol_fname, review_volume_under)
    ret = 1;
    
    write_log(sprintf('  [get volume id of %s]', vol_fname));
    query = sprintf('SELECT id FROM volumes WHERE dataset_id=%d AND net_id=''%s'';', ds_id, username);
    vid = mysql(handle_sql, query);
    if ~isempty(vid)
        write_log(sprintf('   volumd_id: %d', vid));
        query = sprintf('UPDATE volumes SET PATH=''%s%s.omni'' WHERE id=%d;', review_volume_under, vol_fname, vid);
        if mysql(handle_sql, query) < 0 
            write_log(sprintf('@ERROR: query failed(%s)', query));
            ret = 0;
            vid = 0;
        end
        return
    end
    
    msg = '   insert volume info to DB';
    %insert volume info
    query = sprintf('INSERT INTO volumes (dataset_id,net_id,path,vx,vy,vz) VALUES (%d,''%s'',''%s'',0,0,0);', ...
        ds_id, username, sprintf('%s%s.omni', review_volume_under, vol_fname));
    if mysql(handle_sql, query) < 0 
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: query failed(%s)', query));
        ret = 0;
        return
    end
    write_log(sprintf('%s >> done.', msg));
    
	query = sprintf('SELECT id FROM volumes WHERE dataset_id=%d AND net_id=''%s'';', ds_id, username);
    vid = mysql(handle_sql, query);
    if isempty(vid)
        write_log('@ERROR: volume info inserted, but can''t find.');
        ret = 0;
        return
    end 
    write_log(sprintf('   volumd_id: %d', vid));
end


%% get review cell id of user
function [ret, review_cell_id] = get_review_cell_id(handle_sql, ds_id, username)
    ret = 1;
    
    write_log('  [get review cell id]');
    query = sprintf('SELECT c.id FROM cells c LEFT JOIN cell_metadata m ON m.id=c.meta_id WHERE m.name LIKE ''reviewer_%s'';', username);
    review_cell_id = mysql(handle_sql, query);
    if ~isempty(review_cell_id)
        write_log(sprintf('   review cell id: %d.', review_cell_id));
        return
    end
    msg = '   insert review cell';
    query = sprintf('CALL pf_add_review_cell(%d,''reviewer_%s'');', ds_id, username);
    try
        if mysql(handle_sql, query) < 0 
            write_log(sprintf('%s', msg));
            write_log(sprintf('@ERROR: query failed(%s)', query));
            ret = 0;
            return
        end       
    catch err
        [err_lv, err_code, err_msg] = mysql(handle_sql, query);
        write_log(sprintf('%s', msg));
        write_log(sprintf('@ERROR: calling procedure failed. (%s)', query), 1);
        ret = 0;
        return
    end
    write_log(sprintf('%s >> done.', msg));
    
    query = sprintf('SELECT c.id FROM cells c LEFT JOIN cell_metadata m ON m.id=c.meta_id WHERE m.name LIKE ''reviewer_%s'';', username);
    review_cell_id = mysql(handle_sql, query);
    if isempty(review_cell_id)
        write_log('@ERROR: review cell added, but can''t find.');
        ret = 0;
        return
    end        
    write_log(sprintf('   review cell id: %d.', review_cell_id));
end


%% get datasets (error: ret ~= 1) 
function [ret, ds_id] = get_dataset_id(handle_sql)
    ret = 1;
    
    write_log('  [get dataset id]');    
    query = sprintf('SELECT id FROM datasets WHERE name=''lrrtm3_review'';');
    ds_id = mysql(handle_sql, query);
    if isempty(ds_id)        
        write_log('@ERROR: review dataset not exists.');
        ret = 0;
        return
    end
    write_log(sprintf('   dataset_id: %d', ds_id));
end


%%
function release_db(handle)
    mysql(handle, 'close');
    write_log('DB connection released.');
end

