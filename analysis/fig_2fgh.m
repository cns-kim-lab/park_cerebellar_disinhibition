load('./mat/selected_cell_ids.mat');
load('./mat/soma_syn_for_pc_and_in.mat');
load('./mat/in1_in2_frag_id.mat')
load('./mat/int_graph_dend_axon.mat')


%% Volume Synapse Density (Fig 2f)

pf_recon = 0.76;
pc_recon = 0.99;
in_recon = 0.97;
cf_recon = 1;
EM_volume_size = 958470; % um^3
cfin_tp_rate=0.43;

% volume density
info1 = get_syn_info('pf','pc');
info2 = get_syn_info('pf','in');
info3 = get_syn_info('in','pc');
info4 = get_syn_info('in','in');
info5 = get_syn_info('cf','pc');
info6 = get_syn_info('cf','in');
[n1,~] = size(info1); [n2,~] = size(info2); [n3,~] = size(info3); [n4,~] = size(info4); [n5,~] = size(info5); [n6,~] = size(info6);
sf0 = figure('Position',[300 800 800 650]);
%volume_density = [0.155, 0.051, 0.011, 0.008, 0.004,0.0000584];
volume_density = [n1, n2, n3, n4, n5, 56]/EM_volume_size;
volume_density_exp = [n1/pf_recon, n2/pf_recon, n3, n4, n5, n6*cfin_tp_rate]/EM_volume_size;
b = bar(volume_density,'BarWidth', 0.8,'FaceColor',[180,180,180]/255); hold on;
%b.FaceColor = 'flat'; b.CData(:,:) = repmat([90,50,90]/255, 6,1);
scatter(1:6,volume_density_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
ylabel('Synapse density [um^-^3]'); 
set(gcf,'color','w'); set(gca,'FontSize',22, 'XTickLabel', { 'PF-PC','PF-IN','IN-PC','IN-IN','CF-PC','CF-IN'});
title('Volume density'); 
%inset
sf01 = figure('Position',[300 800 600 650]);
volume_density_inset = volume_density(5:6);
b = bar(volume_density_inset,'BarWidth', 0.8,'FaceColor',[180,180,180]/255); hold on;
%b.FaceColor = 'flat'; b.CData(:,:) = repmat([90,50,90]/255, 2,1);
px=[0.4 1.6]; 
py1=[0.00026, 0.0003];
py2=py1+0.00003;
plot(px,py1,'k','LineWidth',2);hold all;
plot(px,py2,'k','LineWidth',2);hold all;
scatter(2,volume_density_exp(6),150,'o','filled','MarkerFaceColor',[250,75,75]/255);
fill([px flip(px)],[py1 flip(py2)],'w','EdgeColor','none');
ylabel('Synapse density [um^-^3]'); ylim([0,0.0005]);
set(gcf,'color','w'); set(gca,'FontSize',22, 'XTickLabel', { 'CF-PC','CF-IN'});
title('Inset');


%% Linear synapse density on PC dendrites (Fig 2g)

load('./mat/in_syn_on_pc_soma.mat');
load('./mat/pc_shaft_graph_isomip2.mat');
npc = numel(pc_ids);
synden_dend_pfpc = zeros(npc,3);
synden_dend_cfpc = zeros(npc,3);
synden_dend_inpc = zeros(npc,3);
for i = 1:npc
    G = pc_shaft_graph{i,1};
    total_dend_length = sum(G.graph.Edges.Weight) * ((0.048+0.048+0.05)/3); % um
    
    % PF-PC
    info = get_syn_info('pf', pc_ids(i));
    syn_on_dend = setdiff(info(:,1), all_syn_on_pc_soma);
    [nsyn_pf,~] = size(syn_on_dend);
    synden_dend_pfpc(i,1) = nsyn_pf;
    synden_dend_pfpc(i,2) = total_dend_length;
    synden_dend_pfpc(i,3) = nsyn_pf / total_dend_length;    
    
    % CF-PC
    info = get_syn_info('cf', pc_ids(i));
    syn_on_dend = setdiff(info(:,1), all_syn_on_pc_soma);
    [nsyn_cf,~] = size(syn_on_dend);
    synden_dend_cfpc(i,1) = nsyn_cf;
    synden_dend_cfpc(i,2) = total_dend_length;
    synden_dend_cfpc(i,3) = nsyn_cf / total_dend_length;
    
    % IN-PC
    info = get_syn_info('in', pc_ids(i));
    syn_on_dend = setdiff(info(:,1), all_syn_on_pc_soma);
    [nsyn_in, ~] = size(syn_on_dend);
    synden_dend_inpc(i,1) = nsyn_in;
    synden_dend_inpc(i,2) = total_dend_length;
    synden_dend_inpc(i,3) = nsyn_in / total_dend_length;   
    
end


%% Linear synapse density on IN dendrites

nin = numel(target_interneurons);
synden_dend_pfin = zeros(nin,3);
synden_dend_cfin = zeros(nin,3);
synden_dend_inin = zeros(nin,3);
in1_dend_lengths = [];
in2_dend_lengths = [];

cfin_table = readtable('./mat/cfin_syn_info_min6_fix_pos.txt');
for i = 1:nin
    total_skel_length = sum(int_graph_dend_isomip3{i,1}.graph.Edges.Weight)*((0.096+0.096+0.1)/3); % um
    if ismember(target_interneurons(i), in1_ids)
        in1_dend_lengths = [in1_dend_lengths; total_skel_length];
    elseif ismember(target_interneurons(i), in2_ids)
        in2_dend_lengths = [in2_dend_lengths; total_skel_length];
    end
    % PF-IN
    info = get_syn_info('pf', target_interneurons(i));
    [nsyn_pf,~] = size(info);
    synden_dend_pfin(i,1) = nsyn_pf;
    synden_dend_pfin(i,2) = total_skel_length;
    synden_dend_pfin(i,3) = nsyn_pf / total_skel_length;    
    
    % CF-IN
    nsyn_cf = sum(cfin_table.seg_post == target_interneurons(i));
    synden_dend_cfin(i,1) = nsyn_cf;
    synden_dend_cfin(i,2) = total_skel_length;
    synden_dend_cfin(i,3) = nsyn_cf / total_skel_length;
    
    % IN-IN
    info = get_syn_info('in', target_interneurons(i));
    [nsyn_in, ~] = size(info);
    synden_dend_inin(i,1) = nsyn_in;
    synden_dend_inin(i,2) = total_skel_length;
    synden_dend_inin(i,3) = nsyn_in / total_skel_length;
end


synden_dend_in1in1 = zeros(numel(in1_ids,3));
synden_dend_in2in1 = zeros(numel(in1_ids,3));
synden_dend_in1in2 = zeros(numel(in2_ids,3));
synden_dend_in2in2 = zeros(numel(in2_ids,3));
for i = 1:numel(in1_ids)
    idx = find(target_interneurons == in1_ids(i));
    total_skel_length = sum(int_graph_dend_isomip3{idx,1}.graph.Edges.Weight)*((0.096+0.096+0.1)/3); % um
    info = get_syn_info([in1_ids;in1_ids_frag], in1_ids(i));
    [nsyn,~] = size(info);
    synden_dend_in1in1(i,1) = nsyn;
    synden_dend_in1in1(i,2) = total_skel_length;
    synden_dend_in1in1(i,3) = nsyn / total_skel_length;     

    info = get_syn_info([in2_ids;in2_ids_frag], in1_ids(i));
    [nsyn,~] = size(info);
    synden_dend_in2in1(i,1) = nsyn;
    synden_dend_in2in1(i,2) = total_skel_length;
    synden_dend_in2in1(i,3) = nsyn / total_skel_length;        
end
for i = 1:numel(in2_ids)
    idx = find(target_interneurons == in2_ids(i));
    total_skel_length = sum(int_graph_dend_isomip3{idx,1}.graph.Edges.Weight)*((0.096+0.096+0.1)/3); % um
    info = get_syn_info([in1_ids;in1_ids_frag], in2_ids(i));
    [nsyn,~] = size(info);
    synden_dend_in1in2(i,1) = nsyn;
    synden_dend_in1in2(i,2) = total_skel_length;
    synden_dend_in1in2(i,3) = nsyn / total_skel_length;     

    info = get_syn_info([in2_ids;in2_ids_frag], in2_ids(i));
    [nsyn,~] = size(info);
    synden_dend_in2in2(i,1) = nsyn;
    synden_dend_in2in2(i,2) = total_skel_length;
    synden_dend_in2in2(i,3) = nsyn / total_skel_length;        
end

avg_input_density_in1in1 = mean(synden_dend_in1in1(:,3));
avg_input_density_in2in1 = mean(synden_dend_in2in1(:,3));
avg_input_density_in1in2 = mean(synden_dend_in1in2(:,3));
avg_input_density_in2in2 = mean(synden_dend_in2in2(:,3));

%}


