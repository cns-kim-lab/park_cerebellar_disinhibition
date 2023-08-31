function celldone(cell_ids, cell_type, cellbody_included)
    switch nargin
        case 1
            type1 = 0;
            type2 = 0;
        case 2
            type1 = get_type1(cell_type);
            type2 = 0;
        case 3
            if ~isempty(cell_type)
                type1 = get_type1(cell_type);
            else
                type1 = 0;
            end
            type2 = get_type2(cellbody_included);            
        otherwise
            fprintf('usage: celldone([cell_ids], celltype, cellbody_flag);\n   >> ex) celldone(100, ''purkinje'', ''yes'');\n');
            return
    end    
    if type1 < 0 || type2 < 0
        fprintf('invalid type value(type1: %d, type2: %d)\n', type1, type2);
        return
    end
    
     process_path = '/data/lrrtm3_wt_code/process/celldone';
     log_path = '/data/lrrtm3_wt_omnivol/cell_trace_data/log_acc_process/';
       
    
    for cell_id=cell_ids
        cmd = sprintf('%s %s %d %d %d', process_path, get_endpoint(), cell_id, type1, type2);
        output = execute_with_logging(log_path, 'celldone', cmd);
        fprintf('%s', output);
    end
end

function typeval = get_type1(celltype)
    celltype_dictionary = ["pc";"purkinje";"purkinje cell"; "pf";"parallel fiber"; "cf"; "climbing fiber"; "int"; "interneuron"; "glia";];
    idx = find(celltype_dictionary==lower(celltype), 1);
    if isempty(idx)
        fprintf('Unknown celltype : %s\n', celltype);
        typeval = -1;
        return
    else    
        switch idx
            case 1  %pc
                typeval = 1;
            case 2  %pc
                typeval = 1;
            case 3  %pc
                typeval = 1;
            case 4  %pf
                typeval = 2;
            case 5  %pf
                typeval = 2;
            case 6  %cf
                typeval = 3;
            case 7  %cf
                typeval = 3;
            case 8  %int
                typeval = 4;
            case 9  %int
                typeval = 4;
            case 10 %glia
                typeval = 5;
            otherwise
                fprintf('Unknown celltype : %s\n', celltype);
                typeval = -1;
                return
        end
    end    
end

function typeval = get_type2(cellbody_included)
    cellbodytype_dictionary = ["yes";"no";"y";"n"];
    idx = find(cellbodytype_dictionary==lower(cellbody_included), 1);
    if isempty(idx)
        fprintf('Unknown cellbody included flag : %s\n', cellbody_included);
        typeval = -1;
        return
    else
        switch idx
            case 1  %yes
                typeval = 1;
            case 2  %no
                typeval = 2;
            case 3  %y
                typeval = 1;
            case 4  %n
                typeval = 2;
            otherwise
                fprintf('Unknown cellbody included flag : %s\n', cellbody_included);
                typeval = -1;
                return
        end
    end    
end
