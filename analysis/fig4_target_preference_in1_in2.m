load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
load('/data/research/cjpark147/conn_analysis/in_dend_rot.mat');
load('/data/research/cjpark147/conn_analysis/in_axon_rot.mat');
load('/data/research/cjpark147/conn_analysis/inpc_syn_rot_merged.mat');
load('/data/research/cjpark147/conn_analysis/inin_syn_rot_merged.mat');
load('/data/research/cjpark147/conn_analysis/interneuron_height_in_avg_dir.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
nin1=numel(in1_ids); nin2 = numel(in2_ids);
in_ids = [in1_ids;in2_ids]; nin = nin1+nin2;
pc_ids = [18,11,4,13,21,20,49,50,3,175];
cf_ids = [463;227;7;681;453;772;878;931;166;953];

%% Visualization of IN1 and IN2 output differences  

f3a3=figure('Position', [300,300,700,500]);
in = target_interneurons_new;
[nin_this,~] = size(in_dist_from_pcl(:,1));
median_in = median_dend_height_in_avg_dir; 
excluded = [19];  npanel=1;
panel_count = 1;

for i = 13:13   % i=9 or 13
    if ismember(i,[9,13])
        idx = find(in==in_dist_from_pcl(i,1));
        subplot(1,1,panel_count);
        panel_count = panel_count + 1;
        s1=scatter(in_axon_rot{idx,2}(1:5:end,1), in_axon_rot{idx,2}(1:5:end,2), 4, [180,175,180]/255, 'filled','o');  hold on;
        s11=scatter(in_dend_rot{idx,2}(1:5:end,1), in_dend_rot{idx,2}(1:5:end,2), 4,  [180,175,180]/255, 'filled','o'); 
        % in-> in syn
         [num_targets,~] = size(inin_syn_rot{idx,2});
         
         
       for j = 1:num_targets
           hold on;
           if ~isempty(inin_syn_rot{idx,2})
               s2=scatter(inin_syn_rot{idx,2}(:,1), inin_syn_rot{idx,2}(:,2),60, petrol,'filled','o');           
            %   s2=scatter(inin_syn_rot{idx,2}(:,1), inin_syn_rot{idx,2}(:,2),40, blue2,'filled','o', 'MarkerEdgeColor', damson_blk, 'LineWidth',1);         
           end
        end               
        % in -> pc syn
        [num_targets,~] = size(inpc_syn_rot{idx,2});
        for j = 1:num_targets
           hold on;
           if ~isempty(inpc_syn_rot{idx,2})
               s3=scatter(inpc_syn_rot{idx,2}(:,1), inpc_syn_rot{idx,2}(:,2),60, coral,'filled','o');
          %     s3=scatter(inpc_syn_rot{idx,2}(:,1), inpc_syn_rot{idx,2}(:,2),40, coral,'filled','o', 'MarkerEdgeColor', damson_blk, 'LineWidth',1);
           end
        end                  
         
%        yline(median_in(idx), ':','LineWidth', 2, 'FontSize',20);
        ylim([-50 2500]);  xlim([30 3700]);
        set(gca,'XTickLabel',[],'YTickLabel', []); set(gca,'FontSize',24);     
        
        if ismember(i, [9,13])
            h=legend([s1,s3,s2],{'Neurite','Outputs to PC', 'Outputs to IN'}, 'Location', 'northoutside', 'FontSize',20, 'Orientation','horizontal'); 
            h.LineWidth = 3;
            legend boxoff;
        end        
        set(gca,'ydir', 'reverse');
    end    
end
h = axes(f3a3, 'visible','off'); h.Title.Visible='on'; h.XLabel.Visible='on'; h.YLabel.Visible='on';
%title(h, 'Synaptic architectures of axons', 'FontSize',24);
xlabel(h,'X','FontSize',26);    ylabel(h,'Y','FontSize',26);
set(gcf,'color','w');
%}

%%  Target preference index  (Number of synapse , Synapse area) 

in_with_cf_input = [22;27;30;31;40; 10;35;64];
in_without_cf_input = setdiff(in_ids,in_with_cf_input);
load('/data/research/cjpark147/conn_analysis/in_soma_pcl_dist.mat');
in_ids_ranked = in_dist_from_pcl(:,1); markersize=140;
nin = numel(in_ids_ranked);
tpi = zeros(nin, 1);  tpi_size = zeros(nin,1);
for i = 1:nin
    syn_in = get_syn_info(in_ids_ranked(i), 'in');
    syn_pc = get_syn_info(in_ids_ranked(i), 'pc');
    [ni,~] = size(syn_in);
    [np,~] = size(syn_pc);
    tpi(i) = (ni-np) / (ni+np);
    total_size = sum(syn_in(:,8)) + sum(syn_pc(:,8));
    tpi_size(i) = (sum(syn_in(:,8)) - sum(syn_pc(:,8))) / total_size;
    %contact_size(i,1) = sum(syn_in(:,8))/total_size;
    %contact_size(i,2) = sum(syn_pc(:,8))/total_size;
