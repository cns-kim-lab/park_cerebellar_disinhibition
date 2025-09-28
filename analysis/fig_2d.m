%% This is a simplified code for figure using pre-computed data.
% See the sections at the end of this script for the data computation script.

% load pre-computed data and draw the figure
load('./mat/fig2d_3k_data.mat')

f = figure('Position',[100 100 800 800]);
violin_data = [];
violin_data = [violin_data; repmat(1, numel(contact_size_per_true_pos), 1), contact_size_per_true_pos];
violin_data = [violin_data; repmat(2, numel(contact_size_per_false_pos), 1), contact_size_per_false_pos];
vp = violinplot(violin_data(:,2), round(violin_data(:,1)), 'ViolinColor', [240,140,30]/255);
for i = 1:2
    vp(i).ScatterPlot.MarkerFaceAlpha = 0.8;
    vp(i).ScatterPlot.SizeData = 55;
    vp(i).BoxWidth = 0.04;
end  
vp(2).ViolinColor = [40,50,120]/255;
set(gcf,'color','w');
ax=gca;
ax.XTickLabel ={'Syn' , 'App'};
ylabel('CF-IN Contact Area (\mum^2)');
set(gca,'FontSize',20);hold on;
yt=get(gca,'YTick'); xt = get(gca,'XTick'); 
plot(xt([1 2]), [1 1]*max(yt)*1, '-k', 'LineWidth',1.5);
text(mean([1 2])*0.95, max(yt)*1.05, '***', 'FontSize',24);


% normality test
[h1,p1] = kstest((contact_size_per_true_pos - mean(contact_size_per_true_pos))/std(contact_size_per_true_pos));
[h2,p2] = kstest((contact_size_per_false_pos - mean(contact_size_per_false_pos))/std(contact_size_per_false_pos));
disp(['kstest p-val=',num2str(p1)])
disp(['kstest p-val=',num2str(p2)])

% since N>30 do t-test
[h3,p3] = ttest2(contact_size_per_true_pos,contact_size_per_false_pos);
disp(['t-test p-val=',num2str(p3)])

[p4,~,~] = ranksum(contact_size_per_true_pos, contact_size_per_false_pos);
disp(['p-val=',num2str(p4)])





%% Script for the data computations
% Requires 600GB .h5 file of contacts volume stored locally

%{
cf_ids = [463;227;7;681;453;772;878;931;166;953];
load('./mat/in1_ids.mat');
load('./mat/in2_ids.mat');
load('./mat/cfin_contacts_info.mat')
in_ids = [in1_ids;in2_ids];

cfin_syn_data = readtable('/Users/changjoopark/volume_3/research/cjpark147/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');
aa = get_syn_info(cf_ids,in_ids);
cfin_id_ai_positive = aa(:,1);

cfin_ai_positive = cfin_contacts(ismember(cfin_contacts.intf_id,cfin_id_ai_positive),:);
cfin_ai_negative = cfin_contacts(~ismember(cfin_contacts.intf_id,cfin_id_ai_positive),:);
cfin_true_positive = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_syn_data.intf_id),:);
cfin_false_positive = cfin_ai_positive(~ismember(cfin_ai_positive.intf_id, cfin_syn_data.intf_id),:);

intf_vol_path = '/Users/changjoopark/kimlab_disk2/volume_3/research/cjpark147/lrrtm3_wt_syn/assembly/interface_relevant_fixed_210503.h5';

% Get Contact Size
start = [cfin_ai_positive.stp_x, cfin_ai_positive.stp_y, cfin_ai_positive.stp_z];
stride = [cfin_ai_positive.stride_x,cfin_ai_positive.stride_y,cfin_ai_positive.stride_z];
intf_area = zeros(length(start),5);
for i = 1:length(start)
    if start(i,1) ~= 0
        vi = h5read(intf_vol_path,'/main', start(i,:), stride(i,:));
        bw = vi == cfin_ai_positive.intf_id(i);
        sz = size(bw);
        bw_padded = padarray(bw, [1,1,1],0);
        dx = diff(bw_padded, 1,2);
        dy = diff(bw_padded, 1,1);
        dz = diff(bw_padded, 1,3);
        faces_x = sum(abs(dx(:))==1);
        faces_y = sum(abs(dy(:))==1);
        faces_z = sum(abs(dz(:))==1);
        this_area = (faces_x + faces_y)/2 * 0.05*0.012*(51/62) + faces_z/2 * 0.012*0.012*(17/24);

        proj_xy = any(bw,3);
        proj_yz = squeeze(any(bw,2));
        proj_xz = squeeze(any(bw,1));
        count_xy = sum(proj_xy(:));
        count_yz = sum(proj_yz(:));
        count_xz = sum(proj_xz(:));
        this_area2 = count_xy*0.012*0.012*(17/24) + count_yz*0.05*0.012*(51/62) + count_xz*0.05*0.012*(51/62);
        
        intf_area(i,1:5) = [cfin_ai_positive.seg_id1(i), cfin_ai_positive.seg_id2(i), cfin_ai_positive.size(i),this_area,this_area2];           
    end
    disp(i)
end

cfin_ai_positive.area1 = intf_area(:,4);
contact_size_per_in1 = [];
contact_size_per_in2 = [];
contact_meansize_per_in1 = [];
contact_meansize_per_in2 = [];

in1_ids_select = in1_ids;
for i = 1:numel(in1_ids_select)
    rows = cfin_ai_positive(ismember(cfin_ai_positive.seg_id1,cf_ids) & ismember(cfin_ai_positive.seg_id2,in1_ids_select(i)), :);
    rows(rows.area1 > 35,:) = [];
    contact_size_per_in1 = [contact_size_per_in1; rows.area1];
    contact_meansize_per_in1 = [contact_meansize_per_in1; mean(rows.area1)];
end
for i = 1:numel(in2_ids)
    rows = cfin_ai_positive(ismember(cfin_ai_positive.seg_id1,cf_ids) & ismember(cfin_ai_positive.seg_id2,in2_ids(i)), :);
    rows(rows.area1 > 35,:) = [];
    contact_size_per_in2 = [contact_size_per_in2; rows.area1];   
    contact_meansize_per_in2 = [contact_meansize_per_in2; mean(rows.area1)];
end

rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_true_positive.intf_id),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_true_pos = rows.area1;
rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_false_positive.intf_id),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_false_pos = rows.area1;
rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_true_positive.intf_id) & ismember(cfin_ai_positive.seg_id2,in1_ids_select),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_true_pos_in1 = rows.area1;
rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_true_positive.intf_id) & ismember(cfin_ai_positive.seg_id2,in2_ids),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_true_pos_in2 = rows.area1;
rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_false_positive.intf_id) & ismember(cfin_ai_positive.seg_id2,in1_ids_select),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_false_pos_in1 = rows.area1;
rows = cfin_ai_positive(ismember(cfin_ai_positive.intf_id, cfin_false_positive.intf_id) & ismember(cfin_ai_positive.seg_id2,in2_ids),:);
rows(rows.area1 > 35,:) = [];
contact_size_per_false_pos_in2 = rows.area1;
%}