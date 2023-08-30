
addpath /data/research/cjpark147/code/ref
load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
nin1=numel(in1_ids); nin2 = numel(in2_ids);
in_ids = [in1_ids;in2_ids]; nin = nin1+nin2;

gray_blue = [165,199,196]/255;  navy = [25,45,96]/255;orange = [248,148,88]/255;red = [190,12,44]/255;orange2 = [235,155,44]/255;gray = [155,152,145]/255;
orange3 = [239,179,74]/255; red2 = [245,101,80]/255;blue2 = [17,80,129]/255;brown = [97,55,49]/255;black = [34,31,38]/255;
damson_blk = [61,45,62]/255;coral = [255,80,75]/255;orange4 = [235,145,5]/255;peacock = [20,140,195]/255;petrol = [60,120,200]/255;pistachio = [185,215,160]/255;pink = [227,189,187]/255; 

% Radial distance of IN's outgoing synapses from PCL

in_basket = [9,10,15,17,23,26,74];
in_stellate = [19, 22, 27, 31,35,37,41];
% IN->PC synapse number vs. distance of IN soma from PCL layer
pc_with_source = [81, 18, 49, 21, 4, 50, 11,20, 13];
pc_source_center = [9400,9700,40;  12500,8500,525;  4900,9980,710;  14000,500,2800;  12240,8490,1820; ...
                    4300,10500,1500;  13790,5530,2425;  9000,10500,2435;  11800,9400,3310];

%{
in_soma_centroid = zeros(numel(list_of_target_interneurons),3);
for i = 1:numel(list_of_target_interneurons)
    [x,y,z] = ind2sub(size(in_separated), find(in_separated==list_of_target_interneurons_cb_id_in_pruned_volume(i)));
    in_soma_centroid(i,1) = mean(x);
    in_soma_centroid(i,2) = mean(y);
    in_soma_centroid(i,3) = mean(z);
end
%}

syn_data_path = '/data/research/cjpark147/lrrtm3_wt_syn/synapse_det_info_210503.txt';
syn_data = readtable(syn_data_path);
intf_id = syn_data.intf_id;
pre_post_amb = syn_data.pre_post_ambiguity;
seg_pre = syn_data.seg_pre;
seg_post = syn_data.seg_post;
type_pre = syn_data.type_pre;
type_post = syn_data.type_post;
intf_size = syn_data.size;
cx = syn_data.contact_x;
cy = syn_data.contact_y;
cz = syn_data.contact_z;

load('/data/research/cjpark147/conn_analysis/in_soma_centroid.mat');
load('/data/research/cjpark147/conn_analysis/in_pcl_dist_sort.mat');
load('/data/research/cjpark147/conn_analysis/int_complexity_w_skeletons.mat');
load('/data/research/cjpark147/conn_analysis/in_soma_dist_all.mat');
load('/data/research/cjpark147/conn_analysis/d_voxel_from_pcl.mat');

in = list_of_target_interneurons;
%in = [in_stellate, in_basket];
target_pc_ids = pc_with_source;
pc_center = pc_source_center;
median_in = median_dend_height_in_avg_dir;
%median_in = median_cellbody_height_in_avg_dir;
median_pc = median_of_purkinje_cells_in_the_mean_direction;

pcl_plane_normal = [-0.848147309991681,-0.525879404662518,0.064007751918581];   %isotropic mip2
point = [2.831929729647417e+03,1984,512];   % point on pcl plane


%% IN-PC synapse distance from PCL 


load('/data/research/cjpark147/conn_analysis/in_soma_centroid.mat');
pc_ids = [18;11;4;13;21;20;49];
pcl_plane_normal = [-0.848147309991681,-0.525879404662518,0.064007751918581];   %isotropic mip2
point = [2.831929729647417e+03,1984,512];   % point on pcl plane
d_soma = zeros(nin1+nin2,2);
inpc_syn_dist_from_pcl = cell(nin1+nin2, 2);
inpc_syn_total = 0;
% get syn dist
for i = 1:(nin1+nin2)    
    syn_info = get_syn_info(in_ids(i), 'pc');
    d_soma(i,1) = in_ids(i);
    d_soma(i,2) = dot(in_soma_centroid(i,2:4) - point, pcl_plane_normal) * 0.05;
    d_syn = [];
    if ~isempty(syn_info)
        [nsyn,~] = size(syn_info);
        syn_coords = [syn_info(:,8)/4, syn_info(:,9)/4, syn_info(:,10)];
        d_syn = dot(syn_coords - repmat(point, nsyn, 1), repmat(pcl_plane_normal, nsyn, 1), 2);
        d_syn = d_syn * 0.05;  % 1 voxel = 0.05 um in isomip2
        inpc_syn_total = inpc_syn_total + nsyn;
    end
    inpc_syn_dist_from_pcl{i,1} = in_ids(i);
    inpc_syn_dist_from_pcl{i,2} = d_syn;
end


%% Use this 
load('/data/research/cjpark147/conn_analysis/inpc_syn_pcl_dist_matrix.mat'); % pc x in matrix. in pcl-sorted 
    violin_data = []; idx_in2 = []; count = 0;
    for j = 1:nin
        d_syn = inpc_syn_pcl_dist_matrix{i,j};
        if ~isempty(d_syn)
            count = count+1;
            violin_data = [violin_data; repmat(j, numel(d_syn), 1), d_syn];
        end
        if ~isempty(d_syn) && ismember(in_dist_from_pcl(j,1), in2_ids)
            idx_in2 = [idx_in2; count];
        end
    end
    f4 = figure('Position',[100 100 900 600]);
    v = violinplot(violin_data(:,2), round(violin_data(:,1)),'ViolinColor', coral);
    
   % if ~isempty(idx_in2)
    for j = 1:numel(idx_in2)
        v(idx_in2(j)).ViolinColor = petrol;
    end    
    xticklabels(in_dist_from_pcl(:,1));
    xlabel('Interneurons (ranked) ');  ylabel('IN-PC syn distance from PCL (\mum)');
    set(gcf, 'color', 'w'); set(gca,'FontSize',20, 'FontName', 'Helvetica');       
    %boxpos = [1,2,3,7,8,10,11,12,15,16,17,19,22,26,35,36,37,38,41,42,49,50];
    %boxplot(data(:,2),round(data(:,1)), 'PlotStyle','compact', 'Widths', 0.5);
    %boxplot(data(:,2),round(data(:,1)),'positions', boxpos);
    h = findobj(gca, 'Tag', 'Box');
    peacock = [0,130,190]/256; coral = [238,50,50]/256;
    for j = 1:length(h)        
        patch(get(h(j),'XData'), get(h(j), 'YData'), peacock, 'FaceAlpha',.5);
    end
    %d_soma_um = unique(round(data(:,1))) * 0.05;
    xticks(1:26); xlim([0 26]);
    %xline(1:26, '--' ,'LineWidth',0.4); 
    save_figure(f4, ['/sfig/pc/inpcsyn', num2str(target_ids(i))], 'pdf');
    %}


