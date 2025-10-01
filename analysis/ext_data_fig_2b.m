
load("./mat/pfin_randomized_counts_near_cfin.mat");
load("./mat/pfin_counts_near_cfin.mat");
ntrial = size(pfin_counts_near_cfin1_syn_rand,2);

% synapse only
counts1 = [vertcat(pfin_counts_near_cfin1_syn{:,1});vertcat(pfin_counts_near_cfin2_syn{:,1})];
counts2 = [vertcat(pfin_counts_near_cfin1_nonsyn{:,1});vertcat(pfin_counts_near_cfin2_nonsyn{:,1})];
p1 = zeros(ntrial,1); p3=p1; p4=p1; p5=p1; p6=p1; p7=p1; p8=p1; p9=p1;
p2 = zeros(ntrial,1); p10 = p1; p11=p1;

% normality test
[h1,pn1] = kstest((counts1 - mean(counts1))/std(counts1));
[h2,pn2] = kstest((counts2 - mean(counts2))/std(counts2));
disp(['kstest p-val=',num2str(pn1)])
disp(['kstest p-val=',num2str(pn2)])


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

j=2;
for i=j:j
    rand_counts1 = [vertcat(pfin_counts_near_cfin1_syn_rand{:,i});vertcat(pfin_counts_near_cfin2_syn_rand{:,i})];
    rand_counts2 = [vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,i});vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,i})];
end
% normality test
[h3,pn3] = kstest((rand_counts1 - mean(rand_counts1))/std(rand_counts1));
[h4,pn4] = kstest((rand_counts2 - mean(rand_counts2))/std(rand_counts2));
disp(['kstest p-val=',num2str(pn3)])
disp(['kstest p-val=',num2str(pn4)])

f3e = figure('Position',[100 100 850 600]);
violin_data = [];
violin_data = [violin_data; repmat(1, numel(counts1), 1), counts1];
violin_data = [violin_data; repmat(2, numel(counts2), 1), counts2];
violin_data = [violin_data; repmat(4, numel(rand_counts1), 1), rand_counts1];
violin_data = [violin_data; repmat(5, numel(rand_counts2), 1), rand_counts2];
dotcolors = [repmat([250,50,50], numel(counts1),1); repmat([50,110,180], numel(counts2),1)]/255;
vp = violinplot(violin_data(:,2), round(violin_data(:,1)), 'ViolinColor', [100,100,100]/255);
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

x5= repmat(4, numel(vertcat(pfin_counts_near_cfin1_syn_rand{:,j})), 1);
x_jittered5 = x5 + (rand(size(x5)) - 0.5) * jitter_amount;
x6= repmat(4, numel(vertcat(pfin_counts_near_cfin2_syn_rand{:,j})), 1);
x_jittered6 = x6 + (rand(size(x6)) - 0.5) * jitter_amount;
x7= repmat(5, numel(vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,j})), 1);
x_jittered7 = x7 + (rand(size(x7)) - 0.5) * jitter_amount;
x8= repmat(5, numel(vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,j})), 1);
x_jittered8 = x8 + (rand(size(x8)) - 0.5) * jitter_amount;

scatter(x_jittered, vertcat(pfin_counts_near_cfin1_syn{:,1}),40, [250,50,50]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered2, vertcat(pfin_counts_near_cfin2_syn{:,1}),40, [50,110,180]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered3, vertcat(pfin_counts_near_cfin1_nonsyn{:,1}),40, [250,50,50]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered4, vertcat(pfin_counts_near_cfin2_nonsyn{:,1}),40, [50,110,180]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered5, vertcat(pfin_counts_near_cfin1_syn_rand{:,j}),40, [250,50,50]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered6, vertcat(pfin_counts_near_cfin2_syn_rand{:,j}),40, [50,110,180]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered7, vertcat(pfin_counts_near_cfin1_nonsyn_rand{:,j}),40, [250,50,50]/255, 'filled', 'MarkerFaceAlpha', 1);
scatter(x_jittered8, vertcat(pfin_counts_near_cfin2_nonsyn_rand{:,j}),40, [50,110,180]/255, 'filled', 'MarkerFaceAlpha', 1);

set(gcf,'color','w');
ylabel('#PF-IN synapses within 1 \mum');
set(gca,'FontSize',20);
ylim([0, max(ylim)+1]);
hold on;yticks(0:1:ceil(max(ylim)));
yt=get(gca,'YTick'); xt = get(gca,'XTick');
xlabel('syn   nonsyn        syn-rand    nonsyn-rand')


%% sfig 2c

a1= [100,0,0];  % cfin1 syn 
a2= [69,31,0];  % cfin2 syn
a3= [77,23,0];  % cfin1 nonsyn
a4= [96,0,4];   % cfin2 nonsyn
a5= [76,24,0];  % cfin1 syn+nonsyn
a6= [96,4,0];   % cfin2 syn+nonsyn

b1= [98,2,0];
b2= [19,81,0];
b3= [81,19,0];
b4= [99,0,1]; 
b5= [76,24,0];
b6= [75,25,0];

colors = [0.7,0.7,0.7; 0.65,0.9,0.56; 0.99,0.1,0.1];
f1=figure('Position', [100 100 800 600]);
h= bar([a1;a2;a3;a4;a5;a6], 'stacked');
for i = 1:numel(h)
    h(i).FaceColor = colors(i,:);
end
ylim([0,120]);
set(gcf,'color','w');
set(gca,'FontSize',22);
legend({'Obs = Rand', 'Obs < Rand', 'Obs > Rand'}, 'Location', 'north','Orientation', 'horizontal');
ylabel('#Trials');
xticks(1:6);
xticklabels({'CF-IN1 syn', 'CF-IN2 syn', 'CF-IN1 nonsyn', 'CF-IN2 nonsyn', 'CF-IN1 contact', 'CF-IN2 contact'})
title('Randomization of CF-IN positions')

f2=figure('Position', [100 100 800 600]);
h= bar([b1;b2;b3;b4;b5;b6], 'stacked');
for i = 1:numel(h)
    h(i).FaceColor = colors(i,:);
end
ylim([0,120]);
set(gcf,'color','w');
set(gca,'FontSize',22);
legend({'Obs = Rand', 'Obs < Rand', 'Obs > Rand'}, 'Location', 'north','Orientation', 'horizontal');
ylabel('#Trials');
xticks(1:6);
xticklabels({'CF-IN1 syn', 'CF-IN2 syn', 'CF-IN1 nonsyn', 'CF-IN2 nonsyn', 'CF-IN1 contact', 'CF-IN2 contact'})
title('Randomization of PF-IN positions')
