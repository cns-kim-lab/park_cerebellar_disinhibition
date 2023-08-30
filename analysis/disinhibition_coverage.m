
%% Disinhibition coverage  
  
% For each PC: Find fraction of silenced inhibitory synpases 

load('/data/research/cjpark147/conn_analysis/pc_soma_centroid.mat');
pc_ids = [18,11,4,13,21,20,49,50,3,175];
cf_ids = [463;227;7;681;453;772;878;931;166;953];

target_ids = pc_ids;
in1_syn_to_pc = get_syn_info([in1_ids; frag_axon_in1], pc_ids);
in2_syn_to_pc = get_syn_info([in2_ids; frag_axon_in2], pc_ids);
pf_syn_to_pc = get_syn_info('pf',pc_ids);
cf_syn_to_pc = get_syn_info(cf_ids,pc_ids);
fontsize=19;

for i = 1:numel(target_ids)


    cfin_data_path = '/data/lrrtm3_wt_syn/cfin_syn_min6.txt';
    cfin_data = readtable(cfin_data_path);    
    in1_prepc = get_pre_id(in1_ids, target_ids(i), 1);
    in1pc_info = get_syn_info(in1_prepc, target_ids(i));
    [num_syn_in1pc,~] = size(in1pc_info);
    contact_size_total = sum(in1pc_info(:,7));
    
    idx = (ismember(cfin_data.seg_pre, cf_ids(i)) & ismember(cfin_data.seg_post, in2_ids));
    in2_postcf = unique(cfin_data.seg_post(idx));
    in1_postin2 = get_post_id(in2_postcf, in1_ids,1);
    in1pc_silenced_info = get_syn_info(in1_postin2, target_ids(i));
    [num_syn_in1pc_sil,~] = size(in1pc_silenced_info);
    contact_size_suppressed = sum(in1pc_silenced_info(:,7));
    y_data = [num_syn_in1pc, num_syn_in1pc_sil];
    contact_size_data = [contact_size_total, contact_size_suppressed];
    num_cell_data = [numel(in1_prepc), numel(unique(in1pc_silenced_info(:,3)))];
    
    f5 = figure('Position',[100 500 850 600]);
    y_data_frac = y_data(:,2) ./y_data(:,1);
    size_data_frac = contact_size_data(:,2) ./ contact_size_data(:,1);
    num_cell_frac = num_cell_data(:,2) ./ num_cell_data(:,1);
    mu1 = mean(y_data_frac); mu2 = mean(size_data_frac);  mu3 = mean(num_cell_frac);
    mus = [mu3;mu1;mu2]*100;
    barcolor = [82,125,205;  45,60,135;  5,3,62]/255;
    for j = 1:3
        handle = bar(j,mus(j),'BarWidth',0.7); hold on;
        xb = get(handle,'XData').' + [handle.XOffset];
        set(handle, 'FaceColor', barcolor(j,:));
    end
    ylabel('Disinhibition coverage (%)');
    ylim([0,100]);
    set(gcf,'color','w'); xticks([1 2 3]); set(gca,'FontSize',fontsize, 'FontName', 'Helvetica','XTickLabel', {'cell', 'syn',  'area'})
    save_figure(f5, ['/sfig/pc/dicoverage', num2str(target_ids(i))], 'pdf');
    close all;
end



%% Previous version

%{
addpath /data/research/cjpark147/conn_analysis
%load('/data/research/cjpark147/conn_analysis/target_cell_ids.mat');
load('in1_ids'); load('in2_ids'); 

%npc = numel(good_pc_ids); 
nin2 = numel(in2_ids); nin1 = numel(in1_ids); 
%ncf = numel(cf_id);

cfin_data_path = '/data/lrrtm3_wt_syn/cfin_syn_info_220224.txt';
%cfin_data_path = '/data/lrrtm3_wt_syn/cfin_syn_score8.txt';
cfin_data = readtable(cfin_data_path);

% target PCs were selected based on the size of dendrites. 
% dendrites with "sufficient size" were selected. 
% dendrite of 13 is quite small, but it has a cell body. 
target_pc_id = [18,11,21,4,20,49,13];  % sorted by dendrite volume. [81,82] locate at boundaries.
corr_cf_id =  [463,227,453,7,772,878,681]; 
y_data = zeros(numel(target_pc_id), 2);
for i = 1:numel(target_pc_id)
    this_pc = target_pc_id(i);
    this_cf = corr_cf_id(i);
    in1_prepc = get_pre_id(in1_ids, this_pc, 1);
    in1pc_info = get_syn_info(in1_prepc, this_pc);
    [num_syn_in1pc,~] = size(in1pc_info);      
    
    idx = (ismember(cfin_data.seg_pre, this_cf) & ismember(cfin_data.seg_post, in2_ids));
    in2_postcf = unique(cfin_data.seg_post(idx));
    in1_postin2 = get_post_id(in2_postcf, in1_ids,1);
    in1pc_silenced_info = get_syn_info(in1_postin2, this_pc);
    [num_syn_in1pc_sil,~] = size(in1pc_silenced_info);
    
    y_data(i,1) = num_syn_in1pc;
    y_data(i,2) = num_syn_in1pc_sil;        
end

h = figure;
b = bar(y_data, 'BarWidth', 0.6);
title('#Silenced synapses by CF->IN2->IN1 path' );
ylabel('Number of synapses'); 
b(1).FaceColor = [56,62,86]/256;
b(2).FaceColor = [246,158,123]/256;
%b(3).FaceColor = [238,218,209]/256;
%b(4).FaceColor = [0,85,133]/256;
set(gcf,'color','w');
set(gca,'Fontsize', 20, 'XTickLabel', {'PC-4', 'PC-11', 'PC-13', 'PC-18', 'PC-21', 'PC-49', 'PC-20'});
legend({'All ', 'Silent'}, 'FontSize',22);
set(gca, 'FontSize',22);
%}


%% save as pdf
%{
set(gcf, 'Units','Inches');
pos = get(gcf,'Position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(gcf,'/data/research/cjpark147/figure/inpc_syn_dist_from_pcl_violin','-dpdf','-r0');
%}
