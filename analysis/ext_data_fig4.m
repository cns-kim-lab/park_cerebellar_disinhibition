load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
load('/data/research/cjpark147/conn_analysis/in_soma_centroid.mat');
load('/data/research/cjpark147/conn_analysis/in1_in2_densi_complx_syn_pcl_distrib.mat');

%% SC/BC vs. IN1/IN2 4 figures with Mann-Whitney U Test

%Mann-Whitney U Test:
[p1,h01,stats1] = ranksum(in1_dend_density, in2_dend_density);
[p2,h02,stats2] = ranksum(in1_axon_complexity, in2_axon_complexity);
[p3,h03,stats3] = ranksum(in1_pcl_distance, in2_pcl_distance);
[p4,h04,stats4] = ranksum(in1_syn_dist_pcl, in2_syn_dist_pcl); 

% 1) dend density

sf1=figure('Position',[100 500 700 550]);
violin_data1= [[in1_dend_density; in2_dend_density], [ones(numel(in1_dend_density),1); ones(numel(in2_dend_density),1)*2]];
vp = violinplot(violin_data1(:,1), violin_data1(:,2), 'ViolinColor', [255,70,70]/255); 
vp(2).ViolinColor = [70,120,210]/255;
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
set(gcf,'Color','w'); set(gca,'FontSize',24); ylabel('Dendrite density');
hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); %ylim([min(yt),max(yt)*1.15]);
plot(xt([1 2]), [1 1]*max(yt)*1.05, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.1, 'n.s.', 'FontSize',24);

% 2) axon complexity
sf2=figure('Position',[100 500 700 550]);
violin_data2= [[in1_axon_complexity; in2_axon_complexity], [ones(numel(in1_axon_complexity),1); ones(numel(in2_axon_complexity),1)*2]];
vp = violinplot(violin_data2(:,1), violin_data2(:,2), 'ViolinColor', [255,70,70]/255); 
vp(2).ViolinColor = [70,120,210]/255;
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
set(gcf,'Color','w'); set(gca,'FontSize',24); ylabel('Axon complexity');
hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); ylim([min(yt),max(yt)*1.15]); 
plot(xt([1 2]), [1 1]*max(yt)*1.05, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.1, '*', 'FontSize',24);

% 3) PCL soma distance
sf3=figure('Position',[100 500 700 550]);
violin_data3= [[in1_pcl_distance; in2_pcl_distance], [ones(numel(in1_pcl_distance),1); ones(numel(in2_pcl_distance),1)*2]];
vp = violinplot(violin_data3(:,1), violin_data3(:,2), 'ViolinColor', [255,70,70]/255); 
vp(2).ViolinColor = [70,120,210]/255;
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
set(gcf,'Color','w'); set(gca,'FontSize',24); ylabel('Soma distance from PCL');
hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); %ylim([min(yt),max(yt)*1.15]); 
plot(xt([1 2]), [1 1]*max(yt)*1.05, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.1, 'n.s.', 'FontSize',24);

% 4) PCL synapse distance
sf4=figure('Position',[100 500 700 550]);
violin_data4= [[in1_syn_dist_pcl; in2_syn_dist_pcl], [ones(numel(in1_syn_dist_pcl),1); ones(numel(in2_syn_dist_pcl),1)*2]];
vp = violinplot(violin_data4(:,1), violin_data4(:,2), 'ViolinColor', [255,70,70]/255); 
vp(2).ViolinColor = [70,120,210]/255;
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
set(gcf,'Color','w'); set(gca,'FontSize',24); ylabel('Syn distance from PCL');
hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); %ylim([min(yt),max(yt)*1.15]); 
plot(xt([1 2]), [1 1]*max(yt)*1.05, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.1, 'n.s.', 'FontSize',24);

%}
