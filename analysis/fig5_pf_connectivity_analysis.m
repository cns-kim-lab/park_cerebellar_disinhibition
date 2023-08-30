
load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
load('/data/research/cjpark147/conn_analysis/pf_ids.mat');
load('/data/research/cjpark147/conn_analysis/pf_within_pc_dendritic_field.mat');
load('/data/research/cjpark147/conn_analysis/selected_cell_ids.mat');
addpath /data/research/cjpark147/code/ref

pc_ids = [18,11,4,13,21,20,49,50,3,175];
cf_ids = [463;227;7;681;453;772;878;931;166;953];
nin1=numel(in1_ids); nin2 = numel(in2_ids); npf = numel(pf_ids);
in_ids = [in1_ids;in2_ids]; nin = nin1+nin2;
npc = numel(pc_ids);

%% PF type sorting 

% Possible types of PF:
% type1 = PF - PC
% type2 = PF - PC,IN1
% type3 = PF - PC,IN2
% type4 = PF - PC,IN1,IN2
% type5 = PF - IN1,IN2
% type6 = PF - IN1
% type7 = PF - IN2
% type8 = PF - 

pf_unique_type_sorted = cell(npc,8);

for i = 1:npc
    pf_sur = pf_within_pc_dendritic_field{i,2};
    info = get_syn_info(pf_sur, pc_ids(i));
    pf1 = unique(info(:,3));    % PF connected to PC
    pf0 = setdiff(pf_sur, pf1);  % PF not connected to PC
    info = get_syn_info(in1_ids, pc_ids(i));
    in1_pre = unique(info(:,3));
    info = get_syn_info(in2_ids, in1_pre);
    in2_pre = unique(info(:,3));
    
    info = get_syn_info(pf_sur, in1_pre);
    pf_to_in1 = unique(info(:,3));
    info = get_syn_info(pf_sur, in2_pre);
    pf_to_in2 = unique(info(:,3));
    pf_to_both_in1_in2 = intersect(pf_to_in1, pf_to_in2);
    
    % Sort type4 and 5 first which connect both IN1 and IN2 assuming/forcing it cannot be any other type, although it can be.
    % This is not a problem since type4, and 5 is almost non-existent and thus not important.
    pf_unique_type_sorted{i,4}=intersect(pf_to_both_in1_in2, pf1);
    pf_unique_type_sorted{i,5}=intersect(pf_to_both_in1_in2, pf0);
    
    % type 1
    pf_unique_type_sorted{i,1}=setdiff(pf1, union(pf_to_in1, pf_to_in2));
    pf_unique_type_sorted{i,2}=setdiff(intersect(pf1, pf_to_in1), pf_unique_type_sorted{i,4});
    pf_unique_type_sorted{i,3}=setdiff(intersect(pf1, pf_to_in2), pf_unique_type_sorted{i,4});
    pf_unique_type_sorted{i,6}=setdiff(intersect(pf0, pf_to_in1), pf_unique_type_sorted{i,5});
    pf_unique_type_sorted{i,7}=setdiff(intersect(pf0, pf_to_in2), pf_unique_type_sorted{i,5});
    pf_unique_type_sorted{i,8}=setdiff(pf0, union(pf_to_in1, pf_to_in2));
    fprintf('%d',i);
end

%save('/data/research/cjpark147/conn_analysis/pf_unique_type_sorted.mat', 'pf_unique_type_sorted');

%}


%% Fraction of PFs sorted by PF types

% type1 = PF - IN2
% type2 = PF - PC,IN2
% type3 = PF - IN1
% type4 = PF - PC,IN1
% type5 = PF - PC
% type6 = PF - PC,IN1,IN2
% type7 = PF - IN1,IN2
% type8 = PF - 


load('/data/research/cjpark147/conn_analysis/pf_unique_type_sorted.mat');
addpath /data/research/cjpark147/code/ref
nm_per_pc = zeros(npc,8);
for i = 1:npc
    for j =1:8
        nm_per_pc(i,j) = numel(pf_unique_type_sorted{i,j});
    end
end       
violin_data = [];

%{
for i = 1:8
    violin_data = [violin_data; ones(10,1)*i, nm_per_pc(:,i)];
end
%}