%% IN-PC synapse dist from PCL individual cells AND Segregation index AND KS-TEST

%{
load('/data/research/cjpark147/conn_analysis/in_soma_centroid.mat');
pc_ids = [18;11;4;13;21;20;49];
pcl_plane_normal = [-0.848147309991681,-0.525879404662518,0.064007751918581];   %isotropic mip2
point = [2.831929729647417e+03,1984,512];   % point on pcl plane
d_soma = zeros(nin1+nin2,2);
inpc_syn_dist_from_pcl = cell(nin1+nin2, 2);
inpc_syn_total = 0;
% get syn dist
for i = 1:(nin1+nin2)    
    syn_info = get_syn_info(in_ids(i), 'pc');
    d_soma(i,1) = in_ids(i);
    d_soma(i,2) = dot(in_soma_centroid(i,2:4) - point, pcl_plane_normal) * 0.05;
    d_syn = [];
    if ~isempty(syn_info)
        [nsyn,~] = size(syn_info);
        syn_coords = [syn_info(:,8)/4, syn_info(:,9)/4, syn_info(:,10)];
        d_syn = dot(syn_coords - repmat(point, nsyn, 1), repmat(pcl_plane_normal, nsyn, 1), 2);
        d_syn = d_syn * 0.05;  % 1 voxel = 0.05 um in isomip2
        inpc_syn_total = inpc_syn_total + nsyn;
    end
    inpc_syn_dist_from_pcl{i,1} = in_ids(i);
    inpc_syn_dist_from_pcl{i,2} = d_syn;
end

% get skel dist

load('/data/research/cjpark147/conn_analysis/in_axon_rot.mat');
load('/data/research/cjpark147/conn_analysis/inpc_syn_rot.mat');
load('/data/research/cjpark147/conn_analysis/in_skeleton/int_graph_dend_and_axon_20210324.mat'); 
load('/data/research/cjpark147/conn_analysis/int_branch_info_dendNaxon_20210324.mat');
load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
load('/data/research/cjpark147/conn_analysis/interneuron_height_in_avg_dir.mat');
load('/data/research/cjpark147/conn_analysis/median_of_purkinje_cells_in_the_mean_direction.mat');

cell_removed = 19;  nin_temp = numel(target_interneurons_new);
idx_removed = find(target_interneurons_new==cell_removed);
in_skel_dist_from_pcl = cell(nin1+nin2, 2);
for i = 1:(nin1+nin2)
    d_skel = [];
    idx = target_interneurons_new == in_ids(i);
    if ~ismember(target_interneurons_new(idx), cell_removed)
        skel_coords = int_graph_axon_isomip3{idx,1}.Node.Coord * 2;
        [np,~]= size(skel_coords);
        d_skel = dot(skel_coords - repmat(point, np, 1), repmat(pcl_plane_normal, np, 1), 2);
        d_skel = d_skel * 0.05;
        in_skel_dist_from_pcl{i,1} = in_ids(i);    
        in_skel_dist_from_pcl{i,2} = d_skel;
    end
end    

% axon syn density
axon_syn_density = cell(nin1+nin2,2);
edges = -40:10:160;
syn_count_raw = zeros(1,numel(edges)-1);
for i = 1:(nin1+nin2)
    d_syn = inpc_syn_dist_from_pcl{i,2};
    d_skel = in_skel_dist_from_pcl{i,2};
    [c1,e1] = histcounts(d_syn, edges);
    [c2,e2] = histcounts(d_skel, edges);
    syn_count_raw = syn_count_raw + c1;
    axon_syn_density{i,1} = in_skel_dist_from_pcl{i,1};
    axon_syn_density{i,2} = c1./c2;
end

% plot inpc syn dist from pcl, sorted by distance from pcl
in = target_interneurons_new;
[nin_this,~] = size(in_dist_from_pcl(:,1));
excluded = [19];  
panel_count = 1;
ff1=figure('Position',[100 500 1600 1000]);
bin=edges;bin_center = bin(2:end) - (bin(2) - bin(1))/2;
for i = 1:nin_this
    if ~ismember(in_dist_from_pcl(i,1),excluded)
        idx = find(in_ids==in_dist_from_pcl(i,1));
        subplot(5,6,panel_count);
        panel_count = panel_count + 1;
        [n,e] = histcounts(inpc_syn_dist_from_pcl{idx,2}, bin);
        plot(bin_center, n,'LineWidth',2,'Color',coral);
        if ismember(in_dist_from_pcl(i,1), in2_ids)
            plot(bin_center, n,'LineWidth',2,'Color',petrol);
        end
        ylim([0,40]); set(gca,'FontSize',12);
    end
end
h = axes(ff1, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
set(gca,'FontSize',22); set(gcf,'color','w'); 
xlabel('Dist from PCL [\mum]'); ylabel('Number of IN-PC synapses'); set(gca,'FontSize',24); set(gcf,'color','w');

% plot inpc syn density from pcl, sorted by distance from pcl
ff2=figure('Position',[100 500 1600 1000]); 
panel_count = 1;
max_x = zeros(nin_this,1); max_y = max_x;
for i = 1:nin_this
    if ~ismember(in_dist_from_pcl(i,1),excluded)
        idx = find(in_ids==in_dist_from_pcl(i,1));
        subplot(5,6,panel_count);
        panel_count = panel_count + 1;
        plot(bin_center, axon_syn_density{idx,2},'LineWidth',2,'Color',coral);
        if ismember(in_dist_from_pcl(i,1), in2_ids)
            plot(bin_center, axon_syn_density{idx,2},'LineWidth',2,'Color',petrol);
        end
        
        [~,max_y(i)] = max(axon_syn_density{idx,2});
        max_x(i) = in_dist_from_pcl(i,2);
        xlim([-40,160]); ylim([0,0.1]); set(gca,'FontSize',12);
    end
end
h = axes(ff2, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
xlabel('Dist from PCL [\mum]'); ylabel('Density of IN-PC synapses');
set(gca,'FontSize',22); set(gcf,'color','w'); 

ff2s = figure('Position',[100 500 850 600]);
for i = 1:nin_this
    scatter(max_x(i), bin_center(max_y(i)), 80,coral,'filled'); hold on;
    if ismember(in_dist_from_pcl(i,1), in2_ids)
        scatter(max_x(i), bin_center(max_y(i)), 80,petrol,'filled');
    end
end
xlabel('Dist from PCL'); ylabel('Peak output density location');
set(gcf,'color','w'); set(gca,'FontSize',24); ylim([-40 160]);
%}

%{
% set boundary to form two groups
th = 10:10:140; % set boundary 
wbin = 20;
si2 = zeros(numel(th),1); si2_num = si2;
ks2 = zeros(numel(th),1); ks2_num = ks2;
data_illust = struct();
for i = 1:numel(th)
    group1 = d_soma_all(d_soma_all(:,2) < th(i),1);   % divide INs into two groups
    group2 = setdiff(d_soma_all(:,1), group1);
    group1(~ismember(group1,in_ids)) = [];   group2(~ismember(group2,in_ids)) = [];
    idx1 = find(in_ids==group1(1)); idx2= find(in_ids==group2(1));           
    den_syn1 = axon_syn_density{idx1,2};  den_syn1(isnan(den_syn1)) = 0;
    den_syn2 = axon_syn_density{idx2,2};  den_syn2(isnan(den_syn2)) = 0;
    [count_syn1,~] = histcounts(inpc_syn_dist_from_pcl{idx1,2}, bin);
    [count_syn2,~] = histcounts(inpc_syn_dist_from_pcl{idx2,2}, bin);
    
    for j = 2:numel(group1)
        idx1 = find(in_ids == group1(j));
        aa = axon_syn_density{idx1,2};  aa(isnan(aa)) = 0;
        den_syn1 = den_syn1 + aa;    % linearly sum density of neurons in group1        
        [bb,~] =  histcounts(inpc_syn_dist_from_pcl{idx1,2}, bin);
        count_syn1 = count_syn1+bb;
    end
    
    for j = 2:numel(group2)
        idx2 = find(in_ids == group2(j));
        aa = axon_syn_density{idx2,2};  aa(isnan(aa)) = 0;
        den_syn2 = den_syn2 + aa;    % linearly sum density of neurons in group2        
        [bb,~] =  histcounts(inpc_syn_dist_from_pcl{idx2,2}, bin);
        count_syn2 = count_syn2+bb;
    end    
    
    si2_num(i) =abs(mean(count_syn1) - mean(count_syn2))/sqrt((var(count_syn1) + var(count_syn2))/2);
    [~,ks2_num(i),~] = kstest2(count_syn1, count_syn2);

    den_syn1 = den_syn1 / sum(den_syn1);  % normalize to make its sum 1
    den_syn2 = den_syn2 / sum(den_syn2);    
    den_syn1(isnan(den_syn1)) = 0; 
    den_syn2(isnan(den_syn2)) = 0;
    bin_center = edges(2:end) - (edges(2)-edges(1))/2;
    
    den_syn1= round(den_syn1,3);
    den_syn2= round(den_syn2,3);
    
    % copmuting variance of probability distribution
    ex1=sum(den_syn1 .* bin_center);     
    ex2=sum(den_syn2 .* bin_center);
    exsq1 = sum(den_syn1 .* bin_center.^2);  
    exsq2 = sum(den_syn2 .* bin_center.^2);
    var1 = exsq1 - ex1^2; 
    var2 = exsq2 - ex2^2;
    si2(i) = abs(ex1 - ex2) / sqrt((var1+var2)/2);    
    [~,ks2(i),~] = kstest2(den_syn1, den_syn2);
    
    % computing variance via estimation of number of synapses 
    %{
    num_syn1 = numel(vertcat(inpc_syn_dist_from_pcl{ismember(in_ids, group1),2}));  % total number of syn in group1
    num_syn2 = numel(vertcat(inpc_syn_dist_from_pcl{ismember(in_ids, group2),2}));
    count_estimate_syn1 = round(den_syn1 * num_syn1);  
    count_estimate_syn2 = round(den_syn2 * num_syn2);   
    d_syn_norm1 = repelem(bin_center, count_estimate_syn1);
    d_syn_norm2 = repelem(bin_center, count_estimate_syn2);
    mu1 = mean(d_syn_norm1);  mu2 = mean(d_syn_norm2);
    var1 = var(d_syn_norm1); var2 = var(d_syn_norm2);
    si2(i) = abs(mu1 - mu2)/sqrt((var1+var2)/2);
    %}
    
    data_illust(i).d_group1 = d_soma_all(ismember(d_soma_all(:,1),group1),2);
    data_illust(i).d_group2 = d_soma_all(ismember(d_soma_all(:,1),group2),2);
    data_illust(i).estimate_syn1 = count_estimate_syn1;
    data_illust(i).estimate_syn2 = count_estimate_syn2;
    data_illust(i).den1 = den_syn1;
    data_illust(i).den2 = den_syn2;
    data_illust(i).syn1 = count_syn1;
    data_illust(i).syn2 = count_syn2;
end


% If syn are homogeneously distributed with equal interval
d_homo = -20:10:150;
homo_syn_density = cell(nin1+nin2,1);
for i = 1:(nin1+nin2)
    idx = ismember(in_ids,in_ids(i));
    this_syn = inpc_syn_dist_from_pcl{idx,2};
    d_min = min(this_syn); d_max = max(this_syn);
    %idx_e1 = ceil((d_min+abs(min(edges)))/10);   % bin index for syn closest to pcl  
    %idx_e2 = ceil((d_max+abs(min(edges)))/10);   % bin index for syn farthest from pcl
    
     idx_e1 = 1; idx_e2 = numel(edges) -1;    % assuming all axons span whole distance from pcl
    
    aa = zeros(20,1); 
    aa(idx_e1:idx_e2) = numel(this_syn)/(idx_e2-idx_e1+1);   % density of homogeneously distributed synapses 
    homo_syn_density{i,1} = aa;
end
si_homo = zeros(numel(th),1); si_num_homo = si_homo;
ks2_homo = zeros(numel(th),1);
for i = 1:numel(th)
    group1 = d_soma_all(d_soma_all(:,2) < th(i),1);   % divide INs into two groups
    group2 = setdiff(d_soma_all(:,1), group1);
    group1(~ismember(group1,in_ids)) = [];   group2(~ismember(group2,in_ids)) = [];
    idx1 = find(in_ids==group1(1)); idx2= find(in_ids==group2(1));
    den_syn1 = homo_syn_density{idx1,1};  
    den_syn2 = homo_syn_density{idx2,1}; 
    for j = 2:numel(group1)
        idx1 = find(in_ids == group1(j));
        aa = homo_syn_density{idx1,1}; 
        den_syn1 = den_syn1 + aa;    % linearly sum density of neurons in group1
    end
    for j = 2:numel(group2)
        idx2 = find(in_ids == group2(j));
        aa = homo_syn_density{idx2,1}; 
        den_syn2 = den_syn2 + aa;    % linearly sum density of neurons in group2
    end
    den_syn1 = den_syn1 / sum(den_syn1);  % normalize to make its sum 1
    den_syn2 = den_syn2 / sum(den_syn2); 
    den_syn1(isnan(den_syn1)) = 0; 
    den_syn2(isnan(den_syn2)) = 0;
    den_syn1 = round(den_syn1,3);
    den_syn2 = round(den_syn2,3);
    
    % copmuting variance of probability distribution
    ex1=sum(den_syn1' .* bin_center);     
    ex2=sum(den_syn2' .* bin_center);
    exsq1 = sum(den_syn1' .* bin_center.^2);  
    exsq2 = sum(den_syn2' .* bin_center.^2);
    var1 = exsq1 - ex1^2; 
    var2 = exsq2 - ex2^2;
    si_homo(i) = abs(ex1 - ex2) / sqrt((var1+var2)/2);    % segregation index 
    
    % computing variance via estimation of number of synapses
    %{
    num_syn1 = numel(vertcat(inpc_syn_dist_from_pcl{ismember(in_ids,group1),2}));  % total number of syn in group1
    num_syn2 = numel(vertcat(inpc_syn_dist_from_pcl{ismember(in_ids,group2),2}));
    count_syn1 = round(den_syn1 * num_syn1);  
    count_syn2 = round(den_syn2 * num_syn2);   
    bin_center = edges(2:end) - (edges(2)-edges(1))/2;
    d_syn_norm1 = repelem(bin_center, count_syn1);
    d_syn_norm2 = repelem(bin_center, count_syn2);
    mu1 = mean(d_syn_norm1);  mu2 = mean(d_syn_norm2);
    var1 = var(d_syn_norm1); var2 = var(d_syn_norm2);    
    si_homo(i) = abs(mu1 - mu2)/sqrt((var1+var2)/2);    
    %}
    
    [~,ks2_homo(i),~] = kstest2(den_syn1, den_syn2);
end


% syn number for each boundary
panel_count = 1;
ff3=figure('Position',[100 500 1600 1000]);
bin=edges;bin_center = bin(2:end) - (bin(2) - bin(1))/2;
for i = 1:numel(th)
    if ~ismember(in_dist_from_pcl(i,1),excluded)
        idx = find(in_ids==in_dist_from_pcl(i,1));
        subplot(4,4,panel_count);
        panel_count = panel_count + 1; hold on;
        text(data_illust(i).d_group1, zeros(numel(data_illust(i).d_group1),1) + 205, '|', 'VerticalAlignment','middle', 'HorizontalAlignment','center','Color',  orange4, 'FontSize',17);
        text(data_illust(i).d_group2, zeros(numel(data_illust(i).d_group2),1) + 205, '|', 'VerticalAlignment','middle', 'HorizontalAlignment','center','Color',  damson_blk*2, 'FontSize',17);
        p1=plot(bin_center,data_illust(i).syn1, 'LineWidth',2, 'Color',orange); 
        p2=plot(bin_center,data_illust(i).syn2, 'LineWidth',2, 'Color',damson_blk*2.5);         
        set(gca,'FontSize',16);  xline(th(i), '--','LineWidth',2);
        xlim([-40,160]);  ylim([0,220]);
    end
end
h = axes(ff3, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
xlabel('Distance from PCL [\mum]'); ylabel('Number of IN-PC synapses '); set(gca,'FontSize',24); set(gcf,'color','w');

% syn density for each boundary 
panel_count = 1;
ff4=figure('Position',[100 500 1600 1000]);
bin=edges;bin_center = bin(2:end) - (bin(2) - bin(1))/2;
for i = 1:numel(th)
    if ~ismember(in_dist_from_pcl(i,1),excluded)
        idx = find(in_ids==in_dist_from_pcl(i,1));
        subplot(4,4,panel_count);
        panel_count = panel_count + 1;
        text(data_illust(i).d_group1, zeros(numel(data_illust(i).d_group1),1) + max([data_illust(i).den1, data_illust(i).den2])*1.1, '|', 'VerticalAlignment','middle', 'HorizontalAlignment','center','Color',  orange4, 'FontSize',27);
        text(data_illust(i).d_group2, zeros(numel(data_illust(i).d_group2),1) + max([data_illust(i).den1, data_illust(i).den2])*1.1, '|', 'VerticalAlignment','middle', 'HorizontalAlignment','center','Color',  damson_blk*2, 'FontSize',27);
        p1=plot(bin_center,data_illust(i).den1, 'LineWidth',2, 'Color',orange); hold on;
        p2=plot(bin_center,data_illust(i).den2, 'LineWidth',2, 'Color',damson_blk*2.5);         
        set(gca,'FontSize',16);  xline(th(i), '--','LineWidth',2);
        xlim([-40,160]); ylim([0,0.28]);   
    end
end
h = axes(ff4, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
xlabel('Dist from PCL [\mum]'); ylabel('IN-PC synapse denstiy (Norm.)'); set(gca,'FontSize',24); set(gcf,'color','w');
        

% si for syn count
ff5=figure; p3=plot(th,si2_num,'-o','LineWidth',1.5); 
xlabel('Boundary dist from PCL'); ylabel('Segregation index'); set(gca,'FontSize',19); set(gcf, 'color','w'); hold on;ylim([-1,7]);
%p4=plot(th,si_num_homo,'-o','LineWidth',1.5, 'Color',color3); 
%legend([p3,p4],{'inpc synapse number', 'homogeneous'}); 

% ks test for syn count
ff6=figure; p3=plot(th,ks2_num,'-o','LineWidth',1.5); 
xlabel('Boundary dist from PCL'); ylabel('KS-test p-value'); set(gca,'FontSize',19); set(gcf, 'color','w'); hold on; ylim([0,1.1]);
%p4=plot(th,ks2_homo,'-o','LineWidth',1.5, 'Color',red); 
%legend([p3,p4],{'inpc synapse density', 'homogeneous'},'Location','northoutside'); ylim([0,1.1]);

% si for syn density
ff7=figure; p3=plot(th,si2,'-o','LineWidth',1.5); 
xlabel('Boundary dist from PCL'); ylabel('Segregation index'); set(gca,'FontSize',19); set(gcf, 'color','w'); hold on;
p4=plot(th,si_homo,'-o','LineWidth',1.5, 'Color',color3); 
legend([p3,p4],{'inpc synapse density', 'homogeneous'}); ylim([-1,7]);

% ks-test for syn density
ff8=figure; p3=plot(th,ks2,'-o','LineWidth',1.5); 
xlabel('Boundary dist from PCL'); ylabel('KS-test p-value'); set(gca,'FontSize',19); set(gcf, 'color','w'); hold on;
p4=plot(th,ks2_homo,'-o','LineWidth',1.5, 'Color',red); 
legend([p3,p4],{'inpc synapse density', 'homogeneous'},'Location','northoutside'); ylim([0,1.1]);

ff7=figure('Position',[100 500, 800, 700]);
y_data = zeros(nin1,1); y_data2 = zeros(nin2,1);
for i = 1:nin1
    y_data(i) = mean(inpc_syn_dist_from_pcl{i,2});
end
for i = 1:nin2
    y_data2(i) = mean(inpc_syn_dist_from_pcl{i+nin1,2});
end
scatter(d_soma(:,2), [y_data;y_data2], 120, coral, 'filled'); hold on;
h2 = lsline; h2.Color = damson_blk; h2.LineWidth = 1.2; h2.LineStyle = '--';
corr_coef = corrcoef(d_soma(:,2), [y_data;y_data2]);
dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
scatter(d_soma(nin1+1:nin1+nin2,2), y_data2, 120, petrol, 'filled'); 
legend(dummyh, {['r = ', num2str(corr_coef(1,2))]}, 'FontSize', 24, 'Location','north');  legend boxoff; axis square;
xlabel('Soma distance from PCL [\mum]'); ylabel('Mean output dist from PCL [\mum]'); set(gcf,'color','w'); set(gca,'FontSize',24); 
%}

%% Plot synapse number vs distance from purkinje layer

%{
dist = cell(numel(in),1);

for i = 1:numel(in)
    idx_syn = (seg_pre == in(i) & strcmp(type_post,'pc'));
    if ~isempty(idx_syn)
        syn_coords = [cx(idx_syn)/4, cy(idx_syn)/4, cz(idx_syn)];
        [nrow,~] = size(syn_coords);
        dist{i,1} = dot(syn_coords - repmat(point, nrow,1), repmat(pcl_plane_normal, nrow, 1),2);
    end
end

for i = 1:numel(in)
    nexttile
    histogram(dist{i,1}, 10);
    if i <= numel(in_stellate)
        title(['Stellate ', num2str(in(i))], 'FontSize', 12);
    else
        title(['Basket ' , num2str(in(i))], 'FontSize',12);
    end
    xlabel('Distance from PCL');
    ylabel('Syn counts');
    xlim([0, 3000]);
end
%}

%% Distance of IN->PC outputs from PCL vs. distance of IN soma from PCL  (previous version)


load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
in = [in1_ids;in2_ids];
in = setdiff(in, [12;39;40;54]);

d_from_pcl = zeros(numel(in),1);
%data = cell(numel(in),1);
data = []; in_rank = zeros(numel(in),2);
for i = 1:numel(in)
    idx_syn = (seg_pre == in(i) & strcmp(type_post, 'pc'));
    idxx = find(in_soma_centroid(:,1) == in(i));
    d_soma = dot(in_soma_centroid(idxx,2:4) - point, pcl_plane_normal)*0.05;
    if in(i) == 27
        d_soma = d_soma-0.6;   % to avoid position overlap in bargraph.
    end
    d_from_pcl(i) = d_soma;
    if sum(idx_syn)~=0

     %   d_from_pcl(i) = d_soma;
        syn_coords = [cx(idx_syn)/4, cy(idx_syn)/4, cz(idx_syn)];
        [nrow,~] = size(syn_coords);        
        d_syn = dot(syn_coords - repmat(point, nrow,1), repmat(pcl_plane_normal, nrow, 1),2);
        d_syn = d_syn * 0.05; % 1 voxel = 50 nm in mip2                
%        data{i,1} = [d_syn *0 + d_soma, d_syn];
        data = [data; d_syn *0 + d_soma, d_syn];        
        in_rank(i,1) = in(i);
        in_rank(i,2) = d_soma;
    end
end
in_rank(in_rank(:,2)==0,:)=[];
in_rank = sortrows(in_rank,2);
figure;
boxpos = [1,2,3,7,8,10,11,12,15,16,17,19,22,26,35,36,37,38,41,42,49,50];
%boxplot(data(:,2),round(data(:,1)), 'PlotStyle','compact', 'Widths', 0.5);
%boxplot(data(:,2),round(data(:,1)));
boxplot(data(:,2),round(data(:,1)),'positions', boxpos);
h = findobj(gca, 'Tag', 'Box');
peacock = [0,130,190]/256; coral = [238,50,50]/256;
for j = 1:length(h)
    patch(get(h(j),'XData'), get(h(j), 'YData'), peacock, 'FaceAlpha',.5);
end
title('IN->PC input distance from PCL vs. IN-soma distance from PCL','FontSize',15);
d_soma_um = unique(round(data(:,1))) * 0.05;
xticklabels(round(d_soma_um));
xlabel('IN-soma distance from PCL (\mum)', 'FontSize', 15);
ylabel('IN->PC input distance from PCL (\mum)', 'FontSize', 15);
set(gcf, 'color', 'w');

% violin plot
figure;
[nbox,~] = size(in_rank);
idx =find(ismember(in_rank(:,1), in2_ids));
peacock = [1,140,190]/256; coral = [238,50,50]/256;
v = violinplot(data(:,2), round(data(:,1)),'ViolinColor', peacock);
for i = 1:numel(in2_ids)
    v(idx(i)).ViolinColor = coral;
end    
title('IN->PC input distance from PCL vs. IN-soma distance from PCL','FontSize',15);
d_soma_um = unique(round(data(:,1))) * 0.05;
xticklabels(round(d_soma_um));
xlabel('IN-soma distance from PCL (\mum) NOT-TO-SCALE ', 'FontSize', 15);
ylabel('IN->PC input distance from PCL (\mum)', 'FontSize', 15);
set(gcf, 'color', 'w');
%}

%% save as pdf
%{
set(gcf, 'Units','Inches');
pos = get(gcf,'Position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
print(gcf,'/data/research/cjpark147/figure/inpc_syn_dist_from_pcl_violin','-dpdf','-r0');
%}




%%  Soma / Dend preference index

%{
load('/data/research/cjpark147/conn_analysis/inpc_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/inin_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
in_axon_rot = in_axon_rot_pcl;
in_dend_rot = in_dend_rot_pcl;
inin_syn_rot = inin_syn_rot_pcl;
inpc_syn_rot = inpc_syn_rot_pcl;
cfin_syn_rot = cfin_syn_rot_pcl;
in_soma_centroid_rot = in_soma_centroid_rot_pcl;
bins = 0:20:140;
spi = zeros(nin,1);
spi_size = spi;
excluded = [19];
mean_soma_syn_size= 57224;
for i = 1:nin
    if ~ismember(inpc_syn_rot{i,1}, excluded) 
        [ndend,~] = size(inpc_syn_rot{i,2}.dend);
        [nsoma,~] = size(inpc_syn_rot{i,2}.soma);
        dend_contact_size = sum(inpc_syn_rot{i,2}.dend_contact_size);
        soma_contact_size = sum(inpc_syn_rot{i,2}.soma_contact_size);
        idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
        soma_syn_predicted = ceil(abs((in_dist_from_pcl(idx,2) - 140)/20));  
        % soma synapse extrapolation/prediction based on distance from PCL.
        nsoma = nsoma + soma_syn_predicted *10;
        soma_contact_size = soma_contact_size + (mean_soma_syn_size*soma_syn_predicted * 10);
        spi(i) =(nsoma-ndend)/(nsoma+ndend);
        spi_size(i) = (soma_contact_size - dend_contact_size) / (soma_contact_size + dend_contact_size);
    end
end

f=figure('Position',[100 500 800 650]);
excluded = [19];
for i = 1:nin
    if ~ismember(inpc_syn_rot{i,1}, excluded) 
        idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
        scatter(in_dist_from_pcl(idx,2), spi_size(i), 80, coral,'filled'); hold on;
        
        if ismember(in_dist_from_pcl(idx,1), in2_ids)
            scatter(in_dist_from_pcl(idx,2), spi_size(i), 80, petrol,'filled'); hold on;
        end        
    end
end
grid minor; 
xlabel('Dist from PCL'); ylabel('Soma Preference Index (size)'); 
set(gca,'FontSize',22,'LineWidth',2); set(gcf,'color','w'); 
%}

%% IN-PC dendrite synapse from PCL
%{
load('/data/research/cjpark147/conn_analysis/inpc_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/inin_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
in_axon_rot = in_axon_rot_pcl;
in_dend_rot = in_dend_rot_pcl;
inin_syn_rot = inin_syn_rot_pcl;
inpc_syn_rot = inpc_syn_rot_pcl;
cfin_syn_rot = cfin_syn_rot_pcl;
in_soma_centroid_rot = in_soma_centroid_rot_pcl;
bins = 0:20:140;
spi = zeros(nin,1);
spi_size = spi;
excluded = [19];
mean_soma_syn_size= 57224;
for i = 1:nin
    if ~ismember(inpc_syn_rot{i,1}, excluded) 
        [ndend,~] = size(inpc_syn_rot{i,2}.dend);
        [nsoma,~] = size(inpc_syn_rot{i,2}.soma);
        dend_contact_size = sum(inpc_syn_rot{i,2}.dend_contact_size);
        idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
        % soma synapse extrapolation/prediction based on distance from PCL.
        spi(i) =(nsoma-ndend)/(nsoma+ndend);
        spi_size(i) = (soma_contact_size - dend_contact_size) / (soma_contact_size + dend_contact_size);
    end
end

f=figure('Position',[100 500 800 650]);
excluded = [19];
for i = 1:nin
    if ~ismember(inpc_syn_rot{i,1}, excluded) 
        idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
        scatter(in_dist_from_pcl(idx,2), spi_size(i), 80, coral,'filled'); hold on;
        
        if ismember(in_dist_from_pcl(idx,1), in2_ids)
            scatter(in_dist_from_pcl(idx,2), spi_size(i), 80, petrol,'filled'); hold on;
        end        
    end
end
grid minor; 
xlabel('Dist from PCL'); ylabel('Soma Preference Index (size)'); 
set(gca,'FontSize',22,'LineWidth',2); set(gcf,'color','w'); 
%}

%% Estimate number of IN-PC somatic synapses (Using axon area in sagittal plane)
%{
% Compute axon area in sagittal plane
load('/data/research/cjpark147/conn_analysis/in_axon_rot.mat');  % axon coords rotated wrt PC mean plane
load('/data/research/cjpark147/conn_analysis/in_dend_rot.mat');  % dend coords rotated wrt PC mean plane
maxy = 0; maxx = 0; miny = 0; minx = 0;
omit_in =[19]; % doesn't have axon
%ngrid = 128*2.^(0:5);
%ngrid=[900,1000,1200];
ngrid = [300,500,600,700,800,900,1200,3600];
axon_expecting_basket = [28;24;71;9;74;15;17;10;26;12;23];
in_axon_sagittal_area_isomip2 = cell(nin,1+numel(ngrid));
max_x = 3652; max_y = 2484;  min_x = 0;   min_y = -66;
for j = 1:numel(ngrid)
    fs=figure('Position',[100 500 2400 2000]);
    tiling = tiledlayout(5,6,'TileSpacing','Compact');
%    tiling = tiledlayout(2,2,'TileSpacing','Compact');
    nx = ceil(max_x/ngrid(j));  
    ny = ceil(max_y/ngrid(j));    
   for i = 1:length(in_dist_from_pcl)
%    for i = 4:5:20
        if ~ismember(in_dist_from_pcl(i,1), omit_in)
            idx = find([in_axon_rot{:,1}]==in_dist_from_pcl(i,1));
            nexttile
            % dendrite
            scatter(in_dend_rot{idx,2}(1:2:end,1), in_dend_rot{idx,2}(1:2:end,2), 2, gray, 'filled','o'); hold on;
            % axon
            scatter(in_axon_rot{idx,2}(1:2:end,1), in_axon_rot{idx,2}(1:2:end,2), 3, coral,'filled','o');
            
            if maxy < max(in_dend_rot{idx,2}(1:2:end,2))
                maxy =  max(in_dend_rot{idx,2}(1:2:end,2));
            end        
            if maxy < max(in_axon_rot{idx,2}(1:2:end,2))
                maxy = max(in_axon_rot{idx,2}(1:2:end,2));
            end        
            if maxx < max(in_dend_rot{idx,2}(1:2:end,1))
                maxx = max(in_dend_rot{idx,2}(1:2:end,1));
            end        
            if maxx < max(in_axon_rot{idx,2}(1:2:end,1))
                maxx = max(in_axon_rot{idx,2}(1:2:end,1));
            end    
            if minx > min(in_dend_rot{idx,2}(1:2:end,1))
                minx =  min(in_dend_rot{idx,2}(1:2:end,1));
            end        
            if minx > min(in_axon_rot{idx,2}(1:2:end,1))
                minx = min(in_axon_rot{idx,2}(1:2:end,1));
            end        
            if miny > min(in_dend_rot{idx,2}(1:2:end,2))
                miny = min(in_dend_rot{idx,2}(1:2:end,2));
            end        
            if miny > min(in_axon_rot{idx,2}(1:2:end,2))
                miny = min(in_axon_rot{idx,2}(1:2:end,2));
            end        
            
            maxx=round(maxx); maxy=round(maxy); minx=round(minx); miny=round(miny);
            total_area = 0;
            for yy = 1:ny
                for xx = 1:nx
                    stp = max([minx,miny], [ngrid(j)*(xx-1)+minx, ngrid(j)*(yy-1)+miny]);  % start point
                    enp = min([maxx, maxy], [ngrid(j)*(xx)+minx, ngrid(j)*(yy)+miny]);                % end point
                 %   yline(enp(2)); xline(enp(1));
                 %   yline(stp(2)); xline(stp(1));

                 %   fprintf('%d %d, %4d %4d, %4d %4d \n', xx, yy, stp(1), stp(2), enp(1), enp(2));
                    valid1 = sum(in_axon_rot{idx,2}(:,1:2) >= stp, 2) == 2;    % valid if axon coord is larger than stp
                    valid2 = sum(in_axon_rot{idx,2}(:,1:2) < enp, 2) == 2;    % valid if axon coord is smaller than enp
                    valid_idx = valid1 & valid2; 
                    axon_in_grid = in_axon_rot{idx,2}(valid_idx,1:2);   % axon part overlapping with this grid
                    %scatter(axon_in_grid(:,1), axon_in_grid(:,2), 3, petrol, 'filled','o');
                    if length(axon_in_grid) > 5 
                        [k,av] = convhull(axon_in_grid);
                        plot(axon_in_grid(k,1), axon_in_grid(k,2), 'LineWidth',1, 'color', petrol);
                        total_area = total_area + av;
                    end                    
                end
            end
            in_axon_sagittal_area_isomip2{i,1} = in_dist_from_pcl(i,1);
            in_axon_sagittal_area_isomip2{i,j+1} = total_area;
            xlim([0,3651]); ylim([-66,2484]);        
            %set(gca,'YDir','reverse', 'FontSize',12);
            daspect([1 1 1]); 
            set(gca,'xdir', 'reverse');
            
            if ismember(in_dist_from_pcl(i,1), axon_expecting_basket)
                set(gca,'XColor', [90,180,110]/255, 'YColor',[90,180,110]/255, 'LineWidth',2)
            else
              %  set(gca,'XColor', gray, 'YColor',[120,200,140]/255, 'LineWidth',2)
            end
        end
   end
    set(gcf,'color','w'); 
    h = axes(fs, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
    title(h, ['Grid spacing ', num2str(ngrid(j))], 'FontSize',20);
    %xlabel(h,'X','FontSize',26);  ylabel(h,'Y','FontSize',26);
    set(gcf,'color','w');    
end
%}


%{
figure;
for i = 1:length(in_dist_from_pcl)
    if ~ismember(in_dist_from_pcl(i,1), omit_in)
        idx = find([in_axon_sagittal_area_isomip2{:,1}]==in_dist_from_pcl(i,1));
        plot(ngrid, [in_axon_sagittal_area_isomip2{idx,2:end}], '-o', 'LineWidth',2); hold on;
    end
end
set(gca,'FontSize',24); set(gcf,'color','w'); xlabel('Grid spacing'); ylabel('Area');

inpc_syn_density = zeros(nin,numel(ngrid));
for i = 1:nin
    inpc_info = get_syn_info(in_dist_from_pcl(i,1), 'pc');
    [nsyn,~] = size(inpc_info);
    idx = find([in_axon_sagittal_area_isomip2{:,1}]==in_dist_from_pcl(i,1));
    for j = 1:numel(ngrid)
        inpc_syn_density(i,j) = nsyn / in_axon_sagittal_area_isomip2{idx,j+1};
    end
end

avg_area = zeros(numel(ngrid),1);
avg_syn_density = zeros(numel(ngrid),1);
for j=1:numel(ngrid)
    avg_syn_density(j)= mean(inpc_syn_density(ismember(in_dist_from_pcl(:,1),in1_ids),j));
    avg_area(j) = mean([in_axon_sagittal_area_isomip2{ismember(in_dist_from_pcl(:,1),in1_ids),j+1}]);
end

% expected number of missing somatic synapses
e_somatic= zeros(numel(axon_expecting_basket),numel(ngrid));
for i = 1:numel(axon_expecting_basket)
    for j = 1:numel(ngrid)
        idx=find([in_axon_sagittal_area_isomip2{:,1}] == axon_expecting_basket(i));
        area_miss = avg_area(j) - in_axon_sagittal_area_isomip2{idx,j+1};
        e_somatic(i,j) = area_miss * avg_syn_density(j);
    end
end

figure('Position',[100 500 1800 650]);
for j = 1:numel(ngrid)
    subplot(2,4,j);
    for i = 1:nin
        scatter(in_dist_from_pcl(i,2), inpc_syn_density(i,j), 50, coral,'filled'); hold on;
        if ismember(in_dist_from_pcl(i,1), in2_ids)
            scatter(in_dist_from_pcl(i,2), inpc_syn_density(i,j), 50, petrol,'filled'); hold on;
        end
    end
    title(['Grid spacing ', num2str(ngrid(j))]); grid minor; 
    xlabel('Dist from PCL'); ylabel('#syn / covhull area'); ylim([0, 0.0003]);
    set(gca,'FontSize',22,'LineWidth',1.5); set(gcf,'color','w'); 
end

figure('Position',[100 500 1800 650]);
for j = 1:numel(ngrid)
    subplot(2,4,j);
    for i = 1:numel(axon_expecting_basket)
        idx = axon_expecting_basket(i) == in_dist_from_pcl(:,1);
        scatter(in_dist_from_pcl(idx,2), e_somatic(i,j), 60, coral,'filled'); hold on;
    end
    title(['Grid spacing ', num2str(ngrid(j))]); grid minor; ylim([-100,100]);
    xlabel('Dist from PCL'); ylabel('missing area * syn density'); 
    set(gca,'FontSize',20,'LineWidth',1.5); set(gcf,'color','w'); 
end

figure('Position',[100 500 1800 650]);
for j = 1:numel(ngrid)
    subplot(2,4,j);
    for i = 1:numel(axon_expecting_basket)
        idx = axon_expecting_basket(i) == in_dist_from_pcl(:,1);
        scatter(in_dist_from_pcl(idx,2), avg_area(j) - in_axon_sagittal_area_isomip2{idx,j+1}, 70, damson_blk,'filled'); hold on;
    end
    title(['Grid spacing ', num2str(ngrid(j))]); grid minor; 
    xlabel('Dist from PCL'); ylabel('avg area - this area'); ylim([-2000000, 3000000]);
    set(gca,'FontSize',20,'LineWidth',1.5); set(gcf,'color','w'); yline(0);
end

load('/data/research/cjpark147/conn_analysis/inpc_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/inin_syn_rot_wrt_pcl.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
inpc_syn_rot = inpc_syn_rot_pcl;
spi = zeros(nin,numel(ngrid));spi_size = spi;
excluded = [19];
mean_soma_syn_size= 57224;
for j = 1:numel(ngrid)
uncertain_axon_w_small_area = axon_expecting_basket(e_somatic(:,j) > 0); 
    for i = 1:nin
        if ~ismember(inpc_syn_rot{i,1}, excluded) 
            [ndend,~] = size(inpc_syn_rot{i,2}.dend);
            [nsoma,~] = size(inpc_syn_rot{i,2}.soma);
            dend_contact_size = sum(inpc_syn_rot{i,2}.dend_contact_size);
            soma_contact_size = sum(inpc_syn_rot{i,2}.soma_contact_size);
            idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));        
            if ismember(inpc_syn_rot{i,1}, uncertain_axon_w_small_area)
                idx3 = inpc_syn_rot{i,1} == axon_expecting_basket;
                nsoma = nsoma + e_somatic(idx3,j);
                soma_contact_size = soma_contact_size + (e_somatic(idx3,j) * mean_soma_syn_size);
            end
            spi(i,j) =(nsoma-ndend)/(nsoma+ndend);
            spi_size(i,j) = (soma_contact_size - dend_contact_size) / (soma_contact_size + dend_contact_size);
        end
    end
end

f=figure('Position',[100 500 1800 1000]);
for j = 1:numel(ngrid)
    subplot(2,4,j); 
    for i = 1:nin
        if ~ismember(inpc_syn_rot{i,1}, excluded) 
            idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
            scatter(in_dist_from_pcl(idx,2), spi_size(i,j), 70, coral,'filled'); hold on;
            if ismember(in_dist_from_pcl(idx,1), in2_ids)
                scatter(in_dist_from_pcl(idx,2), spi_size(i,j), 70, petrol,'filled'); hold on;
            end        
        end
    end
    title(['Grid spacing ',num2str(ngrid(j))]);grid minor; xlabel('Dist from PCL'); ylabel('SPI (size)'); set(gca,'FontSize',22,'LineWidth',1.5); set(gcf,'color','w'); 
end

f2=figure('Position',[100 500 1800 1000]);
for j = 1:numel(ngrid)
    subplot(2,4,j);
    for i = 1:nin
        if ~ismember(inpc_syn_rot{i,1}, excluded) 
            idx = find(inpc_syn_rot{i,1}==in_dist_from_pcl(:,1));
            scatter(in_dist_from_pcl(idx,2), spi(i,j), 70, coral,'filled'); hold on;
            if ismember(in_dist_from_pcl(idx,1), in2_ids)
                scatter(in_dist_from_pcl(idx,2), spi(i,j), 70, petrol,'filled'); hold on;
            end        
        end
    end
    title(['Grid spacing ', num2str(ngrid(j))]);grid minor; xlabel('Dist from PCL'); ylabel('SPI (num)'); set(gca,'FontSize',22,'LineWidth',1.5); set(gcf,'color','w'); 
end
%}
    

%% synapse density IN->PC asymmetry 

%{
inpc_syn_height = cell(numel(list_of_target_interneurons),1);
num_syn_above_in_dend = zeros(numel(list_of_target_interneurons),1);
num_syn_below_in_dend = zeros(numel(list_of_target_interneurons),1);
num_axon_skel_above_dend = num_syn_below_in_dend;
num_axon_skel_below_dend = num_syn_below_in_dend;
density_syn_up = num_syn_below_in_dend;
density_syn_down = num_syn_below_in_dend;

for i = 1:numel(list_of_target_interneurons)
    num_targets = length(inpc_syn_rot{i,2});
    for j = 1:num_targets
        syncoords = inpc_syn_rot{i,2}{:,2};
        if ~isempty(syncoords)
            inpc_syn_height{i,1} = [inpc_syn_height{i,1}; syncoords(:,3)];
        end
    end
end

for i = 1:numel(in_pcl_dist_sort)
    idx = find(list_of_target_interneurons == in_pcl_dist_sort(i));
    skel = [];
    for j = 1:length(int_branch_axon{1,idx})
        skel = [skel; int_branch_axon{1,idx}{1,j}];
    end
    skel(:,3) = skel(:,3)*4;
    skel_rot = round(map_voxel_to_rotated_vol(skel));
    num_axon_skel_above_dend(i) = sum(skel_rot(:,3) > median_in(idx));
    num_axon_skel_below_dend(i) = sum(skel_rot(:,3) < median_in(idx));
    num_syn_above_in_dend(i) = sum(inpc_syn_height{idx,1} > median_in(idx));
    num_syn_below_in_dend(i) = sum(inpc_syn_height{idx,1} < median_in(idx));
    density_syn_up(i) = num_syn_above_in_dend(i) / (num_axon_skel_above_dend(i));
    density_syn_down(i) = num_syn_below_in_dend(i) / (num_axon_skel_below_dend(i));
end

plot(density_syn_up);
hold on;
plot(density_syn_down);
%}
































