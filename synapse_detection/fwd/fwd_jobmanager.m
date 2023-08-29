function fwd_jobmanager(detection_type)

jobconfig_path = ['/data/research/kaffeuser/lrrtm3_syn_detection/cfg_', detection_type, '.txt'];

if exist('jobconfig_path', 'var') < 1
    disp('@jobconfig_path needed');
    return
end

if ~isdeployed
    addpath('/data/research/cjpark147/code/hdf5_ref/');
end

if ~isdeployed
    joblist_fwd_path = '/job_table_fwd.txt';
    joblist_chan_path = '/job_table_chan.txt';
    ststable_path = '/sts_table.txt';
else
    joblist_fwd_path = ['/job_table_fwd_' phase '.txt'];
    joblist_chan_path = ['/job_table_chan_' phase '.txt'];
    ststable_path = ['/sts_table_' phase '.txt'];
end


%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);
[job_default_path,~] = get_cfg(jobcfg, 'job_default_path');
[netname,~] = get_cfg(jobcfg, 'netname');

job_list_fullpath_chan = [job_default_path netname joblist_chan_path];
job_list_fullpath_fwd = [job_default_path netname joblist_fwd_path];
sts_fullpath = [job_default_path netname ststable_path];

%create joblist (fwd, channel image generation) 
%jobid, startp, endp, status, starttime, endtime
[fwd_joblist, chan_joblist] = create_joblist(jobcfg);   %job list status value: 'READY', 'ING', 'DONE'
[fwd_joblist, chan_joblist] = check_previous_job_by_file_exist(jobcfg, fwd_joblist, chan_joblist);  %check finished job

%save joblist as file
format = 'id: %5d %5d %5d, start: %5d %5d %5d, end: %5d %5d %5d, sts: %s, time: %s to %s\n';
save_joblist_as_file(job_list_fullpath_fwd, format, fwd_joblist);
save_joblist_as_file(job_list_fullpath_chan, format, chan_joblist);
%%
[row_chan,~] = size(chan_joblist);
[row_fwd,~] = size(fwd_joblist);

if (row_chan < 1 || row_fwd < 1)
    disp(['no job, chan=' num2str(row_chan) ', fwd=' num2str(row_fwd)]);
    return
end

%create fwd spec file
create_fwd_specfile(jobcfg, fwd_joblist);

% initialize status table %node, gpuid, jobid, joblist_ridx, status, starttime
sts_table = create_sts_table(jobcfg);   %sts table status value: 'IDLE', 'RUN'
save_sts_table_as_file(sts_fullpath, sts_table);


chan_job_completed = 'PROCESSING';
fwd_job_completed = 'PROCESSING'; 

%chan joblist table overwrite (all done)
%chan_joblist = overwrite_chan_job_all_done(chan_joblist);   %%

chan_ridx = get_next_chan_job_index(chan_joblist);
fwd_ridx = get_next_fwd_job_index(fwd_joblist);  

pause_time = 1;
while(1)       
    disp(datetime('now'));
    if chan_ridx > row_chan
        chan_job_completed = 'COMPLETED';
    end
    
    fwd_job_completed = is_complete_job(fwd_joblist);     
    [fwd_remain, chan_remain] = get_cnt_remain_job(fwd_joblist, chan_joblist);
    disp(['[cur status] fwd_job: ' fwd_job_completed ', chan_job: ' chan_job_completed]); 
    disp(['[remain job] fwd_job: ' num2str(fwd_remain) ', chan_job: ' num2str(chan_remain)]);
    
    %all job finished
    if strcmpi(chan_job_completed, 'COMPLETED') && strcmpi(fwd_job_completed, 'COMPLETED')
        disp(['chan : ' chan_job_completed ', fwd : ' fwd_job_completed]);
        disp('all job done');
        break
    end
    %fwd job 
    if strcmpi(fwd_job_completed, 'PROCESSING')    %not completed
        %check sts_table for idle gpu
        sts_ridx = get_idle_gpu_in_sts_table(sts_table);
        if sts_ridx > 0 %idle gpu exist (in sts_table)
            fwd_joblist = cropNsave_fwd_input_cube(jobcfg, fwd_joblist, fwd_ridx);
            create_fwd_cfgfile(jobcfg, fwd_joblist, fwd_ridx);
            [sts_table, fwd_joblist] = start_fwd(jobcfg, sts_table, sts_ridx, fwd_joblist, fwd_ridx);
            save_joblist_as_file(job_list_fullpath_fwd, format, fwd_joblist);
            save_sts_table_as_file(sts_fullpath, sts_table);
            fwd_ridx = get_next_fwd_job_index(fwd_joblist);
            continue
        end
        %check node for idle gpu
        [sts_table, fwd_joblist, exist_done] = check_finished_fwd(sts_table, fwd_joblist, jobcfg);
        if exist_done %idle gpu exist (in remote node)
            sts_ridx = get_idle_gpu_in_sts_table(sts_table);    %get sts_table index of idle gpu
            fwd_joblist = cropNsave_fwd_input_cube(jobcfg, fwd_joblist, fwd_ridx);
            create_fwd_cfgfile(jobcfg, fwd_joblist, fwd_ridx);
            [sts_table, fwd_joblist] = start_fwd(jobcfg, sts_table, sts_ridx, fwd_joblist, fwd_ridx);
            save_joblist_as_file(job_list_fullpath_fwd, format, fwd_joblist);
            save_sts_table_as_file(sts_fullpath, sts_table);
            fwd_ridx = get_next_fwd_job_index(fwd_joblist);
            continue
        else
            pause_time = 1*30;
        end
    elseif strcmpi(fwd_job_completed, 'FORWARDING' ) %only fwd left
        [sts_table, fwd_joblist, exist_done] = check_finished_fwd(sts_table, fwd_joblist, jobcfg);
        save_sts_table_as_file(sts_fullpath, sts_table);
        if exist_done   %if finished job exist, fwd_joblist table update and continue
            save_joblist_as_file(job_list_fullpath_fwd, format, fwd_joblist);
            continue
        end        
        pause_time = 1*30;
    end
    
    %chan job 
    if strcmpi(chan_job_completed, 'COMPLETED') ~= 1        
        chan_joblist = cropNsave_chan_cube(jobcfg, chan_joblist, chan_ridx);
        save_joblist_as_file(job_list_fullpath_chan, format, chan_joblist);
        disp(['chan_jobidx: ' num2str(chan_ridx) ' done']);
        chan_ridx = get_next_chan_job_index(chan_joblist);
        pause_time = 1;
    end    
    pause(pause_time);  
end
end
