
%{
load('/data/research/cjpark147/conn_analysis/interneuron_complexity.mat');
load('/data/research/cjpark147/conn_analysis/cf_id.mat');
%load('/data/research/cjpark147/conn_analysis/pf_nott.mat');

in_id = list_of_target_interneurons;

dend_voxel_count = [646, 1002, 1347, 1302, 1412, 792, 718, 1015, 932, 863, 1222, 1449, 1236, 669, 639, 593, 830, 666, 788, 591, 363, 137, 86];
in_basket = [9,10,15,17, 23, 26, 28, 71, 74];
in_stellate = [19, 22, 24, 27, 30, 31, 35, 36, 37, 64, 68, 41, 46, 47];

syn_data_path = '/data/lrrtm3_wt_syn/synapse_det_info.txt';
syn_data = readtable(syn_data_path);
intf_id = syn_data.intf_id;
pre_post_amb = syn_data.pre_post_ambiguity;
seg_pre = syn_data.seg_pre;
seg_post = syn_data.seg_post;
type_pre = syn_data.type_pre;
type_post = syn_data.type_post;
intf_size = syn_data.size;
cx = syn_data.contact_x;
cy = syn_data.contact_y;
cz = syn_data.contact_z;

syn_counts = zeros(1,numel(in_id));
syn_info = [];

for i = 1:numel(in_id)
%for i = 1:1
    idx_syn = (ismember(seg_pre, cf_id)) & (seg_post == in_id(i));
%    idx_syn = strcmp(type_pre, 'in') & seg_post == 18 & cx >11100 & cy > 7000;
%    idx_syn = strcmp(type_pre, 'in') & strcmp(type_post, 'in') & cx > 11800 & cy > 8700 & cz > 300 & cz < 750;
%    idx_syn = ismember(seg_pre, in_id) & ismember(seg_post, in_id) & cx > 11000 & cy > 6700 & cz > 300 & cz < 750;
    
    syn_info = [syn_info; intf_id(idx_syn), pre_post_amb(idx_syn), seg_pre(idx_syn), ...
    seg_post(idx_syn), seg_pre(idx_syn), seg_post(idx_syn), intf_size(idx_syn), ...
    cx(idx_syn), cy(idx_syn), cz(idx_syn)];  
    syn_counts(i) = sum(idx_syn);
end

%write_syn_data_to_file('/data/lrrtm3_wt_syn/inin_syn.txt',syn_info);
%}


%% CF-IN synapse voting by 4 people
% score range 0~3: not syn(0), syn(3)
%{
a1 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score1.csv');
a2 = readtable('/data/lrrtm3_wt_syn/cfin_syn_score2.csv');
a2_data = sortrows([a2.intf_id, a2.person3, a2.person4],1);
score1 = a1.person1(ismember(a1.intf_id, a2_data(:,1)));
score2 = a1.person2(ismember(a1.intf_id, a2_data(:,1)));
score3 = a2_data(:,2);
score4 = a2_data(:,3);
score_sum = score1 + score2 + score3 + score4;
positive_idx = score_sum == 6;
cfin_syn_id_voted = a2_data(positive_idx,1);
cfin_syn_score = score_sum(positive_idx);

syn_data_path = '/data/lrrtm3_wt_syn/synapse_det_info_210503.txt';
syn_data = readtable(syn_data_path);
intf_id = syn_data.intf_id;
pre_post_amb = syn_data.pre_post_ambiguity;
seg_pre = syn_data.seg_pre;
seg_post = syn_data.seg_post;
type_pre = syn_data.type_pre;
type_post = syn_data.type_post;
intf_size = syn_data.size;
cx = syn_data.contact_x;
cy = syn_data.contact_y;
cz = syn_data.contact_z;

syn_info = [];
idx_syn = ismember(intf_id, cfin_syn_id_voted);
syn_info = [syn_info; intf_id(idx_syn), pre_post_amb(idx_syn), seg_pre(idx_syn), ...
    seg_post(idx_syn), seg_pre(idx_syn), seg_post(idx_syn), intf_size(idx_syn), ...
    cx(idx_syn), cy(idx_syn), cz(idx_syn)];  
%write_syn_data_to_file('/data/lrrtm3_wt_syn/cfin_syn_min6.txt',syn_info);

cfin_false = [47548; 6790; 95329; 115100; 121565; 162087; 286099; 309004; 510636; 556948; 613075; 621054; 722020; 743353];
%}

