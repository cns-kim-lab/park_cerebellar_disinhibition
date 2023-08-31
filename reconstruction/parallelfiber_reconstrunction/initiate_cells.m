function new_cells = initiate_cells(user)
    [cell_ids, new_cells] = get_next_cells(user);
    if isempty(cell_ids)
        write_log('@ERROR: can''t get next cell ids.', 1);
    end   
    
    if isempty(new_cells)   %all cells are old         
        %(do not generate review volume, do not print cell report)
        [success, ~] = pf_cell_review_manager(cell_ids, 0, 1);
        if success ~= 1 
            write_log('quit initiate_cells.');
            new_cells = 1;
            return
        end
    else %new cells exist
        %make review volume for first review (check root tasks)
        [success, ~] = pf_cell_review_manager(cell_ids, 1, 1);        
        if success ~= 1 
            write_log('quit initiate_cells.');
            new_cells = 1;
            return
        end
        
        write_log('  Review root tasks to proceed.', 1);
        cell_id_str = sprintf('%d,', new_cells);
        cell_id_str(end) = [];
        write_log(sprintf('  new cells(#%d): %s', numel(new_cells), cell_id_str), 1);
        
        msgbox('Please check root tasks of new cells.', 'Info', 'help');
    end
end