
%% EM images for CF-IN synapse examples 

%{
%syn_id_select = [28705;126884;302844;330169;425681;556948;795604;879529;896190]; % score=8
%syn_id_select = [28705;302844;425681;795604;896190]; % score=8, 3people
syn_id_select = [28705;96427;126884;302844;330169;425681;556948;795604;879529;896190]; %score = 11, 4 people
syn_table = readtable('/data/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');
seg_pre_id = syn_table.seg_pre;
seg_post_id = syn_table.seg_post;
[num_syn,~] = size(syn_id_select);
ws = 100;

for i = 1:num_syn
    idx = syn_table.intf_id == syn_id_select(i);
    xc = syn_table.contact_x(idx);   yc = syn_table.contact_y(idx);    zc = syn_table.contact_z(idx);
    xc1 = max(xc - ws + 1, 1);  xc2 = min(xc + ws, 14592);
    yc1 = max(yc - ws + 1, 1);  yc2 = min(yc + ws, 10240);
    zc1 = max(zc - 3, 1);   zc2 = min(zc + 3, 1024); 
    chan = h5read('/data/lrrtm3_wt_reconstruction/channel.h5', '/main', [xc1,yc1,zc1], [xc2-xc1+1, yc2-yc1+1, zc2-zc1+1]);     
    chan = permute(chan, [2,1,3]);

    for j = 1:7
        chan_gray = repmat(mat2gray(chan(:, :, j),[0,255]),[1,1,3]) * 1.05;
        imwrite(chan_gray, ['/data/research/cjpark147/figure/paper02/02/cfin_', num2str(syn_id_select(i,1)),'_',num2str(j), '.tif']);
    end
end        
%}

%{
for i = 1:num_syn    
    idx = syn_table.intf_id == syn_id_select(i);
    xc = syn_table.contact_x(idx);   yc = syn_table.contact_y(idx);    zc = syn_table.contact_z(idx);
    xc1 = max(xc - ws + 1, 1);  xc2 = min(xc + ws, 14592);
    yc1 = max(yc - ws + 1, 1);  yc2 = min(yc + ws, 10240);
    zc1 = max(zc - 2, 1);   zc2 = min(zc + 3, 1024); 
    chan = h5read('/data/lrrtm3_wt_reconstruction/channel.h5', '/main', [xc1,yc1,zc1], [xc2-xc1+1, yc2-yc1+1, zc2-zc1+1]);     
    chan = permute(chan, [2,1,3]);
    f=figure('Position',[100 500 1200 700]);
    tiledlayout(2,3, 'TileSpacing','compact');
    for j = 1:6           
        chan_gray = repmat(mat2gray(chan(:, :, j),[0,255]),[1,1,3]) * 1.05;
        nexttile
        title(num2str(j));
        imshow(chan_gray);
        imwrite(chan_gray, ['/data/research/cjpark147/figure/paper02/02/cfin_', num2str(syn_id_select(i,1)),'_',num2str(j), '.tif']);
    end
    %save_figure(f,['cfin_syn_',num2str(i)],'png');
end        
%}

%% CF-IN adjacency matrix heatmap 

% cf-pc pairs
% 463-18
% 227-11
% 453-21
% {7,166}-4
% 772-20
% {465,873}-81 (z-cut)
% 878-49 
% 681-13
% 861-82  (z-cut)
% 931-50
% 913-78  (z-cut)
% 953-175
% 932-739 

