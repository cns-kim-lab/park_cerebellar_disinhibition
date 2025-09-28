%% This is a simplified code for figure using pre-computed data.
% See the sections at the end of this script for the data computation script.

% load pre-computed data
load("./mat/pfin_counts_near_randomized_cfin.mat");
load("./mat/pfin_counts_near_cfin.mat");

ntrial = size(pfin_counts_near_cfin1_syn_rand,2);
% synapse only
counts1 = [vertcat(pfin_counts_near_cfin1_syn{:,1});vertcat(pfin_counts_near_cfin2_syn{:,1})];
counts2 = [vertcat(pfin_counts_near_cfin1_nonsyn{:,1});vertcat(pfin_counts_near_cfin2_nonsyn{:,1})];
p1 = zeros(ntrial,1); p3=p1; p4=p1; p5=p1; p6=p1; p7=p1; p8=p1; p9=p1;
p2 = zeros(ntrial,1);




for i=1:ntrial
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_syn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
    
    %{
    [p0,~,~] = ranksum(counts1, counts2);
    [p1(i),~,~] = ranksum(counts1, rand_counts1);
    [p2(i),~,~] = ranksum(counts2, rand_counts2);    
    [p3(i),~,~] = ranksum(counts1, rand_counts1, 'tail','right');
    [p4(i),~,~] = ranksum(counts2, rand_counts2, 'tail','right');
    % p3,p4 <0.05 suggests left is larger than right
    [p5(i),~,~] = ranksum(counts1, rand_counts1, 'tail','left');
    [p6(i),~,~] = ranksum(counts2, rand_counts2, 'tail','left');
    [p7(i),~,~] = ranksum(rand_counts1, rand_counts2);
    [p8(i),~,~] = ranksum(rand_counts1, rand_counts2, 'tail','right');
    [p9(i),~,~] = ranksum(rand_counts1, rand_counts2, 'tail','left');
    %}

    [~,p0] = ttest2(counts1, counts2);
    [~,p1(i),~,~] = ttest2(counts1, rand_counts1);
    [~,p2(i),~,~] = ttest2(counts2, rand_counts2);    
    [~,p3(i),~,~] = ttest2(counts1, rand_counts1, 'tail','right');
    [~,p4(i),~,~] = ttest2(counts2, rand_counts2, 'tail','right');
    % p3,p4 <0.05 suggests left is larger than right
    [~,p5(i),~,~] = ttest2(counts1, rand_counts1, 'tail','left');
    [~,p6(i),~,~] = ttest2(counts2, rand_counts2, 'tail','left');
    [~,p7(i),~,~] = ttest2(rand_counts1, rand_counts2);
    [~,p8(i),~,~] = ttest2(rand_counts1, rand_counts2, 'tail','right');
    [~,p9(i),~,~] = ttest2(rand_counts1, rand_counts2, 'tail','left'); 
%}
end

for i=1:1
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_syn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
end 
% normality test
[h1,pn1] = kstest((counts1 - mean(counts1))/std(counts1));
[h2,pn2] = kstest((counts2 - mean(counts2))/std(counts2));
[h3,pn3] = kstest((rand_counts1 - mean(rand_counts1))/std(rand_counts1));
[h4,pn4] = kstest((rand_counts2 - mean(rand_counts2))/std(rand_counts2));
disp(['kstest p-val=',num2str(pn1)])
disp(['kstest p-val=',num2str(pn2)])
disp(['kstest p-val=',num2str(pn3)])
disp(['kstest p-val=',num2str(pn4)])

% count number of obs < rand and obs > rand
idx = p1<0.05;
pl=p3(idx);
pr=p5(idx);
nobs_smaller_than_rand = sum(pr<0.05);
nobs_larger_than_rand = sum(pl<0.05);
disp(nobs_smaller_than_rand)
disp(nobs_larger_than_rand)

idx = p2<0.05;
pl=p4(idx);
pr=p6(idx);
nobs_smaller_than_rand = sum(pr<0.05);
nobs_larger_than_rand = sum(pl<0.05);
disp(nobs_smaller_than_rand)
disp(nobs_larger_than_rand)

idx = p7<0.05;
pl=p8(idx);
pr=p9(idx);
nobs_smaller_than_rand = sum(pr<0.05);
nobs_larger_than_rand = sum(pl<0.05);
disp(nobs_smaller_than_rand)
disp(nobs_larger_than_rand)