%{
% old type numbers
violin_data = [violin_data; ones(10,1)*6, nm_per_pc(:,1)];
violin_data = [violin_data; ones(10,1)*3, nm_per_pc(:,2)];
violin_data = [violin_data; ones(10,1)*5, nm_per_pc(:,3)];
violin_data = [violin_data; ones(10,1)*2, nm_per_pc(:,4)];
violin_data = [violin_data; ones(10,1)*1, nm_per_pc(:,5)];
violin_data = [violin_data; ones(10,1)*4, nm_per_pc(:,6)];
violin_data = [violin_data; ones(10,1)*7, nm_per_pc(:,7)];
violin_data = [violin_data; ones(10,1)*8, nm_per_pc(:,8)];
%}

violin_data = [violin_data; ones(10,1)*1, nm_per_pc(:,1)];
violin_data = [violin_data; ones(10,1)*2, nm_per_pc(:,2)];
violin_data = [violin_data; ones(10,1)*3, nm_per_pc(:,3)];
violin_data = [violin_data; ones(10,1)*4, nm_per_pc(:,4)];
violin_data = [violin_data; ones(10,1)*5, nm_per_pc(:,5)];
violin_data = [violin_data; ones(10,1)*6, nm_per_pc(:,6)];
violin_data = [violin_data; ones(10,1)*7, nm_per_pc(:,7)];
violin_data = [violin_data; ones(10,1)*8, nm_per_pc(:,8)];

ff1=figure('Position',[100 500 1400 700]);
v = violinplot(violin_data(:,2)*100, violin_data(:,1),'ViolinColor', petrol);
%v(2).ViolinColor = petrol;
%v(3).ViolinColor = [120,70,120]/255;
%v(4).ViolinColor = gray;
%xticks([0:25:150]); xticklabels([0:25:150]); yticks([-30,0,50,100,150]); yticklabels([-30,0,50,100,150]);  ylim([-35 160]);
xlabel('Possible types of PF'); ylabel('Number of nearby PF');
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
ss = sum(nm_per_pc,2);
violin_data2 = [];

%{
for i = 1:8
    violin_data2 = [violin_data2; ones(10,1)*i, nm_per_pc(:,i)./ss];
end
%}

%{
%old type numbering
violin_data2 = [violin_data2; ones(10,1)*6, nm_per_pc(:,1)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*3, nm_per_pc(:,2)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*5, nm_per_pc(:,3)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*2, nm_per_pc(:,4)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*1, nm_per_pc(:,5)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*4, nm_per_pc(:,6)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*7, nm_per_pc(:,7)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*8, nm_per_pc(:,8)./count_pf_sur];
%}
violin_data2 = [violin_data2; ones(10,1)*1, nm_per_pc(:,1)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*2, nm_per_pc(:,2)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*3, nm_per_pc(:,3)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*4, nm_per_pc(:,4)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*5, nm_per_pc(:,5)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*6, nm_per_pc(:,6)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*7, nm_per_pc(:,7)./count_pf_sur];
violin_data2 = [violin_data2; ones(10,1)*8, nm_per_pc(:,8)./count_pf_sur];

ff2=figure('Position',[100 500 1100 700]);
v = violinplot(violin_data2(:,2)*100, violin_data2(:,1),'ViolinColor', [180,85,180]/255);
%v(2).ViolinColor = petrol;
%v(3).ViolinColor = [120,70,120]/255;
%v(4).ViolinColor = gray;
%xticks([0:25:150]); xticklabels([0:25:150]); yticks([-30,0,50,100,150]); yticklabels([-30,0,50,100,150]);  ylim([-35 160]);
xlabel('PF types'); ylabel('Proportion (%)');
set(gcf, 'color', 'w'); set(gca,'FontSize',24);

ff3=figure('Position',[100 500 1100 700]);
mu = mean(nm_per_pc ./ sum(nm_per_pc,2));
stdev = std(nm_per_pc ./ sum(nm_per_pc,2));
h = bar(mu, 'BarWidth', 0.7); hold on;
xb = get(h,'XData').' + [h.XOffset];
er = errorbar(xb, mu, stdev, 'k.'); er(1).LineWidth=1; 
set(h, 'FaceColor', [180,110,180]/255);
ylabel('Fraction'); %ylim([0, 100]);
set(gcf,'color','w'); set(gca,'FontSize',20);
%}

%{
% pie chart
f =figure; set(gcf,'color','w'); set(gca,'FontSize',17);
%mean_frac_pie = [6.1, 4.7, 13.2, 5.1, 24.5, 0.3, 0.4, 45.7];
mean_frac_pie = [5, 3.8, 10.3, 4.1, 26.4, 0.1, 0.2, 50.1];
labels = {'1','2','3','4','5','6','7','8'};
pie(mean_frac_pie, labels); 
%}