%{
% total score
f2e=figure('Position',[300 800 1000 400]);
%cf_ids = [463;227;453;7;772;878;681;931;953;932];
cf_ids = [463;227;7;681;453;772;878;931;166;953];
a1 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score1.csv');
a2 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score2.csv');
a2_data = sortrows([a2.intf_id, a2.person3, a2.person4],1);
score1 = a1.person1(ismember(a1.intf_id, a2_data(:,1)));
score2 = a1.person2(ismember(a1.intf_id, a2_data(:,1)));
score3 = a2_data(:,2);
score4 = a2_data(:,3);
%score_sum = score3;
score_sum = score1 + score2 + score3 + score4;
%cfin_syn_score = score_sum(positive_idx);

syn_data = readtable('/data/lrrtm3_wt_syn/synapse_det_info_210503.txt');
idx = ismember(syn_data.intf_id, a2_data(:,1));
putative_intf_ids = syn_data.intf_id(idx);
seg_post_ids = syn_data.seg_post(idx);
seg_pre_ids = syn_data.seg_pre(idx);
adjmat_cfin_score = zeros(numel(cf_ids), numel(in_ids));
for i = 1:numel(cf_ids)
    for j = 1:numel(in_ids)
        idx = ismember(seg_pre_ids, cf_ids(i)) & ismember(seg_post_ids, in_ids(j));
        this_intf_ids = putative_intf_ids(idx);
        adjmat_cfin_score(i,j) = sum(score_sum(ismember(a2_data(:,1), this_intf_ids)));
        %adjmat_cfin_score(i,j) = sum(score_sum(ismember(a2_data(:,1), this_intf_ids)))/numel(this_intf_ids);  % mean score
    end
end
imagesc(1:(nin1+nin2), 1:numel(cf_ids),adjmat_cfin_score); 
max_weight = max(adjmat_cfin_score,[],'all')+1;
%cmap_adjmat = [linspace(0.25,0.96,max_weight)', linspace(0.19,0.65,max_weight)', linspace(0.26,0.04,max_weight)'];
%cmap_adjmat = [linspace(0.9,0.1,max_weight)', linspace(0.76,0.18,max_weight)', linspace(0.73,0.38,max_weight)'];
%cmap_adjmat = [linspace(0.7,1,max_weight)', linspace(0.83,0.3,max_weight)', linspace(0.63,0.3,max_weight)'];
%cmap_adjmat = [linspace(28/255,255/255,max_weight)', linspace(109/255,210/255,max_weight)', linspace(208/255,240/255,max_weight)'];
cmap_adjmat = [linspace(255/255,255/255,max_weight)', linspace(255/255,150/255,max_weight)', linspace(255/255,25/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1]);
xlabel('IN','FontSize',30); ylabel('CF','FontSize',30);
%}

%{
% thresholded matrix
f2e2=figure('Position',[300 800 1000 400]);
%cf_ids = [227;463;453;681;7;772;878];  % CF 861, 465, 913, 873 are removed since they locate at the boundaries. 
%cf_ids = [227;463;453;7;772;878;681];  % CF associated with target PC
%{
syn_table = readtable('/data/lrrtm3_wt_syn/cfin_syn_info_220224.txt');
seg_pre_id = syn_table.seg_pre;
seg_post_id = syn_table.seg_post;
%}
cf_ids = [463;227;7;681;453;772;878;931;166;953];
%cf_ids = [463;227;453;7;772;878;681;931;953;932]; % sorted by size
a1 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score1.csv');
a2 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score2.csv');
a2_data = sortrows([a2.intf_id, a2.person3, a2.person4],1);
score1 = a1.person1(ismember(a1.intf_id, a2_data(:,1)));
score2 = a1.person2(ismember(a1.intf_id, a2_data(:,1)));
score3 = a2_data(:,2);
score4 = a2_data(:,3);
score_sum = score1 + score2 + score3 + score4;
positive_idx = score_sum >5;
cfin_syn_id_voted = a2_data(positive_idx,1);
idx = ismember(syn_data.intf_id, cfin_syn_id_voted);
voted_intf_ids = syn_data.intf_id(idx);
seg_post_ids = syn_data.seg_post(idx);
seg_pre_ids = syn_data.seg_pre(idx);
adjmat_cfin = zeros(numel(cf_ids), numel(in_ids));
nrow = numel(cf_ids); ncol = numel(in_ids);
for i = 1:nrow
    for j =1:ncol
        idx = ismember(seg_pre_ids, cf_ids(i)) & ismember(seg_post_ids, in_ids(j));
        adjmat_cfin(i,j) = sum(idx);
    end
end
imagesc(1:(nin1+nin2), 1:numel(cf_ids),log(adjmat_cfin+1)); 
max_weight = max(adjmat_cfin,[],'all')+1;
cmap_adjmat = [linspace(0.25,0.96,max_weight)', linspace(0.19,0.65,max_weight)', linspace(0.26,0.04,max_weight)'];
cmap_adjmat = [linspace(255/255,255/255,max_weight)', linspace(255/255,150/255,max_weight)', linspace(255/255,25/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1]);
xlabel('IN','FontSize',30); ylabel('CF','FontSize',30);
%}
