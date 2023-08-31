%create fwd, chan job list
function [fwd_joblist, chan_joblist] = create_joblist(cfg)
    [chan_tbl, fwd_tbl] = create_coordinate_table_debug(cfg);
    
    %remove some columns
    chan_tbl(:,4) = [];
    %expanding cell to save time information
    [row,~] = size(chan_tbl);
    chan_tbl(:,end+1:end+2) = cell([row 2]);  
    chan_joblist = chan_tbl;
    
    fwd_tbl(:,4:8) = [];
    [row,~] = size(fwd_tbl);
    fwd_tbl(:,end+1:end+3) = cell([row 3]);
    fwd_tbl(:,4) = {'READY'};   %fill up sts
    fwd_joblist = fwd_tbl;
end