%% Number of CF-IN synapse vs distance from PCL

syn_data = readtable('/data/research/cjpark147/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
load('/data/research/cjpark147/conn_analysis/in_dist_from_pcl.mat');
load('/data/research/cjpark147/conn_analysis/IN_dend_total_length_um');

[gcount, gid] = groupcounts(syn_data.seg_post);
gcount = [gcount;0];
gid = [gid; 41];
d = zeros(numel(gid),1);  % dist from PCL
l = zeros(numel(gid),1);  % total dend length

for i = 1:numel(gid)
    idx = find(in_dist_from_pcl(:,1) == gid(i));
    d(i) = in_dist_from_pcl(idx,2);
    idx2 = find(IN_dend_total_length_um(:,1) == gid(i));
    l(i) = IN_dend_total_length_um(idx2,2);
end

density = gcount ./ l;

idx_in1 = find(ismember(gid, in1_ids));
idx_in2 = find(ismember(gid, in2_ids));

f1=figure('Position', [100 100 1000 800]);
scatter(d(idx_in1), gcount(idx_in1), 150, [240,70,70]/255, 'filled'); hold on;
scatter(d(idx_in2), gcount(idx_in2),  150, [60, 110, 200]/255, 'filled');
xlabel('IN-soma distance from PCL (microm)');
ylabel('Number of synapses from CF');
set(gca,'FontSize',20);
lsline;

f2=figure('Position',[500 500 1000 800]);
scatter(d(idx_in1), density(idx_in1), 150, [240,70,70]/255, 'filled'); hold on;
scatter(d(idx_in2), density(idx_in2),  150, [60, 110, 200]/255, 'filled');
title('normalized by available dendrite length');
xlabel('IN-soma distance from PCL (microm)');
ylabel('Density of synapses from CF (Num/DendLength)');
set(gca,'FontSize',20);
lsline;


%% Why does IN 41 have no CF synapse?
%{
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');

% (1) short dendrite length
%{
load('/data/research/cjpark147/conn_analysis/int_graph_dend.mat');
H = int_graph_dend;
in_w_cf_syn = [ 22,27,30,31,40];
in_wo_cf_syn = [41];
in2 = [in_w_cf_syn, in_wo_cf_syn];
total_dend_path = []; total_dend_path2 = [];
for i = 1:numel(in2_ids)
    if ismember(list_of_target_interneurons(i), in_w_cf_syn)
        G = H{i,1}.graph;
        total_dend_path = [total_dend_path; sum(G.Edges.Weight)];        
    elseif ismember(list_of_target_interneurons(i), in_wo_cf_syn)
        G = H{i,1}.graph;
        total_dend_path2 = [total_dend_path2; sum(G.Edges.Weight)];   
        
    end
end
%}
H = int_graph_dend;
in_w_cf_syn = [ 22,27,30,31,40];
in_wo_cf_syn = [41];
in2 = [in_w_cf_syn, in_wo_cf_syn];
total_dend_path = []; total_dend_path2 = [];
for i = 1:numel(in2_ids)
    if ismember(list_of_target_interneurons(i), in_w_cf_syn)
        G = H{i,1}.graph;
        total_dend_path = [total_dend_path; sum(G.Edges.Weight)];        
    elseif ismember(list_of_target_interneurons(i), in_wo_cf_syn)
        G = H{i,1}.graph;
        total_dend_path2 = [total_dend_path2; sum(G.Edges.Weight)];   
        
    end
end



% plot for IN2
figure;
x = categorical({'22', '27', '30', '31', '40', '41'});
y = [total_dend_path; total_dend_path2] * 0.048;    % 1 voxel = 0.048 um
b = bar(x,y, 'BarWidth', 0.4);
title('Total pathlength of IN2 dendrites');
ylabel('Pathlength (\mum)');
set(gcf,'color','w');
set(gca,'FontSize',13);
b.FaceColor = [56,62,86]/256;


% plot for IN1
total_dend_path3 = []; 
for i = 1:numel(in_id)
    if ~ismember(list_of_target_interneurons(i), in2)
        G = H{i,1}.graph;
        total_dend_path3 = [total_dend_path3; sum(G.Edges.Weight)];
    end
end

figure;
in1_id = in_id(~ismember(in_id,in2));
xlbl = strsplit(num2str(in1_id));
x = categorical(xlbl);
y = total_dend_path3 * 0.048;    % 1 voxel = 0.048 um
b = bar(x,y, 'BarWidth', 0.4);
title('Total pathlength of IN1 dendrites');
ylabel('Pathlength (\mum)');
set(gcf,'color','w');
set(gca,'FontSize',13);
b.FaceColor = [246,158,123]/256;
%}

%% number of contacts 
%{
addpath /data/lrrtm3_wt_code/matlab/segment_contact
contacts = omni_contact_coord('/data/research/iys0819/analysis_synapse_detection/volumes/seg_mip2_all_cells.20200313.axon_separation-rev.cb_cut.omni',3712,2560,256);
%contacts2 = omni_contact_coord('/data/lrrtm3_wt_reconstruction/segment_mip2_all_cells_200313.omni',3712,2560,256);
in_id = list_of_target_interneurons;
num_contact = zeros(numel(in_id),7);        % in id, #contacts with cf, #dendritic contacts, #cf in contact, # cf in contact with dend, #innervating cf, #syn        
%num_contact2 = zeros(numel(in_id),2);
id_dend = list_of_target_interneurons_dend_id_in_pruned_volume;
id_axon = list_of_target_interneurons_axon_id_in_pruned_volume;
id_soma = list_of_target_interneurons_cb_id_in_pruned_volume;

for i = 1:numel(in_id)
    this_id = in_id(i);
    inid_set = [id_dend(i),  id_axon(i),  id_soma(i)];   
    num_contact(i,1) = this_id;
    
    % #contact with cf 
    num_contact(i,2) = sum(ismember(contacts(1,:), inid_set) & ismember(contacts(2,:), cf_id*100));
    num_contact(i,2) = num_contact(i,2) + sum(ismember(contacts(1,:), cf_id*100) & ismember(contacts(2,:), inid_set));
    
    % #dend contact
    num_contact(i,3) = sum(ismember(contacts(1,:), id_dend(i)) & ismember(contacts(2,:), cf_id*100));
    num_contact(i,3) = num_contact(i,3) + sum(ismember(contacts(1,:), cf_id*100) & ismember(contacts(2,:), id_dend(i)));    

    % #cf in contact
    cfs = contacts(2, ismember(contacts(1,:), inid_set) & ismember(contacts(2,:), cf_id*100));
    cfs = [cfs, contacts(1, ismember(contacts(1,:), cf_id*100) & ismember(contacts(2,:), inid_set))];
    num_contact(i,4) = numel(unique(cfs));
    
    % # cf in contact with dend
    cfsd = contacts(2, ismember(contacts(1,:), id_dend(i)) & ismember(contacts(2,:), cf_id*100));
    cfsd = [cfsd, contacts(1, ismember(contacts(1,:), cf_id*100) & ismember(contacts(2,:), id_dend(i)))];
    num_contact(i,5) = numel(unique(cfsd));    
    
    % #innervating cf
    num_contact(i,6) = numel(unique(cfin_syn.seg_pre(cfin_syn.seg_post == in_id(i))));
    
    % #syn
    num_contact(i,7) = sum(cfin_syn.seg_post == in_id(i));
    
end

cfin_data = array2table(num_contact, 'VariableNames', {'IN ID','#contact w CF', '#contact dend w CF', '#CF in contact', '#CF in contact w dend', '#CF innervating', '#Synapse'});  

%}

%{ 
for i = 1:numel(in_id)
    this_id = in_id(i);
    inid_set = [id_dend(i),  id_axon(i),  id_soma(i)];   
    num_contact2(i,1) = this_id;
    num_contact2(i,2) = sum(ismember(contacts2(1,:), this_id) & ismember(contacts2(2,:), cf_id));
    num_contact2(i,2) = num_contact2(i,2) + sum(ismember(contacts2(1,:), cf_id) & ismember(contacts2(2,:), this_id)); 
end
%}



% PF-PC syn contact size distrib
%{
pfpc_syn_info = get_syn_info('pf','pc');
pfpc_syn_size = pfpc_syn_info(:,7);
histogram(pfpc_syn_size,50);
set(gcf,'color','w'); set(gca,'FontSize',20);
xlabel('PF-PC syn size (voxel)'); ylabel('count');
figure;
histogram(pfpc_syn_size(pfpc_syn_size > 40000),20,'FaceColor','r');
set(gcf,'color','w'); set(gca,'FontSize',16);
xlabel('PF-PC syn size (voxel)'); ylabel('count');
%}




%% number of interfaces

%{

load('/data/research/cjpark147/conn_analysis/cfin_contacts.mat');
load('/data/lrrtm3_wt_syn/interface/interface_relevant/mat_data/intf_bbox_2020nov.mat');
v_in_dendaxon = h5read('/data/research/cjpark147/conn_analysis/segment_mip2_all_cells.20200313.axon_separation-rev.cb_cut.h5','/main');
v_intf = h5read('/data/lrrtm3_wt_syn/assembly/assembly_interface_relevant.h5','/main');
vol_size = [14592,10240,1024];
interface_in_id = unique(cfin_contacts(:,2));
num_interface = zeros(numel(interface_in_id,3));
for i = 1:numel(interface_in_id)
    this_id = interface_in_id(i);
    this_idx = cfin_contacts(:,2) == this_id;
    num_interface(i,1) = this_id;
    num_interface(i,2) = sum(this_idx);
    num_interface(i,3) = numel(unique(cfin_contacts(this_idx,3)));
end

cfin.in_id = num_interface(:,1);         % post IN id
cfin.num_interface = num_interface(:,2);   % number of interfaces with cf
cfin.num_cf_touch = num_interface(:,3);  % number of cf in contact
%}


%{
for i = 1:numel(interface_in_id)
    this_id = interface_in_id(i);
    intf_id = cfin_contacts(cfin_contacts(:,2) == this_id, 1);
    for j = 1:numel(intf_id)
        v = h5read('/data/lrrtm3_wt_syn/assembly/assembly_interface_relevant_raw.h5','/main');
  %}      





%% Total number of CF-IN interfaces 

%{
addpath /data/research/cjpark147/code/matlab/mysql/

vol_size = [14592, 10240, 1024];
intf_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_fixed.h5';
seg_path = '/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_200313.h5';
%load('/data/lrrtm3_wt_syn/interface_relevant_info.mat');
load('/data/lrrtm3_wt_syn/mat_data/bbox_fixed2');

celltype_map = cell(7,1);
celltype_map{1} = 'pc';
celltype_map{2} = 'pf';
celltype_map{3} = 'cf';
celltype_map{4} = 'in';
celltype_map{5} = 'gl';
celltype_map{6} = 'go';
celltype_map{7} = 'ud';

load_limit = 512*512*128;
thickness = 2;              % interface thickness
intf_size_th = 200;         % interface size threshold
z_scaling = 4;
vc_dist= 5;

%[row,~] = size(interface_info);

intf_ids = find(bbox_fixed2(:,1));
bbox_load = bbox_fixed2(:,4) .* bbox_fixed2(:,5) .* bbox_fixed2(:,6);
intf_ids_beyond_limit = find(bbox_load > load_limit);
intf_ids_within_limit = find(bbox_load <= load_limit & bbox_load > 0);

[row,~] = size(intf_ids);
seg_id_info = zeros(row,2);
cell_type_info = zeros(row,2);
intf_size_info = zeros(row,1);
bbox_info = zeros(row,6);
intf_id_info = zeros(row,1);

parfor ridx=1:numel(intf_ids_within_limit)
 
    stp = max([1,1,1], [bbox_fixed2(intf_ids_within_limit(ridx),1:2) - vc_dist,  bbox_fixed2(intf_ids_within_limit(ridx),3) - ceil(vc_dist/z_scaling) ]);   % bbox x,y,z
    enp = min(vol_size, stp - [1,1,1] + [bbox_fixed2(intf_ids_within_limit(ridx),4:5) + vc_dist *2, bbox_fixed2(intf_ids_within_limit(ridx),6) + ceil(vc_dist/z_scaling)*2]);
    num_elem = enp - stp + 1;
    intf_vol = h5read(intf_path, '/main', stp, num_elem);
    cells_segment_vol = h5read(seg_path, '/main', stp, num_elem);
    intf_idx = find(intf_vol == intf_ids_within_limit(ridx));
    intf_size = numel(intf_idx);
    intf_size_info(ridx,1) = intf_size;
    intf_id_info(ridx,1) = intf_ids_within_limit(ridx);
    
    if (intf_size > intf_size_th)
        bbox_info(ridx,:) = [stp, num_elem];
        
        % match vesicle segments.   cell types { 1-PC, 2-PF, 3-CF, 4-IN, 5-GLI, 6-GOL}
        h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
        rtn = mysql(h_sql, 'use omni_20200313');
        
        bw = (intf_vol == intf_ids_within_limit(ridx));
        se = strel('sphere',1);
        di = imdilate(bw,se);
        su = di~=bw;
        su_id = cells_segment_vol(su);
        su_id(su_id == 0) = [];
        
        seg_id1 = mode(su_id, 'all');   % the most frequent seg id
        su_id(su_id == seg_id1) = [];
        seg_id2 = mode(su_id, 'all');   % second most frequent id
        
        query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id1);
        cell_type1 = mysql(h_sql, query);
        query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id2);
        cell_type2 = mysql(h_sql, query);
        
        mysql(h_sql, 'close');
        
        seg_id_info(ridx, :) = [seg_id1, seg_id2];
        cell_type_info(ridx, :) = [cell_type1, cell_type2];
    end
