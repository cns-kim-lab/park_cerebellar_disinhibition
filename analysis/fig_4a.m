%% Figure 4A: Connectivity matrix
% This is a simplified code for figure using pre-computed data.
% See the sections at the end of this script for the data computation script.

load('./mat/cfpcin_syn_adjmat.mat');
max_weight = max(cfpcin_adjmat,[],'all')+1;
f=figure('Position',[500,100, 1200, 1000]);
imagesc(log(cfpcin_adjmat+1)); colorbar;
title('log(adjmat + 1)');set(gcf,'color','w'); set(gca,'FontSize',19);
spaces = repmat(' ', 1, 50);
ylabel(['IN2',spaces,'IN1',spaces,'CF']); xlabel(['PC',spaces,'IN1',spaces,'IN2']);
cmap_adjmat = [linspace(254/255,100/255,max_weight)', linspace(254/255,55/255,max_weight)', linspace(255/255,100/255,max_weight)'];
colormap(cmap_adjmat); c=colorbar; c.FontSize=26;
set(gcf,'color','w'); 
set(gca,'XTick',[], 'YTick',[],'DataAspectRatio',[1 1 1],'FontSize',18);
xline([0, 10.5]); xline([0, 30.5]); yline([0, 10.5]); yline([0, 30.5]);



%% Script for adj matrix generation

load('./mat/in1_ids.mat');
load('./mat/in2_ids.mat');
load('./mat/adjmat_cfin_min6.mat');

in1_ids = in1_ids(randperm(numel(in1_ids)));
id_in = [in1_ids; in2_ids];
omit_in = [19]; % doesn't have axon
id_in(ismember(id_in, omit_in)) = [];

target_pc_ids = [18;11;21;4;20;49;13;50;175;739];
pc_ids = [18;11;4;13;21;20;49;50;3;175];
cf_ids = [463;227;7;681;453;772;878;931;166;953];
inin_syninfo = get_syn_info(id_in,id_in);
inpc_syninfo = get_syn_info(id_in,pc_ids);
cfpc_syninfo = get_syn_info(cf_ids, pc_ids);
all_syninfo = [inin_syninfo; inpc_syninfo];
id_pre = [cf_ids; id_in];
id_post = [pc_ids;  id_in];
nrow = numel(id_pre); ncol = numel(id_post);
adjmat_syn_directed = zeros(nrow, ncol);

cfin_info = readtable('./mat/cfin_syn_min6.txt');
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

%}






