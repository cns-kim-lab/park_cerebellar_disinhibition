function [cell_ids, all_new_cells] = get_next_cells(user)        
    cell_ids = [];
    all_new_cells = [];
    
    alive_cells = get_alive_cells(user);    
    cell_ids = alive_cells;   
    if numel(alive_cells) >= get_max_cell_th() %enough cell found
        return
    end   
    
    %create more cells
    todo_list = get_todo_list(user);
    if isempty(todo_list)
        return
    end
    
    del_irow = [];    
    for iter=1:size(todo_list,1)
        ntarget = get_max_cell_th() - numel(cell_ids);
        if ntarget < 1
            break
        end        
        new_cells = pf_cell_creator('C1a', todo_list(iter,:), ntarget);
        if isempty(new_cells) 
            del_irow = [del_irow; iter];
            write_log(sprintf(' volume done : x%02d_y%02d_z%02d', todo_list(iter,:)));
            update_finish_list_file(user, todo_list(iter,:));
            continue
        end
        if numel(new_cells) < ntarget
            del_irow = [del_irow; iter];
            write_log(sprintf(' volume done : x%02d_y%02d_z%02d', todo_list(iter,:)));
            update_finish_list_file(user, todo_list(iter,:));
        end
        
        all_new_cells = [all_new_cells; new_cells'];
        cell_ids = [cell_ids; new_cells'];
    end
    
    %remove unavailable vidx from joblist
    todo_list(del_irow,:) = [];  
    
    %update todo list
    get_todo_list(user, todo_list);
end

%%
function new_job_list = get_sorted_joblist(job_list, fin_list)
    %set center volume index
    center_vidx = [13 11 4];
    
    if ~isempty(fin_list)
        job_list = setxor(job_list, intersect(job_list, fin_list, 'rows'), 'rows');
    end

    diff = job_list - center_vidx;
    dist_array = cellfun(@norm, num2cell(diff,2));

    [~,sidx] = sort(dist_array);
    new_job_list = job_list(sidx,:); 
end

%%
function job_array = get_todo_list(username, updated_joblist)
    persistent job_list;    
    
    if nargin == 1 && ~isempty(job_list) %return joblist
        job_array = job_list;
        return
    end
    if nargin == 2  %replace joblist
        job_list = updated_joblist;
        job_array = job_list;
        return
    end
    
    %read todo file
    fid = fopen(sprintf('/data/lrrtm3_wt_pf_review/task/todo_%s', username), 'r');    
    if fid < 0 
        write_log('@ERROR: can''t find todo file.', 1);
        job_array = [];
        return
    end
    
    job_list = [];
    while ~feof(fid)
        str_line = fgetl(fid);
        vidx = sscanf(str_line, 'x%d_y%d_z%d');    
        job_list = [job_list; vidx'];
    end
    fclose(fid);
    
    finished = [];
    %read finished list file    
    fid = fopen(sprintf('/data/lrrtm3_wt_pf_review/task/finish_%s', username), 'r');
    if fid < 0 
        
    else        
        while ~feof(fid)
            str_line = fgetl(fid);        
            vidx = sscanf(str_line, 'x%d_y%d_z%d');
            finished = [finished; vidx'];
        end
        fclose(fid);
    end
    
    job_list = get_sorted_joblist(job_list, finished);    
    job_array = job_list;    
end

%%
function update_finish_list_file(username, vidx)
    fid = fopen(sprintf('/data/lrrtm3_wt_pf_review/task/finish_%s', username), 'a+');    
    if fid < 0 
        write_log(sprintf('@ERROR: can''t open finished list file for user %s.', username), 1);
        return
    end   
    fprintf(fid, 'x%02d_y%02d_z%02d\n', vidx);    
    fclose(fid);
end