end
    fprintf('1st part done. \n');

intf_info_tbl = [intf_id_info, seg_id_info, cell_type_info, intf_size_info, bbox_info];
save('/data/lrrtm3_wt_syn/intf_info_tbl.mat', 'intf_info_tbl');


n_classified = numel(intf_ids_within_limit);
for ridx=1:numel(intf_ids_beyond_limit)

    ridx2 = ridx + n_classified;
    stp = max([1,1,1], [bbox_fixed2(intf_ids_beyond_limit(ridx),1:2) - vc_dist,  bbox_fixed2(intf_ids_beyond_limit(ridx),3) - ceil(vc_dist/z_scaling) ]);   % bbox x,y,z
    enp = min(vol_size, stp - [1,1,1] + [bbox_fixed2(intf_ids_beyond_limit(ridx),4:5) + vc_dist *2, bbox_fixed2(intf_ids_beyond_limit(ridx),6) + ceil(vc_dist/z_scaling)*2]);
    num_elem = enp - stp + 1;
    intf_vol = h5read(intf_path, '/main', stp, num_elem);
    cells_segment_vol = h5read(seg_path, '/main', stp, num_elem);
    
    intf_idx = find(intf_vol == intf_ids_beyond_limit(ridx));
    intf_size = numel(intf_idx);
    intf_size_info(ridx2,1) = intf_size;
    intf_id_info(ridx2,1) = intf_ids_beyond_limit(ridx);
    
    
    bbox_info(ridx2,:) = [stp, num_elem];    
    
    h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
    rtn = mysql(h_sql, 'use omni_20200313');
    
    bw = (intf_vol == intf_ids_beyond_limit(ridx));
    se = strel('sphere',1);
    di = imdilate(bw,se);
    su = di~=bw;
    clear bw di;
    su_id = cells_segment_vol(su);
    su_id(su_id == 0) = [];
    clear cells_segment_vol;
    
    seg_id1 = mode(su_id, 'all');   % the most frequent seg id
    su_id(su_id == seg_id1) = [];
    seg_id2 = mode(su_id, 'all');   % second most frequent id
    
    query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id1);
    cell_type1 = mysql(h_sql, query);
    query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id2);
    cell_type2 = mysql(h_sql, query);
    mysql(h_sql, 'close');
    
    
    seg_id_info(ridx2, :) = [seg_id1, seg_id2];
    cell_type_info(ridx2, :) = [cell_type1, cell_type2];
 