%% Linear synapse density on IN axon (Fig 2h)

info1 = get_syn_info([in1_ids;in2_ids], 'in');
info2 = get_syn_info([in1_ids;in2_ids], 'pc');
[inin_syn_count,~] = size(info1);
[inpc_syn_count,~] = size(info2);
nin = numel(target_interneurons);
synden_axon_inin = zeros(nin,3); 
synden_axon_inpc = zeros(nin,3);

for i = 1:nin
    info1 = get_syn_info(target_interneurons(i), 'in');
    info2 = get_syn_info(target_interneurons(i), 'pc');
    [n1,~] = size(info1);
    [n2,~] = size(info2);    
    G = int_graph_axon_isomip3{i,1};
    in_axon_length = sum(G.graph.Edges.Weight) * ((0.096+0.096+0.1)/3); % um
    synden_axon_inin(i,1) = n1;
    synden_axon_inpc(i,1) = n2;
    synden_axon_inin(i,2) = in_axon_length;
    synden_axon_inpc(i,2) = in_axon_length;
    synden_axon_inin(i,3) = n1 / in_axon_length;
    synden_axon_inpc(i,3) = n2 / in_axon_length;
end

in_ids = [in1_ids; in2_ids];
in1_ids_frag = in1_frag;
in2_ids_frag = in2_frag;


