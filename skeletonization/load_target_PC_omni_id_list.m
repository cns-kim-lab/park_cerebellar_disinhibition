function target_cell_omni_id_list = load_target_PC_omni_id_list()

    fileID = fopen('./additional_infos/target_PC_omni_id_list.txt','r');
    data = textscan(fileID,'%d');
    target_cell_omni_id_list = data{1};
    
end