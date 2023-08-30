
%% Morphological properties of SC and BC  

load('/data/research/cjpark147/conn_analysis/in_skeleton/27int_graph_dend_and_axon_20210324.mat'); 
load('/data/research/cjpark147/conn_analysis/in_skeleton/27int_branch_info_dendNaxon_20210324.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
%load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
cell_removed = 19;  nin_temp = numel(target_interneurons_new);
idx_removed = find(target_interneurons_new==cell_removed);
nin = numel(target_interneurons_new) - numel(cell_removed);
markersize = 125; fontsize = 22; markercolor = [50 120 220]/255;

% Dendrite density vs PCL 
f3d1 = figure('Position',[300 800 600 500]);
%t = tiledlayout(3,1, 'TileSpacing','compact');
is_in1 = zeros(nin_temp,1);
%nexttile;
dend_total_length = zeros(nin,1); convex_hull = zeros(nin,1); pcl_dist = zeros(nin,1);
cell_id_temp = zeros(nin,1);
for i = 1:nin_temp
    if ~ismember(i, idx_removed)
        dend_total_length(i) = sum(int_dend_branch_info(i).branch_length);
        dend_coord = vertcat(int_dend_branch_info(i).Node_coord{:});
        cell_id_temp(i) = target_interneurons_new(i);
        [~,av] = convhull(dend_coord(:,1), dend_coord(:,2));
        convex_hull(i) = av;    
        idx = find(target_interneurons_new(i) == in_dist_from_pcl(:,1));
        pcl_dist(i) = in_dist_from_pcl(idx,2);
        if ismember(target_interneurons_new(i), in1_ids)
            is_in1(i) = 1;
        end
    end
end
dend_total_length(idx_removed) = []; convex_hull(idx_removed) = []; pcl_dist(idx_removed)=[]; is_in1(idx_removed)=[];
dend_density = dend_total_length./convex_hull;
scatter(pcl_dist, dend_density, markersize, markercolor,'filled'); hold on;
ax=gca; ax.YAxis.Exponent=-3;
h1 = lsline; h1.Color = damson_blk; h1.LineWidth = 1.2; h1.LineStyle = '--';
dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
corr_coef = corrcoef(pcl_dist, dend_density);

in1_idx = is_in1 > 0;
scatter(pcl_dist(in1_idx), dend_density(in1_idx), markersize, coral, 'filled');
legend(dummyh, {['r = ', num2str(corr_coef(1,2))]}, 'FontSize', fontsize); legend boxoff;
xlabel('{\it d}_I_N (\mum)'); ylabel('Dendrite density');
set(gcf,'color','w'); set(gca,'FontSize',fontsize); %axis square;

% Axon complexity vs PCL
f3d2 = figure('Position',[300 800 600 500]);
axon_total_length = zeros(nin,1); num_branch_point = zeros(nin,1); 
for i = 1:nin_temp
    if ~ismember(i, idx_removed)
        axon_total_length(i) = sum(int_axon_branch_info(i).branch_length);
        [num_branch_point(i),~] = size(int_axon_branch_info(i).branching_point_coord);
    end
end
num_branch_point(idx_removed) = []; axon_total_length(idx_removed) = [];
axon_complexity = num_branch_point./axon_total_length;
scatter(pcl_dist, axon_complexity, markersize, markercolor,'filled'); hold on;
ax=gca; ax.YAxis.Exponent=-4;
h2 = lsline; h2.Color = damson_blk; h2.LineWidth = 1.2; h2.LineStyle = '--';
corr_coef = corrcoef(pcl_dist, axon_complexity);
scatter(pcl_dist(in1_idx), axon_complexity(in1_idx), markersize, coral, 'filled');

dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
legend(dummyh, {['r = ', num2str(corr_coef(1,2))]}, 'FontSize', fontsize);  legend boxoff;
xlabel('{\it d}_I_N (\mum)'); ylabel('Axon complexity'); ylim([min(axon_complexity)*0.9, max(axon_complexity)*1.05]);
set(gcf,'color','w'); set(gca,'FontSize',fontsize); %axis square;


% Mean IN-PC syn distance vs PCL
pcl_plane_normal = [-0.848147309991681, -0.525879404662518, 0.064007751918581];   %isotropic mip2
point = [2.831929729647417e+03, 1984, 512];   % point on pcl plane
mean_syn_dist_data = zeros(nin_temp,2);
for i = 1:nin_temp    
    if ~ismember(i, idx_removed)
        syn_info = get_syn_info(target_interneurons_new(i), 'pc');    
        d_syn = [];
        if ~isempty(syn_info)
            [nsyn,~] = size(syn_info);
            syn_coords = [syn_info(:,8)/4, syn_info(:,9)/4, syn_info(:,10)];
            d_syn = dot(syn_coords - repmat(point, nsyn, 1), repmat(pcl_plane_normal, nsyn, 1), 2);
            d_syn = d_syn * 0.05;  % 1 voxel = 0.05 um in isomip2
        end
        mean_syn_dist_data(i,1) = target_interneurons_new(i);
        mean_syn_dist_data(i,2) = mean(d_syn);
    end
end
mean_syn_dist_data(idx_removed,:) = [];

f3d3 = figure('Position',[300 800 600 500]);
scatter(pcl_dist, mean_syn_dist_data(:,2), markersize, markercolor,'filled'); hold on;
h2 = lsline; h2.Color = damson_blk; h2.LineWidth = 1.2; h2.LineStyle = '--';
corr_coef = corrcoef(pcl_dist, mean_syn_dist_data(:,2));
scatter(pcl_dist(in1_idx),  mean_syn_dist_data(in1_idx,2), markersize, coral, 'filled');
dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
legend(dummyh, {['r = ', num2str(corr_coef(1,2))]}, 'FontSize', fontsize);  legend boxoff;
xlabel('{\it d}_I_N (\mum)'); ylabel('IN-PC syn dist from PCL'); %ylim([min( mean_syn_dist_data(:,2))*0.9, max( mean_syn_dist_data(:,2))*1.05]);
set(gcf,'color','w'); set(gca,'FontSize',fontsize); %axis square;


%Mann-Whitney U Test:
[p1,h01,stats1] = ranksum(dend_density(in1_idx), dend_density(~in1_idx));
[p2,h02,stats2] = ranksum(axon_complexity(in1_idx), axon_complexity(~in1_idx));
[p3,h03,stats3] = ranksum(pcl_dist(in1_idx), pcl_dist(~in1_idx));


%%  IN1-> PC synapse distribution from PCL (VIOLIN PLOT)

%{
load('/data/research/cjpark147/conn_analysis/in_soma_centroid.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
pc_ids = [18,11,4,13,21,20,49,50,3,175];
pcl_plane_normal = [-0.848147309991681,-0.525879404662518,0.064007751918581];   %isotropic mip2
point = [2.831929729647417e+03,1984,512];   % point on pcl plane
d_soma = zeros(nin1+nin2,2);
inpc_syn_dist_from_pcl = cell(nin1+nin2, 2);
inpc_syn_pcl_dist_matrix = cell(numel(pc_ids), nin1+nin2);  

for i = 1:numel(pc_ids)
    for j = 1:numel(in_ids)
        syn_info =get_syn_info(in_dist_from_pcl(j,1), pc_ids(i));
        if ~isempty(syn_info)
            [nsyn,~] = size(syn_info);
            syn_coords= [syn_info(:,8)/4, syn_info(:,9)/4, syn_info(:,10)];
            d_syn = dot(syn_coords - repmat(point, nsyn, 1), repmat(pcl_plane_normal, nsyn, 1), 2) * 0.05;
        else
            d_syn = [];
        end
        inpc_syn_pcl_dist_matrix{i,j}=d_syn;
    end
end
        
violin_data = []; mean_data = [];
for i = 1:(nin1+nin2)    
    syn_info = get_syn_info(in_ids(i), 'pc');
    d_soma(i,1) = in_ids(i);
    d_soma(i,2) = dot(in_soma_centroid(i,2:4) - point, pcl_plane_normal) * 0.05;
    
    if in_ids(i) == 27
        d_soma(i,2) = d_soma(i,2) -0.6;   % to avoid position overlap in violin plot
    end
    d_syn = [];
    if ~isempty(syn_info)
        [nsyn,~] = size(syn_info);
        syn_coords = [syn_info(:,8)/4, syn_info(:,9)/4, syn_info(:,10)];
        d_syn = dot(syn_coords - repmat(point, nsyn, 1), repmat(pcl_plane_normal, nsyn, 1), 2);
        d_syn = d_syn * 0.05;  % 1 voxel = 0.05 um in isomip2
    end
    inpc_syn_dist_from_pcl{i,1} = in_ids(i);
    inpc_syn_dist_from_pcl{i,2} = d_syn; 
    mean_data = [mean_data; mean(d_syn)];
    
    violin_data = [violin_data;  d_syn *0 + d_soma(i,2), d_syn];
end

% Mean syn dist vs soma dist. scatter plot
f4i = figure('Position',[300 800 600 500]);
idx_in2_temp = ismember(in_ids, in2_ids);
scatter(d_soma(~idx_in2_temp,2), mean_data(~idx_in2_temp),'filled', 'r'); hold on;
scatter(d_soma(idx_in2_temp,2), mean_data(idx_in2_temp), 'filled' ,'b');



% syn dist vs soma dist. violin plot.
f4e=figure('Position',[100 500 2000 500]);
idx_in2 =find(ismember(in_dist_from_pcl(:,1), in2_ids));
v = violinplot(violin_data(:,2), violin_data(:,1),'ViolinColor', coral);
for i = 1:numel(in2_ids)
    v(idx_in2(i)).ViolinColor =[55,120,210]/255;
end
%d_soma_um = unique(round(data(:,1)));
xticks([0:25:150]); xticklabels([0:25:150]); yticks([-30,0,50,100,150]); yticklabels([-30,0,50,100,150]);  ylim([-35 160]);
xlabel('IN-soma distance from PCL (\mum)'); ylabel('IN-PC syn dist from PCL');
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
%}