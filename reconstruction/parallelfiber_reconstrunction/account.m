function ret = account(username)
    persistent reviewer;
    
    %set
    if nargin < 1
        %do nothing (return reviewer name only)
        
    elseif isempty(reviewer) && ~isempty(username)
        reviewer = username;
        fprintf('Welcome! %s\n', reviewer);
        
        %create log file
        get_log_fid(1);         
    elseif isempty(username)
        %clean up
        get_log_fid(2);
        
        reviewer = [];        
    elseif ~strcmpi(username,reviewer)
        get_log_fid(2);        
        fprintf('Bye~ \n\n');
        
        reviewer = username;
        fprintf('Welcome! %s\n', reviewer);
        get_log_fid(1);
    end
    
    %get
    ret = reviewer;
end