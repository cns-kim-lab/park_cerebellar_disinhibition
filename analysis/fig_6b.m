
%% Fig6b

load('./mat/cfpcin_syn_adjmat.mat');
load('./mat/in1_ids.mat');
load('./mat/in2_ids.mat');
load('./mat/adjmat_cfin_min6.mat');

f3=figure('Position',[500,100, 500, 450]);
imagesc(cfpcin_adjmat(1:10,31:end)); colorbar;
set(gcf,'color','w'); set(gca,'FontSize',24);
ylabel('CF'); xlabel('IN2');
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',24);


f4 = figure('Position',[500,100, 800, 600]);
num_precf = zeros(6,1);
mean_num_cf_inputs = zeros(6,1);
for i = 1:6
    a = get_syn_info('cf',in2_ids(i));
    num_precf(i) = sum(cfpcin_adjmat(1:10,30+i)>0);
    num_cf_inputs = sum(cfpcin_adjmat(1:10,30+i));
    mean_num_cf_inputs(i) = num_cf_inputs / num_precf(i);
end
violin_data = [ones(6,1),num_precf];
violin_data = [violin_data; ones(6,1)+1, mean_num_cf_inputs];
vp = violinplot(violin_data(:,2), violin_data(:,1),'ViolinColor', [0.7,0.4,0.7]);
for i = 1:2
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.7;
    vp(i).ScatterPlot.SizeData = 100;
    vp(i).BoxWidth = 0.04;
end  
violin_data2 = [num_precf;   mean_num_cf_inputs];
syntype = {'# distinct CFs', 'mean #syn / CF'};
vx2  = categorical([repmat(syntype(1), numel(in2_ids), 1); repmat(syntype(2), numel(in2_ids), 1)]);
vp2 = violinplot(violin_data2, vx2);
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
%save_figure(f4, 'cf-in31_violinplot','svg');
