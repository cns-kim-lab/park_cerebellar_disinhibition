function batch_create_todo_list()
    all_cube = remove_finished_job(get_all_job());

    user = "daniel";
    write_joblist(user, get_joblist(all_cube, user));

    user = "hnseo";
    write_joblist(user, get_joblist(all_cube, user));

    user = "jwshin";
    write_joblist(user, get_joblist(all_cube, user));

    user = "jwyun";
    write_joblist(user, get_joblist(all_cube, user));

    user = "jykim";
    write_joblist(user, get_joblist(all_cube, user));
end

%%
function write_joblist(username, job_list)
    fid = fopen(sprintf('/data/lrrtm3_wt_pf_review/task/todo_%s', str2mat(username)), 'w+');    
    for ijob=1:size(job_list, 1)
        fprintf(fid, 'x%02d_y%02d_z%02d\n', job_list(ijob,:));
    end   
    fclose(fid);
end    

%%
function all_job = get_all_job()
    center_vidx = [13 11 4];
    all_vidx = [];
    for y=1:22
        for x=1:31
            all_vidx = [all_vidx; [x y 4]];
        end
    end
    
    diff = all_vidx - center_vidx;
    dist_array = cellfun(@norm, num2cell(diff, 2));
    
    [~,sidx] = sort(dist_array);
    all_job = all_vidx(sidx,:);
end

%%
function remain_job = remove_finished_job(all_job)
    username_list = ["daniel"; "hnseo"; "jwshin"; "jwyun"; "jykim";];
    finished_list = [];
    for user_=1:size(username_list,1)        
        %read finished list file
        fid = fopen(sprintf('/data/lrrtm3_wt_pf_review/task/finish_%s', username_list(user_,:)), 'r');
        if fid < 0 %if finish file not exist, return todo list        
            continue
        end

        while ~feof(fid)
            str_line = fgetl(fid);        
            vidx = sscanf(str_line, 'x%d_y%d_z%d');
            finished_list = [finished_list; vidx'];
        end
        fclose(fid);    
    end
    
    if isempty(finished_list)  
        remain_job = all_job;
        return
    end
    
    finished_list = unique(finished_list, 'rows');    
    remain_job = setxor(all_job, intersect(all_job, finished_list, 'rows'), 'rows');
end

%%
function job_list = get_joblist(all_job, username)
    nrows = size(all_job,1);
    ntracers = 5;
    
    start_ = 0;
    if strcmp(username, "daniel")
        start_ = 1;
    elseif strcmp(username, "hnseo")
        start_ = 2;
    elseif strcmp(username, "jwshin")
        start_ = 3;
    elseif strcmp(username, "jwyun")
        start_ = 4;
    elseif strcmp(username, "jykim")
        start_ = 5;
    end
    
    my_idx = start_:ntracers:nrows;
    job_list = all_job(my_idx,:);
end

