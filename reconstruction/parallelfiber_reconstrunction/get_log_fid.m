% mode_ (1: create, 2: close)
function ret = get_log_fid(mode_)
    persistent log_fid;
    [year, month, day] = ymd(datetime());
    fpath = '/data/lrrtm3_wt_pf_review/log';
    fname = sprintf('pf_%04d_%02d_%02d_%s', year, month, day, account());
    
    %only get
    if nargin < 1 
        if isempty(log_fid) || log_fid < 0
            fprintf('ERROR: get failed, file ID is invalid.\n');
        end
        ret = log_fid;
        return
    end
    
    if isempty(mode_)
        fprintf('ERROR: mode not specified.\n');
        ret = -1;
        return
    end
    
    if mode_ == 1   %create fid
        if ~isempty(log_fid) && log_fid > 2
            fprintf('file ID already exists(%d).\n', log_fid);
            ret = log_fid;
            return
        end
        log_fid = fopen([fpath '/' fname], 'a');        

        fprintf(log_fid, '\n======================================================================================================\n');
        ret = log_fid;
        return
    elseif mode_ == 2     %close file 
        if isempty(log_fid) || log_fid < 0
            fprintf('ERROR: close failed, file ID is invalid.\n');
            ret = -1;
            return
        end
        fclose(log_fid);
        log_fid = -1; 
        return
    else
        fprintf('ERROR: not implemented.\n');        
    end
    
    ret = -1;
end