function write_log(sentence, display_)
    persistent h_err;
    fid = get_log_fid(); 
    time_ = datetime();
    fprintf(fid, '%04d-%02d-%02d %02d:%02d:%02d   %s\n', ...
        time_.Year, time_.Month, time_.Day, time_.Hour, time_.Minute, floor(time_.Second), sentence);
    
    if nargin > 1 && display_
       fprintf('%s\n', sentence); 
    end
    
    if strncmpi(sentence, '@ERROR', 6) 
        if ~isempty(h_err)
            delete(h_err);
        end
        h_err = msgbox(sprintf('An error has occurred. Please contact the person in charge.\n(timestamp: %04d-%02d-%02d %02d:%02d:%02d)', ...
            time_.Year, time_.Month, time_.Day, time_.Hour, time_.Minute, floor(time_.Second)), ...
            'Error', 'error');
    end
end