end
nin_cf=  numel(in_with_cf_input); nin_nocf= numel(in_without_cf_input);

x_data1 = find(ismember(in_ids_ranked, in_without_cf_input));
x_data2 = find(ismember(in_ids_ranked, in_with_cf_input));

f3c=figure('Position', [300 800 640 450]);
scatter(x_data1, tpi(x_data1), markersize, coral, 'filled'); hold on;
scatter(x_data2, tpi(x_data2), markersize,[50,120,220]/255, 'filled'); 
%scatter(x_data1, tpi(x_data1), markersize, coral, 'filled', 'MarkerEdgeColor', damson_blk, 'LineWidth',1); hold on;
%scatter(x_data2, tpi(x_data2), markersize, petrol, 'filled', 'MarkerEdgeColor', damson_blk, 'LineWidth',1); 
yline(0, '--','LineWidth',2, 'Color', damson_blk);
xlabel('Interneurons (rank)'); ylabel('TPI_n_u_m');
set(gca,'FontSize',24); set(gcf,'color','w');

f3c2=figure('Position', [1500 800 640 450]);
scatter(x_data1, tpi_size(x_data1), markersize, coral, 'filled'); hold on;
scatter(x_data2, tpi_size(x_data2), markersize, [50,120,220]/255, 'filled'); 
%scatter(x_data1, tpi_size(x_data1), markersize, coral, 'filled', 'MarkerEdgeColor', damson_blk, 'LineWidth',1); hold on;
%scatter(x_data2, tpi_size(x_data2), markersize, petrol, 'filled', 'MarkerEdgeColor', damson_blk, 'LineWidth',1); 
yline(0, '--','LineWidth',2, 'Color', damson_blk);
xlabel('Interneurons'); ylabel('TPI_s_i_z_e');
set(gca,'FontSize',24); set(gcf,'color','w');
%}
%{
% old version
f0=figure;
color_scale = tpi./max(tpi);
scatter(ones(nin,1), [1:nin]*15, 200, color_scale, 's','filled', 'MarkerEdgeColor' ,'none'); hold on;
colormap cool; h = colorbar('southoutside'); 
scatter(ones(nin,1)*2, [1:nin]*15, contact_size(:,1)*200, navy, 'filled', 'MarkerEdgeColor','none');
scatter(ones(nin,1)*2.6, [1:nin]*15, contact_size(:,2)*200, navy, 'filled', 'MarkerEdgeColor', 'none');
set(gcf, 'color', 'w'); set(gca,'FontSize',24); set(gca, 'xtick', []); set(gca, 'ytick', []);
set(gca,'YDir','reverse','visible','off');
%}

%% Target distribution of IN1 and IN2

load('/data/research/cjpark147/conn_analysis/in_ids_all.mat');
in1_frac = zeros(numel(in1_ids),4);
in2_frac = zeros(numel(in2_ids),4);
in1_numsyn = zeros(numel(in1_ids),5); % [pc,in1,in2,inx,all] 
in2_numsyn = in1_numsyn;
in_unclassified = setdiff(in_ids_all, [in1_ids; in2_ids]);

for i = 1:numel(in1_ids)
    this_id = in1_ids(i);
    info_in1pc = get_syn_info(this_id, 'pc');
    info_in1in1 = get_syn_info(this_id, in1_ids);
    info_in1in2 = get_syn_info(this_id, in2_ids);
    info_in1inx = get_syn_info(this_id, in_unclassified);
    [npc,~] = size(info_in1pc);     [nin1,~] = size(info_in1in1);     [nin2,~] = size(info_in1in2);
    [ninx,~] = size(info_in1inx); 
    ninx = round(ninx * 0.8);  % since 20 % were false positives
    total_syn  = npc + nin1 + nin2 + ninx;
    in1_frac(i,:) = ([npc, nin1, nin2, ninx] / total_syn);
    in1_numsyn(i,1) = npc;  in1_numsyn(i,2) = nin1;  in1_numsyn(i,3) = nin2;    in1_numsyn(i,4) = ninx;
    in1_numsyn(i,5) = total_syn;
