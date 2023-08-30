
%% Extended figure 6 - PFs nearby PC that target multiple INs 

load('/data/research/cjpark147/conn_analysis/pf_unique_type_sorted.mat');
%vol = h5read('/data/lrrtm3_wt_reconstruction/segment_iso_mip3_all_cells_210503.pc_cb_cut_and_int_axon_cut.sample_first_sheet.h5','/main');
%vol = h5read('/data/research/cjpark147/segment_iso_mip3_all_cells_200313.h5','/main');
num_types=8;
pfin_mat_per_pf_type = cell(npc, num_types);
multiplier = 1; % use 1 if vol = unseparated segment,   use 100 if vol = axon/dend/cb separated 

%{
for i = 1:npc
    % Presynaptic IN1, IN2 ids
    info = get_syn_info(in1_ids, pc_ids(i));
    in1_pre = unique(info(:,3));
    info = get_syn_info(in2_ids, in1_pre);
    in2_pre = unique(info(:,3));    
    in_pre = [in1_pre;in2_pre];
    
    % Distribution of number of involved INs, targeted by a given PF type.
    for j = 1:num_types
        this_pfs = pf_unique_type_sorted{i,j};
        this_pfin_mat = zeros(numel(this_pfs), numel(in_pre));
        for k = 1:numel(in_pre)
            info = get_syn_info(this_pfs, in_pre(k));
            pf_con = unique(info(:,3));
            this_pfin_mat(:,k) = ismember(this_pfs, pf_con);
        end
        pfin_mat_per_pf_type{i,j} = this_pfin_mat;        
    end
    fprintf('%d',i);
 
end
%}

load('/data/research/cjpark147/conn_analysis/pfin_mat_per_pf_type.mat');
f = figure('Position',[100,100, 3000, 1400]);
for i = 1:num_types
    violin_data = [];
    subplot(2,4,i);
    for j = 1:npc
        temp = pfin_mat_per_pf_type{j,i};
        counts = sum(temp,2); % number of IN innervated by a given type of PF
        freq = histc(counts, 0:8);
        [npf_this_type,~] = size(temp);
        frac = freq / npf_this_type;
        violin_data = [violin_data; [(1:9)', frac]];
    end
    v = violinplot(violin_data(:,2)*100, violin_data(:,1),'ViolinColor', [180,80,180]/255);
    xticks([1:9]); xticklabels([0:8]); ylim([0 100]);
    xlabel('Number of connected IN'); ylabel('proportion (%)'); title(['PF type ', num2str(i)], 'FontWeight','normal');
    set(gcf, 'color', 'w'); set(gca,'FontSize',20);
end
%}