f = figure('Position',[100 100 850 600]);
violin_data = [];
violin_data = [violin_data; repmat(1, numel(counts1), 1), counts1];
violin_data = [violin_data; repmat(2, numel(counts2), 1), counts2];
violin_data = [violin_data; repmat(3, numel(rand_counts1), 1), rand_counts1];
violin_data = [violin_data; repmat(4, numel(rand_counts2), 1), rand_counts2];
color_in1 = [250,50,50]/255;
color_in2 = [50,110,180]/255;
vp = violinplot(violin_data(:,2), round(violin_data(:,1)),'ViolinColor', [100,100,100]/255);
for i = 1:4
    vp(i).ScatterPlot.MarkerFaceAlpha = 0;
    vp(i).ScatterPlot.SizeData = 70;
    vp(i).BoxWidth = 0.04;
end  
vp(2).ViolinColor = [180,180,180]/255;
vp(4).ViolinColor = [180,180,180]/255;
jitter_amount = 0.5;  % adjust as needed
x1= repmat(1, numel(vertcat(pfin_counts_near_cfin1_syn{:,1})), 1);
x_jittered = x1 + (rand(size(x1)) - 0.5) * jitter_amount;
x2= repmat(1, numel(vertcat(pfin_counts_near_cfin2_syn{:,1})), 1);
x_jittered2 = x2 + (rand(size(x2)) - 0.5) * jitter_amount;
x3= repmat(2, numel(vertcat(pfin_counts_near_cfin1_nonsyn{:,1})), 1);
x_jittered3 = x3 + (rand(size(x3)) - 0.5) * jitter_amount;
x4= repmat(2, numel(vertcat(pfin_counts_near_cfin2_nonsyn{:,1})), 1);
x_jittered4 = x4 + (rand(size(x4)) - 0.5) * jitter_amount;

x5= repmat(3, numel(vertcat(pfin_counts_near_cfin1_syn_rand{:,1})), 1);
x_jittered5 = x5 + (rand(size(x5)) - 0.5) * jitter_amount;
x6= repmat(3, numel(vertcat(pfin_counts_near_cfin2_syn_rand{:,1})), 1);
x_jittered6 = x6 + (rand(size(x6)) - 0.5) * jitter_amount;
x7= repmat(4, numel(vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,1})), 1);
x_jittered7 = x7 + (rand(size(x7)) - 0.5) * jitter_amount;
x8= repmat(4, numel(vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,1})), 1);
x_jittered8 = x8 + (rand(size(x8)) - 0.5) * jitter_amount;

scatter(x_jittered, vertcat(pfin_counts_near_cfin1_syn{:,1}),40, color_in1, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered2, vertcat(pfin_counts_near_cfin2_syn{:,1}),40, color_in2, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered3, vertcat(pfin_counts_near_cfin1_nonsyn{:,1}),40, color_in1, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered4, vertcat(pfin_counts_near_cfin2_nonsyn{:,1}),40, color_in2, 'filled', 'MarkerFaceAlpha', 1);

scatter(x_jittered5, vertcat(pfin_counts_near_cfin1_syn_rand{:,1}),40, color_in1, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered6, vertcat(pfin_counts_near_cfin2_syn_rand{:,1}),40, color_in2, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered7, vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,1}),40, color_in1, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered8, vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,1}),40, color_in2, 'filled', 'MarkerFaceAlpha', 1);

set(gcf,'color','w');
ylabel('#PF-IN synapses within 1 \mum');
set(gca,'FontSize',20);
ylim([0, max(ylim)+1]);
hold on;yticks(0:1:ceil(max(ylim)));
yt=get(gca,'YTick'); xt = get(gca,'XTick');
ax=gca;
ax.XTickLabel ={'Syn' , 'App', 'Syn-rand' , 'App-rand'};


%% Script for the data computations
% "pfin_counts_near_randomized_cfin.mat"
% "pfin_counts_near_cfin.mat";
% This section requires 600GB .h5 segmentation file.

cf_ids = [463;227;7;681;453;772;878;931;166;953];
load('./mat/in1_ids.mat');
load('./mat/in2_ids.mat');
load('./mat/cfin_contacts_info.mat')
in_ids = [in1_ids;in2_ids];

cfin_syn_data = readtable('/Users/changjoopark/volume_3/research/cjpark147/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');
seg = h5read('segment_iso_mip3_all_cells_210503_revised.pc_cb_cut_and_int_axon_cut.sample_first_sheet.int_cb_cut.h5','/main');
aa = get_syn_info(cf_ids,in_ids);
cfin_id_ai_positive = aa(:,1);
cfin_ai_positive = cfin_contacts(ismember(cfin_contacts.intf_id,cfin_id_ai_positive),:);
cfin_ai_negative = cfin_contacts(~ismember(cfin_contacts.intf_id,cfin_id_ai_positive),:);
cfin_true_positive = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_syn_data.intf_id),:);
cfin_false_positive = cfin_ai_positive(~ismember(cfin_ai_positive.intf_id, cfin_syn_data.intf_id),:);

