function iterate_cf_ids_for_cf_skeletonization (p_scale, p_const, seg_vol_h5_path, mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

    list_of_cf_omni_id = get_omni_ids_of_a_celltype(3,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd); % type 3 : CF
    multiplier = 100;
    % p_scale = 1.2;
    % p_const = 5;

    dilate_or_not = 1;
    largest_cc_only = 0;
    draw_figure = 0;
    output_mat_file_dir = '/data/research/iys0819/cell_morphology_pipeline/result/skeleton_cf';

    vol = h5read(seg_vol_h5_path,'/main');
    % vol = h5read('/data/lrrtm3_wt_reconstruction/segment_iso_mip2_all_cells_210503.pc_cb_cut_and_int_axon_cut.sample_first_sheet.h5','/main');
    vol = vol(1:2:end,1:2:end,1:2:end);

    for i=1:length(list_of_cf_omni_id)
        target_cf_omni_id = list_of_cf_omni_id(i);
        target_cf_seg_id = target_cf_omni_id*multiplier;
        [branch_path_sub, branch_path_dbf, branch_terminal, dilation_count]= get_cf_skeleton(vol, target_cf_seg_id, p_scale, p_const, dilate_or_not, largest_cc_only, draw_figure);
        output_mat_file_path = sprintf('%s/skeleton_of_CF_%d.iso_mip3.dilated.ps_%.2f.pc_%d.mat',output_mat_file_dir,target_cf_omni_id,p_scale,p_const);
        save(output_mat_file_path,'branch_path_sub','branch_path_dbf','branch_terminal','dilation_count','target_cf_omni_id','p_scale','p_const');
    end

    draw_cf_skeletons(p_scale,p_const);

end

function id_list = get_omni_ids_of_a_celltype (type1,mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)
% types
% 1 : PC, 2:PF, 3:CF, 4:INT, 5:Glia, 6:Golgi, 0:unknown
    h_sql = connect_mysql(mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd);
    
    query = sprintf(['select cm.omni_id from cells c inner join cell_metadata cm on cm.id = c.meta_id ' ...
            'where c.status<>2 and cm.omni_id is not null ' ...
            'and cm.type1 = %d'], type1);
        
    omni_ids = mysql(h_sql,query);
    id_list = unique(omni_ids);
    mysql(h_sql,'close');

end
    
function h_sql = connect_mysql (mysql_server_hostname, mysql_db_name, mysql_db_id, mysql_db_passwd)

    addpath ./mysql/
    
    try
        h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
    catch    
        fprintf('stat - already db open, close and reopen\n');    
        mysql(h_sql,'close');
        h_sql = mysql('open',mysql_server_hostname,mysql_db_id,mysql_db_passwd);
    end

    r = mysql(h_sql, sprintf('use %d',mysql_db_name));
    if r <= 0
        fprintf('db connection fail\n');
        return;
    end
end