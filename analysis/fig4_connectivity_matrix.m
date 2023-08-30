
%load('/data/lrrtm3_wt_syn/mat_data/interface_relevant_info.mat');
load('/data/research/cjpark147/conn_analysis/in1_ids.mat');
load('/data/research/cjpark147/conn_analysis/in2_ids.mat');
%load('/data/lrrtm3_wt_syn/interface/interface_relevant/mat_data/intf_bbox_2020nov.mat');
load('/data/research/cjpark147/conn_analysis/data_for_interneuron_complexity_measure.iso_mip2.mat');
%id_in = [in1_ids; in2_ids];

load('/data/research/cjpark147/conn_analysis/target_interneurons_new.mat');
load('/data/research/cjpark147/conn_analysis/in_soma_pcl_dist.mat');

mli2 = [22,27,30,31,40,41];
mli1 = setdiff(target_interneurons_new, mli2);
mli1 = mli1(randperm(numel(mli1)));
omit_in = [19]; % doesn't have axon
id_in = [mli1,mli2]';
id_in(ismember(id_in, omit_in)) = [];

%{
addpath /data/lrrtm3_wt_code/matlab/segment_contact
%contacts = omni_contact_coord('/data/research/iys0819/analysis_synapse_detection/volumes/seg_mip2_all_cells.20200313.axon_separation-rev.cb_cut.omni',3712,2560,256);
%contacts2 = omni_contact_coord('/data/lrrtm3_wt_reconstruction/segment_mip2_all_cells_200313.omni',3712,2560,256);
adj_mat_dend_contact = zeros(numel(id_in));   
adj_mat_all_contact = zeros(numel(id_in));        


% group IN1 and IN2
id_dend_unsorted = list_of_target_interneurons_dend_id_in_pruned_volume;
id_axon_unsorted = list_of_target_interneurons_axon_id_in_pruned_volume;
id_soma_unsorted = list_of_target_interneurons_cb_id_in_pruned_volume;
id_dend = zeros(1,numel(id_in)); id_axon = id_dend; id_soma = id_dend;
for i = 1:numel(id_in)
    idx = find(list_of_target_interneurons == id_in(i));
    id_dend(i) = id_dend_unsorted(idx);
    id_axon(i) = id_axon_unsorted(idx);
    id_soma(i) = id_soma_unsorted(idx);
end
%}

%% {CF, IN1, IN2} to {PC, IN1, IN2} adjacency matrix

load('/data/research/cjpark147/conn_analysis/adjmat_cfin_min6.mat');
target_pc_ids = [18;11;21;4;20;49;13;50;175;739];
pc_ids = [18;11;4;13;21;20;49;50;3;175];
cf_ids = [463;227;7;681;453;772;878;931;166;953];
%id_pc = good_pc_ids(1:end-2);
%id_pc = id_pc(randperm(numel(id_pc)));
inin_syninfo = get_syn_info(id_in,id_in);
inpc_syninfo = get_syn_info(id_in,pc_ids);
cfpc_syninfo = get_syn_info(cf_ids, pc_ids);
all_syninfo = [inin_syninfo; inpc_syninfo];
id_pre = [cf_ids; id_in];
id_post = [pc_ids;  id_in];
nrow = numel(id_pre); ncol = numel(id_post);
adjmat_syn_directed = zeros(nrow, ncol);
%adj_mat_syn_directed(1:numel(cf_ids), numel(pc_ids)+1:end) = adjmat_cfin;

cfin_info = readtable('/data/research/cjpark147/lrrtm3_wt_syn/cfin_syn_min6.txt');
for i = 1:numel(cf_ids)
    for j = 1:numel(pc_ids)
        adjmat_syn_directed(i,j)=sum(ismember(cfpc_syninfo(:,3:4), [cf_ids(i), pc_ids(j)], 'rows'));
    end            
    
    for j = numel(pc_ids)+1:ncol
        adjmat_syn_directed(i,j)=sum(ismember(cfin_info.seg_pre, cf_ids(i)) & ismember(cfin_info.seg_post, id_in(j-numel(pc_ids))));
    end
end

for i = numel(cf_ids)+1:nrow
    for j = 1:ncol
        adjmat_syn_directed(i,j)=sum(ismember(all_syninfo(:,3:4), [id_pre(i), id_post(j)], 'rows'));
    end
end
cfpcin_adjmat = adjmat_syn_directed;
cfpcin_ids = [cf_ids; pc_ids; id_in];
save('/data/research/cjpark147/conn_analysis/cfpcin_syn_adjmat_210503_v3.mat', 'cfpcin_adjmat', 'cfpcin_ids');

