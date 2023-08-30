
%% Volume/Linear synapse density 

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


% dend density
sf1 = figure('Position',[300 800 800 650]);
mu_pc = mean([synden_dend_pfpc(:,3),synden_dend_cfpc(:,3),synden_dend_inpc(:,3)]);
mu_in = mean([synden_dend_pfin(:,3),synden_dend_cfin(:,3),synden_dend_inin(:,3)]);
sd_pc = std([synden_dend_pfpc(:,3),synden_dend_cfpc(:,3),synden_dend_inpc(:,3)]);
sd_in = std([synden_dend_pfin(:,3),synden_dend_cfin(:,3),synden_dend_inin(:,3)]);
linear_dend_density = [ mu_pc,0,0,mu_in];
%linear_dend_density = [linear_density_pfpc, linear_density_cfpc, linear_density_inpc, 0,0,linear_density_pfin, linear_density_cfin, linear_density_inin];

% expected density
mu_pc_exp = mean([synden_dend_pfpc(:,3)/pf_recon,synden_dend_cfpc(:,3)/cf_recon,synden_dend_inpc(:,3)/in_recon]);
mu_in_exp = mean([synden_dend_pfin(:,3)/pf_recon,synden_dend_cfin(:,3)/cf_recon,synden_dend_inin(:,3)/in_recon]);

b = bar(linear_dend_density,'BarWidth', 0.8,'FaceColor',[180,180,180]/255); hold on;
%b.FaceColor = 'flat'; b.CData(1:3,:) = repmat([180,220,160]/255, 3,1);
%b.CData(6:8,:) = repmat([60,110,220]/255,3,1);
ylabel('Synapse density [um^-^1]'); 
scatter(1:3,mu_pc_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
scatter(6:8,mu_in_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
err_low = [sd_pc,0,0, sd_in];  err_high = [sd_pc,0,0, sd_in];
er = errorbar(1:3, mu_pc, sd_pc, sd_pc,'k.'); er(1).LineWidth=1.5; 
er = errorbar(6:8, mu_in, [sd_in(1),0,sd_in(3)], [sd_in(1),0,sd_in(3)],'k.'); er(1).LineWidth=1.5; 
set(gcf,'color','w'); set(gca,'FontSize',22, 'XTickLabel', { 'PF-PC','CF-PC','IN-PC','','','PF-IN','CF-IN','IN-IN'});
title('On dendrite');

% inset
sf2 = figure('Position',[300 800 800 650]);
%linear_dend_density_inset = [linear_density_pfin, linear_density_cfin, linear_density_inin];
linear_dend_density_inset = mu_in;
b = bar(linear_dend_density_inset,'BarWidth', 0.8,'FaceColor',[180,180,180]/255); hold on; 
%b.FaceColor = 'flat'; b.CData(1:3,:) = repmat([60,110,220]/255, 3,1);
er = errorbar(2, mu_in(2), sd_in(2), sd_in(2),'k.'); er(1).LineWidth=1.5; 
px=[0.4 1.6]; py1=[0.075, 0.082]; 
py2=py1+0.004;
plot(px,py1,'k','LineWidth',2);
plot(px,py2,'k','LineWidth',2);
fill([px flip(px)],[py1 flip(py2)],'w','EdgeColor','none');
px=[2.4 3.6]; py1=[0.075, 0.082]; 
py2=py1+0.004;
plot(px,py1,'k','LineWidth',2);
plot(px,py2,'k','LineWidth',2);
fill([px flip(px)],[py1 flip(py2)],'w','EdgeColor','none');
ylabel('Synapse density [um^-^1]'); ylim([0 0.1])
set(gcf,'color','w'); set(gca,'FontSize',22, 'XTickLabel', {'PF-IN','CF-IN','IN-IN'});
title('inset');


% axon density
sf3 = figure('Position',[300 800 800 650]);
mu_cf = mean([synden_axon_cfpc(:,3),synden_axon_cfin(:,3)*cfin_tp_rate]);
mu_pf = mean([synden_axon_pfpc(:,3),synden_axon_pfin(:,3)]);
mu_in = mean([synden_axon_inpc(:,3),synden_axon_inin(:,3)]);
sd_cf = std([synden_axon_cfpc(:,3),synden_axon_cfin(:,3)*cfin_tp_rate]);
sd_pf = std([synden_axon_pfpc(:,3),synden_axon_pfin(:,3)]);
sd_in = std([synden_axon_inpc(:,3),synden_axon_inin(:,3)]);
linear_axon_density = [ mu_cf,0,0,mu_pf,0,0,mu_in];
% expected density
mu_cf_exp =mean([synden_axon_cfpc(:,3)/pc_recon,synden_axon_cfin(:,3)/in_recon*cfin_tp_rate]);
mu_pf_exp =mean([synden_axon_pfpc(:,3)/pc_recon,synden_axon_pfin(:,3)/in_recon]);
mu_in_exp =mean([synden_axon_inpc(:,3)/pc_recon,synden_axon_inin(:,3)/in_recon]);

%linear_axon_density = [lin_density_axon_cfpc,lin_density_axon_cfin, 0,0,lin_density_axon_pfpc,lin_density_axon_pfin, 0,0, lin_density_axon_inpc,lin_density_axon_inin];
b = bar(linear_axon_density,'BarWidth', 0.8,'FaceColor',[180,180,180]/255); hold on;
%b.FaceColor = 'flat'; b.CData(1:2,:) = repmat([240,160,20]/255, 2,1); b.CData(5:6,:) = repmat([190,100,190]/255,2,1); b.CData(9:10,:) = repmat([60,110,220]/255,2,1);
ylabel('Synapse density [um^-^1]'); 
scatter(1:2,mu_cf_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
scatter(5:6,mu_pf_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
scatter(9:10,mu_in_exp,100,'o','filled','MarkerFaceColor',[250,75,75]/255);
er = errorbar(1:2, mu_cf, sd_cf, sd_cf,'k.'); er(1).LineWidth=1.5; 
er = errorbar(5:6, mu_pf, [sd_pf(1), mu_pf(2)], sd_pf,'k.'); er(1).LineWidth=1.5; 
er = errorbar(9:10, mu_in, [sd_in(1),mu_in(2)], sd_in,'k.'); er(1).LineWidth=1.5; 
set(gcf,'color','w'); set(gca,'FontSize',22, 'XTickLabel', {'CF-PC','CF-IN','','','PF-PC','PF-IN','','','IN-PC','IN-IN'}); 
title('On axon');
%}

