 
%%
target_pc_dend_id_list = load_target_PC_dendrite_id_list;
target_pc_dend_id_list = double(target_pc_dend_id_list([1 2 4:14])); % omit 1802,400,402

mat_dir = '/data/research/iys0819/cell_morphology_analysis/angular_composition_around_pc_dend/result';
output_figure_dir = '/data/research/iys0819/cell_morphology_analysis/angular_composition_around_pc_dend/figures';

for i = 1:length(target_pc_dend_id_list)
    target_pc_id = target_pc_dend_id_list(i);
    dil_count_list = [5 10 15];
    for n = 1:length(dil_count_list)
        dil_count = dil_count_list(n);
        fprintf('Drawing plots for PC %d...\n',target_pc_id);
        directions_mat_path = sprintf('%s/directions_of_surrounding_volume_voxels_of_PC_%d.dilation_count_%d.self_spine_included.mat',mat_dir,target_pc_id,dil_count);
        match_mat_path = sprintf('%s/result_surrounding_volume_match_to_shaft_skeleton_of_PC_%d.dilation_count_%d.self_spine_included.mat',mat_dir,target_pc_id,dil_count);
        load(directions_mat_path);
        load(match_mat_path);

    %% dot products

        dot_root_w_hori = dot(norm_proj_root_dir,hori_dir,2);
        dot_root_w_vert = dot(norm_proj_root_dir,vert_dir,2);

    %% convert to angles
        angle_root_w_hori = acos_degeneracy_removed(dot_root_w_hori,dot_root_w_vert);
        
        angle_root_w_hori_no_type = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==0);
        angle_root_w_hori_pc = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==1);
        angle_root_w_hori_pf = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==2);
        angle_root_w_hori_cf = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==3);
        angle_root_w_hori_in = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==4);
        angle_root_w_hori_gl = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==5);
        angle_root_w_hori_gol = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==6);
        angle_root_w_hori_7 = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==7);
        angle_root_w_hori_self_spine = angle_root_w_hori(celltypes_of_surroundings_w_valid_match==8);


        polarbins = [-pi:pi/15:pi];
        polarbin_mids = (polarbins(1:end-1)+polarbins(2:end))/2;
        [N_total,~] = histcounts(angle_root_w_hori,polarbins);
        [N_zero,~] = histcounts(angle_root_w_hori_no_type,polarbins);
        [N_pc,~] = histcounts(angle_root_w_hori_pc,polarbins);
        [N_pf,~] = histcounts(angle_root_w_hori_pf,polarbins);
        [N_cf,~] = histcounts(angle_root_w_hori_cf,polarbins);
        [N_in,~] = histcounts(angle_root_w_hori_in,polarbins);
        [N_gl,~] = histcounts(angle_root_w_hori_gl,polarbins);
        [N_gol,~] = histcounts(angle_root_w_hori_gol,polarbins);
        [N_7,~] = histcounts(angle_root_w_hori_7,polarbins);
        [N_self_spine,~] = histcounts(angle_root_w_hori_self_spine,polarbins);

    %% draw

        figure;
        set(gcf,'Position',[298 820 570 420].*[1 1 3 1]);
        t = tiledlayout(1,3);
        nexttile;
    %     figure;
        polarplot([polarbin_mids polarbin_mids(1)],[N_total N_total(1)],'LineWidth',2);
        hold on;
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine N_self_spine(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_pc N_pc(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_pf N_pf(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_cf N_cf(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_in N_in(1)],'LineWidth',2);
%         polarplot([polarbin_mids polarbin_mids(1)],[N_gl N_gl(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_zero N_zero(1)],'LineWidth',2);
%         legend({'total','spine','other PCs','PF','CF','IN','GL','?/BK'});
        legend({'total','spine','other PCs','PF','CF','IN','?/BK'});
        title(sprintf('Number of Surrounding Voxels of PC %d, dil %d',target_pc_id,dil_count));
    %%
    %      figure;
        nexttile;
        polarplot([polarbin_mids polarbin_mids(1)],[N_total N_total(1)]./[N_total N_total(1)],'LineWidth',2);
        hold on;
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine N_self_spine(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_pc N_pc(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_pf N_pf(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_cf N_cf(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_in N_in(1)]./[N_total N_total(1)],'LineWidth',2);
%         polarplot([polarbin_mids polarbin_mids(1)],[N_gl N_gl(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_zero N_zero(1)]./[N_total N_total(1)],'LineWidth',2);
        legend({'total','spine','other PCs','PF','CF','IN','?/BK'});
%         legend({'total','spine','other PCs','PF','CF','IN','GL','?/BK'});
        title(sprintf('Ratio of Surrounding Voxels of PC %d, dil %d',target_pc_id,dil_count));


    %%     figure;
        nexttile;
        polarplot([polarbin_mids polarbin_mids(1)],[N_pc+N_pf+N_cf+N_in+N_gl+N_zero N_pc(1)+N_pf(1)+N_cf(1)+N_in(1)+N_gl(1)+N_zero(1)]./[N_total N_total(1)],'LineWidth',2);
        hold on;
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine, N_self_spine(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine+N_pc, N_self_spine(1)+N_pc(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine+N_pc+N_pf, N_self_spine(1)+N_pc(1)+N_pf(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine+N_pc+N_pf+N_cf, N_self_spine(1)+N_pc(1)+N_pf(1)+N_cf(1)]./[N_total N_total(1)],'LineWidth',2);
        polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine+N_pc+N_pf+N_cf+N_in, N_self_spine(1)+N_pc(1)+N_pf(1)+N_cf(1)+N_in(1)]./[N_total N_total(1)],'LineWidth',2);
%         polarplot([polarbin_mids polarbin_mids(1)],[N_self_spine+N_pc+N_pf+N_cf+N_in+N_gl, N_self_spine(1)+N_pc(1)+N_pf(1)+N_cf(1)+N_in(1)+N_gl(1)]./[N_total N_total(1)],'LineWidth',2);
%         legend({'Total','spine','other PCs','PF','CF','IN','GL'});
        legend({'Total','spine','other PCs','PF','CF','IN'});
        title(sprintf('Cumul.Dist of Surrounding Voxels of PC %d, dil %d',target_pc_id,dil_count));

        pdftitle = sprintf('%s/angular_dist_of_surr_voxels_of_PC_%d_polarhist.dilation_count_%d.self_spine_included.pdf',output_figure_dir,target_pc_id,dil_count);
        plottitle = sprintf('%s/angular_dist_of_surr_voxels_of_PC_%d_polarhist.dilation_count_%d.self_spine_included.png',output_figure_dir,target_pc_id,dil_count);
%         save_pdf_of_gcf(gcf,pdftitle);
%         saveas(gcf,plottitle);
    end
end
%%
%     figure;
%     set(gcf,'Position',[298 820 570 440].*[1 1 4 1]);
% 
%     t=tiledlayout(1,4);
%     nexttile;
%     polarplot([polarbin_mids polarbin_mids(1)],[N_pc N_pc(1)]./[N_total N_total(1)],'LineWidth',2);
%     title(sprintf('PC'));
%     nexttile;
%     polarplot([polarbin_mids polarbin_mids(1)],[N_pf N_pf(1)]./[N_total N_total(1)],'LineWidth',2);
%     title(sprintf('PF'));
%     nexttile;
%     polarplot([polarbin_mids polarbin_mids(1)],[N_cf N_cf(1)]./[N_total N_total(1)],'LineWidth',2);
%     title(sprintf('CF'));
%     nexttile;
%     polarplot([polarbin_mids polarbin_mids(1)],[N_in N_in(1)]./[N_total N_total(1)],'LineWidth',2);
%     title(sprintf('IN'));
%     title(t,sprintf('Ratio of voxels among surrounding voxels of PC %d, dil %d',target_pc_id,n));
%     pdftitle = sprintf('%s/angular_dist_of_surr_voxels_of_PC_%d_polarhist.dilation_count_%d.type_by_type.pdf',output_figure_dir,target_pc_id,n);
%     plottitle = sprintf('%s/angular_dist_of_surr_voxels_of_PC_%d_polarhist.dilation_count_%d.type_by_type.png',output_figure_dir,target_pc_id,n);
%     save_pdf_of_gcf(gcf,pdftitle);
%     saveas(gcf,plottitle);    