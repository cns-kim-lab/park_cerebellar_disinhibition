function [ret, valid] = get_cfg(cfg, fieldname)
    cidx = find(strcmpi(fieldname, cfg(:,1)),1);
    if isempty(cidx)
        disp(['@not exist field :' fieldname]);
        %not exist field
        ret = -1;  
        valid = 0;
        return
    end
    
    ret = cfg{cidx, 2};
    valid = 1;
    return