max_weight = max(cfpcin_adjmat,[],'all')+1;
f=figure('Position',[500,100, 1200, 1000]);
imagesc(log(cfpcin_adjmat+1)); colorbar;
title('log(N + 1)');set(gcf,'color','w'); set(gca,'FontSize',19);
%ylabel('IN2                          IN1                                   CF'); xlabel('PC                                   IN1                             IN2');
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',18);


f=figure('Position',[500,100, 1200, 1000]);
imagesc((cfpcin_adjmat(1:10,11:end))); colorbar;
title('log(N + 1)');set(gcf,'color','w'); set(gca,'FontSize',19);
%ylabel('IN2                          IN1                                   CF'); xlabel('PC                                   IN1                             IN2');
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',18);
%}


%% Figure 4A: Connectivity matrix
%{
load('/data/research/cjpark147/conn_analysis/cfpcin_syn_adjmat_210503_v3.mat');
max_weight = max(cfpcin_adjmat,[],'all')+1;
f=figure('Position',[500,100, 1200, 1000]);
imagesc(log(cfpcin_adjmat+1)); colorbar;
title('log(adjmat + 1)');set(gcf,'color','w'); set(gca,'FontSize',19);
ylabel('IN2                          IN1                                   CF'); xlabel('PC                                   IN1                             IN2');
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',18);
xline([0, 10.5]); xline([0, 30.5]); yline([0, 10.5]); yline([0, 30.5]);
%save_figure(f, 'f4c_conn_matrix','svg');
%}

%% Extended figure CF, IN1, IN2, to PC, IN1, IN2 adj matrix including fragments

%{
cf_all = [7,166,227,293,453,463,465,561,595,626,681,715,772,861,863,873,878,913,931,932,953,964,965,1885]';
%pc_all = [4,3,11,3,21,18,81,18,19322,17211,13,13,20,82,20,81,49,78,50,739,175,81,3,81]');
pc_all = [4,3,11,21,18,81,19322,17211,13,20,82,49,78,50,739,175]';
 
load('/data/research/cjpark147/conn_analysis/cfpc_pairs.mat');
load('/data/research/cjpark147/conn_analysis/in1_in2_frag_id.mat');
in1_all = [in1_ids; in1_frag];
in2_all = [in2_ids; in2_frag];
id_in = [in1_all; in2_all];

inin_syninfo = get_syn_info(id_in,id_in);
inpc_syninfo = get_syn_info(id_in,pc_all);
cfpc_syninfo = get_syn_info(cf_all, pc_all);
all_syninfo = [inin_syninfo; inpc_syninfo];

id_pre = [cf_all; id_in];
id_post = [pc_all;  id_in];
nrow = numel(id_pre); ncol = numel(id_post);
adjmat_syn_directed = zeros(nrow, ncol);
%adj_mat_syn_directed(1:numel(cf_ids), numel(pc_ids)+1:end) = adjmat_cfin;

cfin_info = readtable('/data/lrrtm3_wt_syn/cfin_syn_min6.txt');
cfin_info2 = readtable('/data/lrrtm3_wt_syn/synapse_det_info_210503.txt');
for i = 1:numel(cf_all)
    for j = 1:numel(pc_all)
        adjmat_syn_directed(i,j)=sum(ismember(cfpc_syninfo(:,3:4), [cf_all(i), pc_all(j)], 'rows'));
    end            
    
    for j = numel(pc_all)+1:ncol
        adjmat_syn_directed(i,j)=sum(ismember(cfin_info.seg_pre, cf_all(i)) & ismember(cfin_info.seg_post, id_in(j-numel(pc_all))));
    end
    
    for j = numel(pc_all)+numel(in1_ids)+1:numel(pc_all)+numel(in1_all)
        adjmat_syn_directed(i,j)=sum(ismember(cfin_info2.seg_pre, cf_all(i)) & ismember(cfin_info2.seg_post, in1_all(j-numel(pc_all))));
    end
    
    for j = numel(pc_all)+numel(in1_all)+numel(in2_ids)+1:numel(pc_all)+numel(in1_all)+numel(in2_all)
        adjmat_syn_directed(i,j)=sum(ismember(cfin_info2.seg_pre, cf_all(i)) & ismember(cfin_info2.seg_post, in2_all(j-numel(pc_all)-numel(in1_all))));
    end   
    
end

for i = numel(cf_all)+1:nrow
    for j = 1:ncol
        adjmat_syn_directed(i,j)=sum(ismember(all_syninfo(:,3:4), [id_pre(i), id_post(j)], 'rows'));
    end
end
cfpcin_adjmat_extended = adjmat_syn_directed;

max_weight = max(cfpcin_adjmat_extended,[],'all')+1;
f=figure('Position',[500,100, 1200, 1000]);
imagesc((cfpcin_adjmat_extended+1)); colorbar;
%imagesc(log(cfpcin_adjmat_extended+1)); colorbar;
%title('log(N + 1)');
set(gcf,'color','w'); set(gca,'FontSize',19);
%ylabel('IN2                          IN1                                   CF'); xlabel('PC                                   IN1                             IN2');
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
%set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',6);
set(gca,'XTick',[16,36,145,151], 'YTick',[24,44,153,159],'DataAspectRatio',[1 1 1],'FontSize',6);
%}