end

for i = 1:numel(in2_ids)
    this_id = in2_ids(i);
    info_in2pc = get_syn_info(this_id, 'pc');
    info_in2in1 = get_syn_info(this_id, in1_ids);
    info_in2in2 = get_syn_info(this_id, in2_ids);   
    info_in2inx = get_syn_info(this_id, in_unclassified);
    [npc,~] = size(info_in2pc);     [nin1,~] = size(info_in2in1);     [nin2,~] = size(info_in2in2);
    [ninx,~] = size(info_in2inx); 
    ninx = round(ninx * 0.8);  % since 20 % were false positives
    total_syn  = npc + nin1 + nin2 + ninx;
    in2_frac(i,:) = ([npc, nin1, nin2, ninx] / total_syn);
    in2_numsyn(i,1) = npc;  in2_numsyn(i,2) = nin1;  in2_numsyn(i,3) = nin2;  in2_numsyn(i,4) = ninx;
    in2_numsyn(i,5) = total_syn;
end

% NaN can exist if IN doesn't make any synapse to given targets; remove records containing NaN
in1_nan_idx = any(isnan(in1_frac), 2);
in2_nan_idx = any(isnan(in2_frac), 2);
in1_frac(in1_nan_idx, :) = [];      in2_frac(in2_nan_idx, :) = [];
in1_numsyn(in1_nan_idx, :) = [];    in2_numsyn(in2_nan_idx,:) = [];

% plot 
f4=figure('Position',[300,300, 800,650]);
in1_frac_allsyn = sum(in1_numsyn(:,1:4))/sum(in1_numsyn(:,5));
in2_frac_allsyn = sum(in2_numsyn(:,1:4))/sum(in2_numsyn(:,5));
in1_total_numsyn = sum(in1_numsyn);   in2_total_numsyn = sum(in2_numsyn);
x = categorical({'IN1', 'IN2'});
y = [in1_frac_allsyn * 100; in2_frac_allsyn * 100];
b = bar(x,y,'stacked', 'BarWidth',0.4);
%title({'Target distribution of output synapses',['#IN1=',num2str(in1_numcell), ' #Syn=', num2str(in1_total_numsyn(5)), ...
%    ', #IN2=',num2str(in2_numcell),' #Syn=',num2str(in2_total_numsyn(5))]});
ylabel('Fraction of output synapses (%)'); axis tight
b(1).FaceColor = coral; 
b(2).FaceColor = petrol;
b(3).FaceColor = orange3;
b(4).FaceColor = brown;
set(gcf,'color','w'); set(gca,'Fontsize', 24); legend({' PC ', ' IN1 ', ' IN2 ',  ' INx '}, 'FontSize',22);

% plot mean and standard error bars for target distribution 
[in1_numcell,~] = size(in1_frac); [in2_numcell,~] = size(in2_frac);
in1_frac_avg = sum(in1_frac)/in1_numcell;  in2_frac_avg = sum(in2_frac)/in2_numcell;
total_numsyn = sum(in1_numsyn) + sum(in2_numsyn);
in1_frac_stderr = std(in1_frac) / sqrt(in1_numcell);
in2_frac_stderr = std(in2_frac) / sqrt(in2_numcell);

f5=figure('Position',[300,300, 850, 650]);
y = [in1_frac_avg * 100; in2_frac_avg *100];
b = bar(y, 'grouped');
err = [in1_frac_stderr; in2_frac_stderr];
xb = cell2mat(get(b,'XData')).' + [b.XOffset];  hold on;
er = errorbar(xb, y, err*100, 'k.'); er(1).LineWidth=1.5; er(2).LineWidth=1.5; er(3).LineWidth=1.5; er(4).LineWidth=1.5;
%title({'Target distribution of output synapses',['#IN1=',num2str(in1_numcell), ' #Syn=', num2str(in1_total_numsyn(5)), ...
%    ', #IN2=',num2str(in2_numcell),' #Syn=',num2str(in2_total_numsyn(5))]});
ylabel('Fraction of output synapses (%)'); ylim([0, 100]);
b(1).FaceColor = [150,100,150]/255;
b(2).FaceColor = coral;
b(3).FaceColor = petrol;
b(4).FaceColor = gray;
set(gcf,'color','w'); set(gca,'Fontsize', 24, 'XTickLabel', {'IN1', 'IN2'});
legend({' PC ', ' IN1 ', ' IN2 ', ' INx ' }, 'FontSize',30, 'Location','north','Orientation','horizontal'); hold off;
%}
