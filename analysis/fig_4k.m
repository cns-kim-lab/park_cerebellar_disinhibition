load('fig3j_3l_data.mat');
f=figure('Position',[100,100,400,600]);
color_in1 = [250,50,50]/255;
color_in2 = [50,110,180]/255;
violin_data = [];
violin_data = [violin_data; repmat(1, numel(npf_syn_per_in1), 1), npf_syn_per_in1];
violin_data = [violin_data; repmat(2, numel(npf_syn_per_in2), 1), npf_syn_per_in2];
vp = violinplot(violin_data(:,2), round(violin_data(:,1)));
vp(1).ViolinColor = color_in1;
vp(2).ViolinColor = color_in2;
for i = 1:2
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.7;
    vp(i).ScatterPlot.SizeData = 70;
    vp(i).BoxWidth = 0.04;
end  
ylabel('#PF-IN synapses');
ax=gca;
ax.XTickLabel ={'IN1' , 'IN2'};
set(gcf,'color','w');
set(gca,'FontSize',20);
[p0,~,~] = ranksum(npf_syn_per_in1, npf_syn_per_in2);

%% Save figure
%save_figure(f,'fig_3l','svg');