%% Linear synapse density on PF

load('./mat/skel_main_branch_pf.mat');  % aniso mip2

[npf, ~] = size(skel_main_branches_pf);
pf_ids_used = [skel_main_branches_pf{:,1}]';
info1 = get_syn_info(pf_ids_used,'in');
info2 = get_syn_info(pf_ids_used,'pc');
[pfin_syn_count,~] = size(info1); 
[pfpc_syn_count,~] = size(info2);
synden_axon_pfin = zeros(npf,3);
synden_axon_pfpc = zeros(npf,3);
for i = 1:npf
    this_skel = skel_main_branches_pf{i,2};
    if ~isempty(this_skel)
        n1 = sum(ismember(info1(:,3), skel_main_branches_pf{i,1}));
        n2 = sum(ismember(info2(:,3), skel_main_branches_pf{i,1}));
        %info1 = get_syn_info(skel_main_branches_pf{i,1}, 'in');
        %info2 = get_syn_info(skel_main_branches_pf{i,1}, 'pc');        
        %[n1,~] = size(info1);
        %[n2,~] = size(info2);        
        this_skel(:,3) = this_skel(:,3)*4;  % make iso mip2
        v = this_skel(2:end,:) - this_skel(1:end-1,:);
        pf_skel_length = sum(vecnorm(v')) * (0.048+0.048+0.05)/3;   
        synden_axon_pfin(i,1) = n1; 
        synden_axon_pfin(i,2) = pf_skel_length;
        synden_axon_pfin(i,3) = n1 / pf_skel_length;
        synden_axon_pfpc(i,1) = n2;
        synden_axon_pfpc(i,2) = pf_skel_length;
        synden_axon_pfpc(i,3) = n2 / pf_skel_length;
    end
    if mod(i,1000)==0
        fprintf('%d\n',i);
    end
end


%% Linear synapse density on CF

ncf = numel(cf_ids);
synden_axon_cfin = zeros(ncf,3);
synden_axon_cfpc = zeros(ncf,3);
%cfin_table = readtable('/data/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');

for i = 1:ncf
    load(['./mat/skeleton_of_CF_',num2str(cf_ids(i)),'.iso_mip3.dilated.ps_1.20.pc_15.mat']);
    [~,nb] = size(branch_path_sub);
    cf_skel_length = 0;
    for j = 1:nb
        br = branch_path_sub{1,j};
        v = br(2:end,:) - br(1:end-1,:);
        cf_skel_length = cf_skel_length + sum(vecnorm(v')) * (0.096+0.096+0.1)/3;
    end
    info1 = get_syn_info(cf_ids(i),'pc');
    info2 = get_syn_info(cf_ids(i),'in');
    [n1,~] = size(info1);
    [n2,~] = size(info2);
    synden_axon_cfpc(i,1) = n1;
    synden_axon_cfpc(i,2) = cf_skel_length;
    synden_axon_cfpc(i,3) = n1 / cf_skel_length;
    synden_axon_cfin(i,1) = n2;
    synden_axon_cfin(i,2) = cf_skel_length;
    synden_axon_cfin(i,3) = n2 / cf_skel_length;    
end

%}



%% Number of IN2s that each IN1 receives


% ------ IN1 to IN1 ------
%{
idx_pre_long_axon = find(synden_axon_inin(:,2)>1600);  % IN1
pre_ids_long_axon = target_interneurons(idx_pre_long_axon);
pre_ids_incl_orphan = [in1_ids; in1_ids_frag];
idx_post_long_dend = find(synden_dend_in1in1(:,2)>1200);
post_ids = in1_ids(idx_post_long_dend); 
%}

% ------ IN1 to IN2 ------
%{
idx_pre_long_axon = find(synden_axon_inin(:,2)>1600);  % IN1
pre_ids_long_axon = target_interneurons(idx_pre_long_axon);
pre_ids_incl_orphan = [in1_ids; in1_ids_frag];
idx_post_long_dend = find(synden_dend_in1in2(:,2)>1000);
post_ids = in2_ids(idx_post_long_dend); 
%}
% ------ IN2 to IN1 ------
%{
pre_ids_long_axon = in2_ids;
pre_ids_incl_orphan = [in2_ids; in2_ids_frag];
idx_post_long_dend = find(synden_dend_in1in1(:,2)>1200);
post_ids = in1_ids(idx_post_long_dend); 
%}
% ------ IN2 to IN2 ------
%{
pre_ids_long_axon = in2_ids;
pre_ids_incl_orphan = [in2_ids; in2_ids_frag];
idx_post_long_dend = find(synden_dend_in1in2(:,2)>1000);
post_ids = in2_ids(idx_post_long_dend); 
%}


nsyn_total = 0; % number of synapses from presynaptic neuron
npre_total = 0; % number of presynaptic neuron
nsyn_incl_orphan = 0;

for i = 1:numel(post_ids)
    a = get_syn_info(pre_ids_long_axon, post_ids(i));
    [nsyn,~] = size(a);
    npre = numel(unique(a(:,3)));
    nsyn_total = nsyn_total + nsyn;
    npre_total = npre_total + npre;

    b = get_syn_info(pre_ids_incl_orphan, post_ids(i));
    [nsyn,~] = size(b);
    nsyn_incl_orphan = nsyn_incl_orphan + nsyn;
end
avg_nsyn_from_pre = nsyn_total / npre_total;   % avg number of synapses that each presynaptic cell type receives from postsynaptic cell type
avg_n_pre = nsyn_incl_orphan / avg_nsyn_from_pre;




%% Linear synapse density on IN1/2 dendrites

idx_in1 = find(ismember(target_interneurons,in1_ids));
synden_dend_pfin1 = synden_dend_pfin(idx_in1,:);
synden_dend_cfin1 = synden_dend_cfin(idx_in1,:);
synden_dend_inin1 = synden_dend_inin(idx_in1,:);

idx_in2 = find(ismember(target_interneurons,in2_ids));
synden_dend_pfin2 = synden_dend_pfin(idx_in2,:);
synden_dend_cfin2 = synden_dend_cfin(idx_in2,:);
synden_dend_inin2 = synden_dend_inin(idx_in2,:);
