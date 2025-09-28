load("./mat/pfin_counts_near_randomized_cfin.mat");
load("./mat/pfin_counts_near_cfin.mat");
ntrial = size(pfin_counts_near_cfin1_syn_rand,2);
color_in1 = [250,50,50]/255;
color_in2 = [50,110,180]/255;
% IN1 vs IN2
counts1 = [vertcat(pfin_counts_near_cfin1_syn{:,1});vertcat(pfin_counts_near_cfin1_nonsyn{:,1})];
counts2 = [vertcat(pfin_counts_near_cfin2_syn{:,1});vertcat(pfin_counts_near_cfin2_nonsyn{:,1})];
p1 = zeros(ntrial,1); p3=p1; p4=p1; p5=p1; p6=p1; p7=p1; p8=p1; p9=p1;
p2 = zeros(ntrial,1);
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

for i=2:2
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin2_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
end
f = figure('Position',[100 100 800 600]);
violin_data = [];
violin_data = [violin_data; repmat(1, numel(counts1), 1), counts1];
violin_data = [violin_data; repmat(2, numel(counts2), 1), counts2];
violin_data = [violin_data; repmat(3, numel(rand_counts1), 1), rand_counts1];
violin_data = [violin_data; repmat(4, numel(rand_counts2), 1), rand_counts2];
vp = violinplot(violin_data(:,2), round(violin_data(:,1)), 'ViolinColor', color_in1);
for i = 1:4
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.8;
    vp(i).ScatterPlot.SizeData = 70;
    vp(i).BoxWidth = 0.04;
end  
vp(2).ViolinColor = color_in2;
vp(4).ViolinColor = color_in2;
set(gcf,'color','w');
ax=gca;
ax.XTickLabel ={'IN1' , 'IN2', 'IN1-r' , 'IN2-r'};
ylabel('#PF-IN synapses within 1 \mum');
set(gca,'FontSize',20);
ylim([0, max(ylim)+1]);
hold on;yticks(0:1:ceil(max(ylim)));
yt=get(gca,'YTick'); xt = get(gca,'XTick');

%% save figure
save_figure(f,'fig_3m','svg');