end    
intf_info_tbl = [intf_id_info, seg_id_info, cell_type_info, intf_size_info, bbox_info];
save('/data/lrrtm3_wt_syn/intf_info_tbl.mat', 'intf_info_tbl');

fprintf('all done. \n');

%}

%{
figure;
scatter(int_dend_complexity, syn_counts ./ int_dend_skeleton_length, 'filled');
title('(# PF syn / dend skeleton length) vs. dendrite complexity', 'FontSize', 13);
xlabel('dend complexity', 'FontSize', 12);
ylabel('# PF syn / dend skeleton length', 'FontSize', 12);
for i = 1:numel(in_id)
    text( int_dend_complexity(i), syn_counts(i) / int_dend_skeleton_length(i), cellstr(['  ',num2str(in_id(i))]));
end
%}
    
    
%{
figure;
h=scatter(int_dend_skeleton_length, syn_counts, 'filled');
%gscatter(int_dend_skeleton_length, syn_counts, group, 'br');
title('# CF syn vs. IN dend skeleton length', 'FontSize', 13);
xlabel('dend skeleton length');
ylabel('# CF syn');
for i = 1:numel(in_id)
    text( int_dend_skeleton_length(i), syn_counts(i), cellstr(['  ',num2str(in_id(i))]));
end
h1 = lsline;
h1.LineWidth = 2;
corr_coef = corrcoef(int_dend_skeleton_length, syn_counts);
%lin_reg = fitlm(int_dend_skeleton_length, syn_counts);
legend(h, {['R=', num2str(corr_coef(1,2))]}, 'FontSize', 12);
%}