% Observed CF-IN contacts per IN
pfin_counts_near_cfin1_syn = cell(numel(in1_ids),1);
pfin_counts_near_cfin1_nonsyn = cell(numel(in1_ids),1);
pfin_counts_near_cfin2_syn = cell(numel(in2_ids),1);
pfin_counts_near_cfin2_nonsyn = cell(numel(in2_ids),1);
distances = [1];
target_in_ids = in1_ids;
for i= 1:numel(target_in_ids)
    pfin_info = get_syn_info('pf', target_in_ids(i));
    pfin_syn_pos = [pfin_info(:,8:9)/4, pfin_info(:,10)];
    % syn
    rows = cfin_true_positive(ismember(cfin_true_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        cfin_contact_pos = [rows.contact_x/4, rows.contact_y/4, rows.contact_z];
        D_contact = pdist2(cfin_contact_pos, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
        pfin_counts_near_cfin1_syn{i,1} = sum(D_contact < distances(1),2);
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        cfin_contact_pos = [rows.contact_x/4, rows.contact_y/4, rows.contact_z];
        D_contact = pdist2(cfin_contact_pos, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
        pfin_counts_near_cfin1_nonsyn{i,1} = sum(D_contact < distances(1),2);
    end        
    disp(i)    
end
target_in_ids = in2_ids;
for i= 1:numel(target_in_ids)
    pfin_info = get_syn_info('pf', target_in_ids(i));
    pfin_syn_pos = [pfin_info(:,8:9)/4, pfin_info(:,10)];
    % syn
    rows = cfin_true_positive(ismember(cfin_true_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        cfin_contact_pos = [rows.contact_x/4, rows.contact_y/4, rows.contact_z];
        D_contact = pdist2(cfin_contact_pos, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
        pfin_counts_near_cfin2_syn{i,1} = sum(D_contact < distances(1),2);
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        cfin_contact_pos = [rows.contact_x/4, rows.contact_y/4, rows.contact_z];
        D_contact = pdist2(cfin_contact_pos, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
        pfin_counts_near_cfin2_nonsyn{i,1} = sum(D_contact < distances(1),2);
    end        
    disp(i)    
end


% Random shuffles of observed CF-IN contacts per IN
ntrial = 100;
pfin_counts_near_cfin1_syn_rand = cell(numel(in1_ids),ntrial);
pfin_counts_near_cfin1_nonsyn_rand = cell(numel(in1_ids),ntrial);
pfin_counts_near_cfin2_syn_rand = cell(numel(in2_ids),ntrial);
pfin_counts_near_cfin2_nonsyn_rand = cell(numel(in2_ids),ntrial);
distances = [1];
target_in_ids = in1_ids;
for i= 1:numel(target_in_ids)
    bw = (seg == target_in_ids(i)*100);
    surface_mask = bwperim(bw,6);
    [x, y, z] = ind2sub(size(seg), find(surface_mask));
    surface_coords = [x(1:4:end)*2, y(1:4:end)*2, z(1:4:end)*2];
    pfin_info = get_syn_info('pf', target_in_ids(i));
    pfin_syn_pos = [pfin_info(:,8:9)/4, pfin_info(:,10)];
    % syn
    rows = cfin_true_positive(ismember(cfin_true_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            cfin_contact_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos_rand, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin1_syn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            cfin_contact_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos_rand, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin1_nonsyn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end        
    disp(i)    
end
target_in_ids = in2_ids;
for i= 1:numel(target_in_ids)
    bw = (seg == target_in_ids(i)*100);
    surface_mask = bwperim(bw,6);
    [x, y, z] = ind2sub(size(seg), find(surface_mask));
    surface_coords = [x(1:4:end)*2, y(1:4:end)*2, z(1:4:end)*2];
    pfin_info = get_syn_info('pf', target_in_ids(i));
    pfin_syn_pos = [pfin_info(:,8:9)/4, pfin_info(:,10)];
    % syn
    rows = cfin_true_positive(ismember(cfin_true_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            cfin_contact_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos_rand, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin2_syn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(rows,1);
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            cfin_contact_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos_rand, pfin_syn_pos)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin2_nonsyn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end        
    disp(i)    
end

