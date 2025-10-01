
load("./mat/pfin_randomized_counts_near_cfin.mat");
load("./mat/pfin_counts_near_cfin.mat");
ntrial = size(pfin_counts_near_cfin1_syn_rand,2);

% IN1 vs IN2
counts1 = [vertcat(pfin_counts_near_cfin1_syn{:,1});vertcat(pfin_counts_near_cfin1_nonsyn{:,1})];
counts2 = [vertcat(pfin_counts_near_cfin2_syn{:,1});vertcat(pfin_counts_near_cfin2_nonsyn{:,1})];
p1 = zeros(ntrial,1); p3=p1; p4=p1; p5=p1; p6=p1; p7=p1; p8=p1; p9=p1;
p2 = zeros(ntrial,1); p10=p1; p11=p1;

% normality test
[h1,pn1] = kstest((counts1 - mean(counts1))/std(counts1));
[h2,pn2] = kstest((counts2 - mean(counts2))/std(counts2));
disp(['kstest p-val=',num2str(pn1)])
disp(['kstest p-val=',num2str(pn2)])


for i=1:ntrial
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin2_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
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

    [~,p10(i)] = kstest((rand_counts1 - mean(rand_counts1))/std(rand_counts1));
    [~,p11(i)] = kstest((rand_counts2 - mean(rand_counts2))/std(rand_counts2));
end
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

for i=6:6
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin2_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
end

% normality test
[h3,pn3] = kstest((rand_counts1 - mean(rand_counts1))/std(rand_counts1));
[h4,pn4] = kstest((rand_counts2 - mean(rand_counts2))/std(rand_counts2));
disp(['kstest p-val=',num2str(pn3)])
disp(['kstest p-val=',num2str(pn4)])

f3d = figure('Position',[100 100 850 600]);
violin_data = [];
violin_data = [violin_data; repmat(1, numel(counts1), 1), counts1];
violin_data = [violin_data; repmat(2, numel(counts2), 1), counts2];
violin_data = [violin_data; repmat(4, numel(rand_counts1), 1), rand_counts1];
violin_data = [violin_data; repmat(5, numel(rand_counts2), 1), rand_counts2];

vp = violinplot(violin_data(:,2), round(violin_data(:,1)), 'ViolinColor', [250,50,50]/255);
for i = 1:4
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.8;
    vp(i).ScatterPlot.SizeData = 70;
    vp(i).BoxWidth = 0.04;
end  
vp(2).ViolinColor = [60,110,210]/255;
vp(4).ViolinColor = [60,110,210]/255;
set(gcf,'color','w');
ylabel('#PF-IN synapses within 1 \mum');
set(gca,'FontSize',20);
ylim([0, max(ylim)+1]);
hold on;yticks(0:1:ceil(max(ylim)));
yt=get(gca,'YTick'); xt = get(gca,'XTick');

%}


%% Shuffle PF-IN synapse positions
%{
cf_ids = [463;227;7;681;453;772;878;931;166;953];
load('./mat/in1_ids.mat');
load('./mat/in2_ids.mat');
load('./mat/cfin_contacts_info.mat')
in_ids = [in1_ids;in2_ids];

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
        ncontact = size(pfin_info,1);
        cfin_contact_pos = [rows.contact_x/4,rows.contact_y/4,rows.contact_z];
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            pfin_syn_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos, pfin_syn_pos_rand)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin1_syn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(pfin_info,1);
        cfin_contact_pos = [rows.contact_x/4,rows.contact_y/4,rows.contact_z];
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            pfin_syn_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos, pfin_syn_pos_rand)/20; % [um], divide by 20 since 1 voxel = 50nm
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
        ncontact = size(pfin_info,1);
        cfin_contact_pos = [rows.contact_x/4,rows.contact_y/4,rows.contact_z];
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            pfin_syn_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos, pfin_syn_pos_rand)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin2_syn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end
    % nonsyn
    rows = cfin_false_positive(ismember(cfin_false_positive.seg_id2, target_in_ids(i)), :);
    if ~isempty(rows)
        ncontact = size(pfin_info,1);
        cfin_contact_pos = [rows.contact_x/4,rows.contact_y/4,rows.contact_z];
        for j = 1:ntrial
            idx = randperm(size(surface_coords,1),ncontact);
            pfin_syn_pos_rand = surface_coords(idx,:);
            D_contact = pdist2(cfin_contact_pos, pfin_syn_pos_rand)/20; % [um], divide by 20 since 1 voxel = 50nm
            pfin_counts_near_cfin2_nonsyn_rand{i,j} = sum(D_contact < distances(1),2);
        end
    end        
    disp(i)    
end
%save("pfin_randomized_counts_near_cfin.mat","pfin_counts_near_cfin2_syn_rand","pfin_counts_near_cfin2_nonsyn_rand", "pfin_counts_near_cfin1_syn_rand","pfin_counts_near_cfin1_nonsyn_rand");
%}
