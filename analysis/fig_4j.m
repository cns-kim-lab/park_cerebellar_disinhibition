
load('fig3j_3l_data.mat');

data1 = [ncfin_nonsyn_per_in1 ncfin_syn_per_in1];
data2 = [ncfin_nonsyn_per_in2 ncfin_syn_per_in2];

f=figure('Position',[100,100,750,600]);
h=bar([data1; data2], 'stacked');
bar_colors = [0,0.1,0.5; 0.95,0.67,0.05];
for i = 1:length(h)
    h(i).FaceColor = bar_colors(i,:);
end
legend(h, 'Apposition', 'Synapse','Location','north');
ylabel('#Contacts with CF');
xlabel('1-20: IN1, 21-26: IN2')
set(gcf,'color','w');
set(gca,'FontSize',20);



%% Save figure
save_figure(f,'fig_3j','svg');