
%% IN1 vs IN2 ratio including axon fragments 

load('/data/research/cjpark147/conn_analysis/in_frag_dend.mat');  % data from "get_axon_dend_fragments_of_in.m"
load('/data/research/cjpark147/conn_analysis/in_frag_axon.mat');

syn_info_axon_to_IN = get_syn_info(in_frag_axon, 'in');
syn_info_axon_to_PC = get_syn_info(in_frag_axon, 'pc');

tpi = zeros(numel(in_frag_axon),3);
for i = 1:numel(in_frag_axon)
    n1 = sum(syn_info_axon_to_IN(:,3) == in_frag_axon(i));
    n2 = sum(syn_info_axon_to_PC(:,3) == in_frag_axon(i));
    tpi(i,1) = in_frag_axon(i);
    tpi(i,2) = (n1 - n2) / (n1 + n2);
    if n1+n2 > 30
        tpi(i,3) = 1;
    end
end

syn_info_to_IN = get_syn_info(in_ids, 'in');
syn_info_to_PC = get_syn_info(in_ids, 'pc');
tpi2 = zeros(numel(in_ids),1);
for i = 1:numel(in_ids)
    n1 = sum(syn_info_to_IN(:,3) == in_ids(i));
    n2 = sum(syn_info_to_PC(:,3) == in_ids(i));
    tpi2(i) = (n1 - n2) / (n1 + n2);
end

f1=figure('Position',[300 500, 500 400]);
bins = -1.15:0.1:1.15;
idx_valid = tpi(:,3) == 1;
tpi_all = [tpi(idx_valid,2); tpi2];
[n,e] = histcounts(tpi_all, bins);
bin_mid = bins(2:end)-(bins(2)-bins(1))/2;
plot(bin_mid,n, 'LineWidth',2, 'Color',[190,90,190]/255);
set(gcf,'color','w'); set(gca,'FontSize',17);
ylabel('Number of cell fragments'); xlabel('TPI'); xline(0,'--','LineWidth',2);

f2=figure('Position',[900 500, 500 400]);
pie_data = [129,34];
labels = {'IN1','IN2'};
h=pie(pie_data);
lgd=legend(labels,'Location','south','Orientation','horizontal');
set(gcf,'color','w'); set(gca,'FontSize',17);
patchHand = findobj(h, 'Type','Patch');
patchHand(1).FaceColor = [250,75,75]/255;
patchHand(2).FaceColor = [60,105,240]/255;
%}  