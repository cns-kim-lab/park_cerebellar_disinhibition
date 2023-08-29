function joblist = overwrite_chan_job_all_done(joblist)
    [row,~] = size(joblist);
    for iter=1:row
        joblist{iter,4} = 'DONE';
    end