%% Putataive synapse list for Szi-cheih

%{
center_points = [...
5420,10062,317,390; 
6385,9742,818,687; 
13189,9118,1875,602; 
28705,9671,3465,330;
38863,10116,4669,297;
40910,9405,4622,565;
47548,9239,5557,432;
96427,10717,3447,569;
96511,10365,2936,545;
96511,10590,2561,552;
108331,11004,4859,322;
108377,10319,4573,311;
115100,10888,5443,311;
126884,10713,7168,452;
148992,11812,2399,538;
150314,11966,2716,618;
150317,12061,2753,596;
200848,13005,2315,655;
206534,12100,3139,613;
296845,1287,3234,581;
302844,1344,4424,568;
324639,1228,7851,621;
330169,1645,8160,629;
332126,3001,9750,231;
332127,2685,9061,264;
341140,3304,1389,366;
425681,3475,2056,470;
437369,3389,2048,705;
446072,3788,3736,430;
448895,3833,3744,557;
460244,3943,4393,553;
491183,3614,7670,295;
508996,4321,9480,258;
515513,4308,1062,186;
556948,5120,4174,732; 
613075,5199,908,520;
621054,5084,1430,565;
709443,6613,1741,220; 
711864,6782,1453,364;
722020,6136,2164,419;
737371,6615,3725,875;
746298,6784,4924,799;
795604,7282,494,391;
795605,7594,955,402;
820539,7609,3364,411;
842456,7595,5588,550;
859161,7404,7108,434;
874373,8734,9075,216;
879529,8617,979,403;
879530,8658,992,409;
887172,8184,1857,753;
896190,8700,2570,770;
];

%}