%% Create PF, IN1, IN2, PC connectivity matrix     
%{
load('/data/research/cjpark147/conn_analysis/selected_cell_ids.mat')
load('/data/research/cjpark147/conn_analysis/pf_ids.mat')

pfin_info = get_syn_info(pf_ids, [in1_ids;in2_ids]);
pfpc_info = get_syn_info(pf_ids, pc_ids);
inin_info = get_syn_info([in1_ids;in2_ids], [in1_ids;in2_ids]);
inpc_info = get_syn_info([in1_ids;in2_ids], pc_ids);
all_info = [pfin_info; pfpc_info; inin_info; inpc_info];
pre_ids = [pf_ids; in1_ids; in2_ids];
post_ids = [in1_ids; in2_ids; pc_ids'];

npf = numel(pf_ids); nin1 = numel(in1_ids);  nin2 = numel(in2_ids); npc = numel(pc_ids);
nrow = npf + nin1 + nin2;
ncol = nin1+nin2+npc;
conn_matrix = zeros(nrow,ncol);
for i = 1:nrow
    for j = 1:ncol
        conn_matrix(i,j) = sum(ismember(all_info(:,3:4), [pre_ids(i), post_ids(j)], 'rows'));
    end
    if mod(i,10) == 0
        fprintf('%d\n' , i);
    end
end

conn_matrix_sparse = sparse(conn_matrix);
save('/data/research/cjpark147/conn_analysis/conn_matrix_sparse_221123.mat','conn_matrix_sparse');
%}

% Outdated
%{
load('/data/research/cjpark147/conn_analysis/target_cell_ids.mat');
pfin_info = get_syn_info(pf_notT_ids, [in1_ids;in2_ids]);
pfpc_info = get_syn_info(pf_notT_ids, good_pc_ids);
inin_info = get_syn_info([in1_ids;in2_ids], [in1_ids;in2_ids]);
inpc_info = get_syn_info([in1_ids;in2_ids], good_pc_ids);
all_info = [pfin_info; pfpc_info; inin_info; inpc_info];
all_ids = [pf_notT_ids; in1_ids; in2_ids; good_pc_ids];

npf = numel(pf_notT_ids); nin1 = numel(in1_ids);  nin2 = numel(in2_ids); npc = numel(good_pc_ids);
nrow = npf + nin1 + nin2 + npc;
conn_matrix = zeros(nrow,nrow);
for i = 1:(npf+nin1+nin2)
    for j = (npf+1):nrow
        conn_matrix(i,j) = sum(ismember(all_info(:,3:4), [all_ids(i), all_ids(j)], 'rows'));
    end
    if mod(i,100) == 0
        fprintf('%d\n' , i);
    end
end
%}

%% IN-IN Contacts 
%{
% dend contact
for i = 1:numel(id_in)
    for j = i:numel(id_in)
        adj_mat_dend_contact(i,j) = sum(contacts(1,:) == id_dend(i) & contacts(2,:) == id_dend(j));
        adj_mat_dend_contact(i,j) = adj_mat_dend_contact(i,j) + sum(contacts(2,:) == id_dend(i) & contacts(1,:) == id_dend(j));
    end
end


% all contact
for i = 1:numel(id_in)
    for j = i:numel(id_in)
        adj_mat_all_contact(i,j) = sum(ismember(contacts2(1,:), id_in(i)) & ismember(contacts2(2,:), id_in(j)));
        adj_mat_all_contact(i,j) = adj_mat_all_contact(i,j) + sum(ismember(contacts2(2,:), id_in(i)) & ismember(contacts2(1,:), id_in(j)));
    end
end
%}


%% Autapses of IN
% If autpase exists, such interface is not included in assembly_interface.h5
% Manual search is required.
%{
in_autapse = [];
for i = 1:numel(id_in)
    idx1 = ismember(contacts(1,:), id_dend(i)) & ismember(contacts(2,:), id_axon(i));
    idx2 = ismember(contacts(2,:), id_dend(i)) & ismember(contacts(1,:), id_axon(i));
    idx = idx1 | idx2;
    coords = contacts(6:8, idx)' * 4;
    coords(:,3) = coords(:,3) * 4;
    [nrow,ncol] = size(coords);
    this_id = repmat(id_in(i), nrow,1);
    data = [this_id, coords];
    in_autapse = [in_autapse; data];
end
%}

