load('./mat/fig2d_3k_data.mat')

f5v2 = figure('Position',[100 100 800 800]);
color_in1 = [250,50,50]/255;
color_in2 = [50,110,180]/255;
violin_data = [];
violin_data = [violin_data; repmat(1, numel(contact_size_per_true_pos_in1), 1), contact_size_per_true_pos_in1];
violin_data = [violin_data; repmat(1, numel(contact_size_per_false_pos_in1), 1), contact_size_per_false_pos_in1];
violin_data = [violin_data; repmat(2, numel(contact_size_per_true_pos_in2), 1), contact_size_per_true_pos_in2];
violin_data = [violin_data; repmat(2, numel(contact_size_per_false_pos_in2), 1), contact_size_per_false_pos_in2];
vp = violinplot(violin_data(:,2), round(violin_data(:,1)), 'ViolinColor', color_in1);
for i = 1:2
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.8;
    vp(i).ScatterPlot.SizeData = 55;
    vp(i).BoxWidth = 0.04;
end  
vp(2).ViolinColor = color_in2;
set(gcf,'color','w');
ax=gca;
ax.XTickLabel ={'IN1' , 'IN2'};
ylabel('CF-IN Contact Area (\mum^2)');
set(gca,'FontSize',20);hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); %ylim([min(yt),max(yt)*1.15]);
plot(xt([1 2]), [1 1]*max(yt)*1, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.05, '***', 'FontSize',24);

% normality test
counts1 = [contact_size_per_true_pos_in1; contact_size_per_false_pos_in1];
counts2 = [contact_size_per_true_pos_in2; contact_size_per_false_pos_in2];
[h1,pn1] = kstest((counts1 - mean(counts1))/std(counts1));
[h2,pn2] = kstest((counts2 - mean(counts2))/std(counts2));
disp(['kstest p-val=',num2str(pn1)])
disp(['kstest p-val=',num2str(pn2)])

% since N>30 do t-test
[h3,p3] = ttest2(counts1,counts2);
disp(['t-test p-val=',num2str(p3)])

[p5,~,~] = ranksum([contact_size_per_true_pos_in1; contact_size_per_false_pos_in1],[contact_size_per_true_pos_in2; contact_size_per_false_pos_in2]);
disp(['p-val=',num2str(p5)]);


%% Save figure
save_figure(f,'fig_3k','svg');