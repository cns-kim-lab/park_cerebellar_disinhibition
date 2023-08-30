load('/data/research/cjpark147/conn_analysis/in_ids_all.mat');
load('/data/research/cjpark147/conn_analysis/in_soma_dist_all.mat');

in_ids_w_soma = d_soma_all(:,1);
in_targets = setdiff(in_ids_all, in_ids_w_soma);
dend_segments =[];
axon_segments = [];
both_segments = [];
score = [];

pfin_syn_info = get_syn_info('pf',in_targets);
inin_syn_info = get_syn_info('in',in_targets);
cfin_syn_info = get_syn_info('cf',in_targets);
pcin_syn_info = get_syn_info('pc',in_targets);

pfout_syn_info = get_syn_info(in_targets,'pf');
inout_syn_info = get_syn_info(in_targets,'in');
cfout_syn_info = get_syn_info(in_targets,'cf');
pcout_syn_info = get_syn_info(in_targets,'pc');

in_syn_info = [pfin_syn_info;inin_syn_info;cfin_syn_info;pcin_syn_info];
out_syn_info =[pfout_syn_info;inout_syn_info;cfout_syn_info;pcout_syn_info];
%syn_info = [pfin_syn_info;inin_syn_info;cfin_syn_info;pcin_syn_info;pfout_syn_info;inout_syn_info;cfout_syn_info;pcout_syn_info];


for i = 1:numel(in_targets)        
    n1 = sum(ismember(in_syn_info(:,4), in_targets(i)));  % #syn this IN is postsynaptic to
    n2 = sum(ismember(out_syn_info(:,3), in_targets(i)));  % #syn this IN is presynaptic to
        
    if n1+n2 > 10
        fprintf('%d \n', i);
        idx = (n1-n2)/(n1+n2);
        
        score = [score; in_targets(i), idx];

        if idx >= 0.5
            dend_segments = [dend_segments; in_targets(i)];
        elseif idx <= -0.5
            axon_segments =  [axon_segments; in_targets(i)];
        else
            both_segments = [both_segments; in_targets(i)];
        end  
    end
end

figure;
histogram(score(:,2),12);
set(gcf,'color','w'); set(gca,'FontSize',20);
xline(0.5,'--', 'LineWidth',1.5, 'Color','r');
xlabel('dendrite score');ylabel('count');










