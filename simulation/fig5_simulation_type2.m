
%% Simulation. CF-IN2 absent

dt = 0.1;
t = -5:dt:16;
tau1 = -5:dt:15;           
a= 2;
b= 0.5;
k= 1;
ntrial = 1000;
delay = 1;

overlap_area_absent = zeros(ntrial,1); 

% Number of cells 
nodes_pf = 1:2;   
nodes_in1 = 1:1;  
nodes_in2 = 1:1;  
y_cf = double_exp(t, 1, -1, 8, 2);
y_pf = double_exp(t-2.5, 1, -1, 2, 0.5);
y_cf_shapes1 = zeros(ntrial, numel(t));
y_cf_shapes2 = zeros(ntrial, numel(t));

for i = 1:ntrial

    % randomly activate PF
    num_active_pf = randi([2,max(nodes_pf)]);    % number of active PF
    active_pf = randsample(nodes_pf, num_active_pf, false);  % which PF fires?
    timing_pf = randsample(tau1, max(nodes_pf), false);  % Timing of PF firing 
    
    % activity curves when CF-IN2 is absent
    y_in_absent = zeros(numel(nodes_in1) + numel(nodes_in2), length(t));  
    for j = 1:numel(nodes_pf)
        if ismember(j, active_pf)
            y_in_absent(j,:) = y_in_absent(j,:) + (-1*double_exp(t-timing_pf(j), 1, -1, a, b));
        end
    end
    y_in_absent(1,:) = y_in_absent(1,:) + (-1*double_exp(t-2.5, 1, -1, a, b));   % motif 4 
    
    % IN2-IN1 delay
    inin_delay = delay/dt; 
    y_in2_absent_delay = [zeros(1,inin_delay), y_in_absent(2,1:end-inin_delay)];      
    
    % Total IN input to PC when CF-IN2 is absent       
    y_in_total_absent = rect(y_in_absent(1,:) - y_in2_absent_delay, -1);
        
    % IN1-PC delay
    inpc_delay = delay/dt; 
    y_in_total_absent_delay = [zeros(1,inpc_delay), y_in_total_absent(1:end-inpc_delay)];    

    % CF,PF overlap area when CF-IN2 is absent
    y_cf_truncated1 = rect(y_cf + y_in_total_absent_delay, 1);
    y_cf_shapes1(i,:) = y_cf_truncated1;
    area_union = trapz(max(y_pf, y_cf_truncated1));
    A1 = rect(y_pf - y_cf_truncated1, 1);
    A2 = rect(y_cf_truncated1 - y_pf, 1);
    area_btwn_two_curves = trapz(A1) + trapz(A2);
    overlap_area_absent(i) = area_union - area_btwn_two_curves;          
     
end

area_union = trapz(max(y_pf, y_cf));
A1 = rect(y_pf - y_cf, 1);
A2 = rect(y_cf - y_pf, 1);
max_overlap = area_union - (trapz(A1) + trapz(A2));

%% Simulation. CF-IN2 present

overlap_area_present = zeros(ntrial,1); 

for i = 1:ntrial
    % randomly activate PF
    num_active_pf = randi([2,max(nodes_pf)]);    % number of active PF
    active_pf = randsample(nodes_pf, num_active_pf, false);  % which PF fires?
    timing_pf = randsample(tau1, max(nodes_pf), false);  % Timing of PF firing 
    pf_onoff = zeros(1,numel(nodes_pf));
    pf_onoff(active_pf) = 1;
    
    % activity curves when CF-IN2 is present
    y_in_present = zeros(numel(nodes_in1) + numel(nodes_in2), length(t));  
    for j = 1:numel(nodes_pf)
        if ismember(j, active_pf)
            y_in_present(j,:) = y_in_present(j,:) + (-1*double_exp(t-timing_pf(j), 1, -1, a, b));
        end
    end    
    
    y_in_present(1,:) = y_in_present(1,:) + (-1*double_exp(t-2.5, 1, -1, a, b)); % motif 4
    y_in_present(2,:) = y_in_present(2,:) + (-1*double_exp(t-delay, 1, -1, a, b)); % CF-IN2
        
    % IN2-IN1 delay
    inin_delay = delay/dt;
    y_in2_present_delay = [zeros(1,inin_delay), y_in_present(2,1:end-inin_delay)];
    
    % Total IN input to PC when CF-IN2 is present      
    y_in_total_present = rect(y_in_present(1,:) - y_in2_present_delay, -1);
    
    % IN1-PC delay
    inpc_delay = delay/dt;
    y_in_total_present_delay = [zeros(1,inpc_delay), y_in_total_present(1:end-inpc_delay)];    
             
    % CF,PF overlap area when CF-IN2 is present
    y_cf_truncated2 = rect(y_cf + y_in_total_present_delay, 1);
    y_cf_shapes2(i,:) = y_cf_truncated2;
    area_union = trapz(max(y_pf, y_cf_truncated2));
    A1 = rect(y_pf - y_cf_truncated2, 1);
    A2 = rect(y_cf_truncated2 - y_pf, 1);
    area_btwn_two_curves = trapz(A1) + trapz(A2);
    overlap_area_present(i) = area_union - area_btwn_two_curves;
 
end
%}

% average CF trace
f4=figure('Position',[300 100 500 400]);set(gcf,'color','w');
plot(t,y_cf_shapes1(1:50,:)', 'Color', [170,170,175]/255); hold on;
plot(t,mean(y_cf_shapes1)', 'Color', [240,60,60]/255, 'LineWidth',3);
title('CF-IN2 absent');set(gca,'FontSize',16, 'xtick',[], 'ytick',[]);
xlim([-5,16]); ylim([0, 0.52]); 

f5=figure('Position',[1000 100 500 400]); set(gcf,'color','w');
plot(t,y_cf_shapes2(1:50,:)', 'Color', [170,170,175]/255); hold on;
plot(t,mean(y_cf_shapes2)', 'Color', [240,60,60]/255 , 'LineWidth',3);
title('CF-IN2 present');set(gca,'FontSize',16, 'xtick',[], 'ytick',[]);
xlim([-5,16]); ylim([0, 0.52]);   xlabel('t');

% overlap area
f6=figure('Position',[1700 100 600 500]);
violin_data = [];
violin_data = [violin_data; [ones(numel(overlap_area_absent),1), overlap_area_absent]];
violin_data = [violin_data; [ones(numel(overlap_area_present),1)*2, overlap_area_present]];
violin_data(:,2) = violin_data(:,2) / max_overlap;
vp = violinplot(violin_data(:,2), violin_data(:,1), 'ViolinColor', [255,75,75]/255);
vp(2).ViolinColor = [100,250,120]/255;
violin_data_type2= violin_data;
set(gcf, 'color', 'w'); set(gca,'FontSize',24);
ylabel('PF,CF overlap area'); set(gca,'FontSize',19); set(gcf,'color','w');
%legend([h1,h2], {'CF-IN2 absent', 'CF-IN2 present'}, 'Location', 'north');
%}


%% Example activity curves when CF-IN2 is absent/present

dt = 0.1;
t = -5:dt:25;
t2 = -5:dt:16; % for plot
a= 2;
b= 0.5;
k= 1;
ntrial = 1;
delay = 1;
active_pf = [1,2];
timing_pf = [1,4];

overlap_area_absent = zeros(ntrial,1); % when CF-IN2 is absent
overlap_area_present = zeros(ntrial,1);

% Number of cells 
nodes_pf = 1:2;   
nodes_in1 = 1:1;  
nodes_in2 = 1:1;  
y_cf = double_exp(t, 1, -1, 8, 2);
y_pf = double_exp(t-2.5, 1, -1, 2, 0.5);
y_cf_shapes1 = zeros(ntrial, numel(t));
y_cf_shapes2 = zeros(ntrial, numel(t));

for i = 1:ntrial
    
    % activity curves when CF-IN2 is absent
    y_in_absent = zeros(numel(nodes_in1) + numel(nodes_in2), length(t));  
    for j = 1:numel(nodes_pf)
        if ismember(j, active_pf)
            y_in_absent(j,:) = y_in_absent(j,:) + (-1*double_exp(t-timing_pf(j), 1, -1, a, b));
        end
    end
    y_in_absent(1,:) = y_in_absent(1,:) + (-1*double_exp(t-2.5, 1, -1, a, b));

    % IN2-IN1 delay
    inin_delay = delay/dt; 
    y_in2_absent_delay = [zeros(1,inin_delay), y_in_absent(2,1:end-inin_delay)];      
    
    % Total IN input to PC when CF-IN2 is absent       
    y_in1_node1 = rect(y_in_absent(1,:) - y_in2_absent_delay, -1);
    y_in_total_absent = y_in1_node1;
        
    % IN1-PC delay
    inpc_delay = delay/dt; 
    y_in_total_absent_delay = [zeros(1,inpc_delay), y_in_total_absent(1:end-inpc_delay)];    

    % CF,PF overlap area when CF-IN2 is absent
    y_cf_truncated1 = rect(y_cf + y_in_total_absent_delay, 1);
    y_cf_shapes1(i,:) = y_cf_truncated1;
    area_union = trapz(max(y_pf, y_cf_truncated1));
    A1 = rect(y_pf - y_cf_truncated1, 1);
    A2 = rect(y_cf_truncated1 - y_pf, 1);
    area_btwn_two_curves = trapz(A1) + trapz(A2);
    overlap_area_absent(i) = area_union - area_btwn_two_curves;      
    
    % Activity curves when CF-IN2 is present
    y_in_present = y_in_absent;
    y_in_present(2,:) = y_in_present(2,:) + (-1*double_exp(t, 1, -1, a/(2^(k-1)), b/(2^(k-1)))); % CF-IN2

    % IN2-IN1 delay
    inin_delay = delay/dt; 
    y_in_present_delay = [zeros(1,inin_delay), y_in_present(2,1:end-inin_delay)];    
    
    % Total IN input to PC when CF-IN2 is present    
    y_in1_node1_present = rect(y_in_present(1,:) - y_in_present_delay, -1);
    y_in_total_present = y_in1_node1_present;

    % IN1-PC delay
    inpc_delay = delay/dt; 
    y_in_total_present_delay = [zeros(1,inpc_delay), y_in_total_present(1:end-inpc_delay)];        
    
    % CF,PF overlap area when CF-IN2 is present
    y_cf_truncated2 = rect(y_cf + y_in_total_present_delay, 1);
    y_cf_shapes2(i,:) = y_cf_truncated2;
    area_union = trapz(max(y_pf, y_cf_truncated2));
    A1 = rect(y_pf - y_cf_truncated2, 1);
    A2 = rect(y_cf_truncated2 - y_pf, 1);
    area_btwn_two_curves = trapz(A1) + trapz(A2);
    overlap_area2 = area_union - area_btwn_two_curves;
    overlap_area_present(i) = overlap_area2;  
    
% --------------------------------------------------------------------------------------------------------------------------------    
    % Example plot showing PF timing when CF-IN2 is absent   
    f1=figure('Position',[400 500 600 800]);
    subplot('position', [0.13 0.86 1-0.26 0.06]); set(gcf,'color','w');
    arrow_tail = 0.9;
    arrow_head = 0.862; 
    arrow_fontsize = 14;
    
    if ismember(1, active_pf)
        xx = (timing_pf(1)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
        annotation('line',[xx,xx],[arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [250,70,70]/255);
        %annotation('textarrow', [xx ,xx],[arrow_tail, arrow_head],'String', '1', 'FontSize',arrow_fontsize ,'LineWidth',2,'Color', [160,80,160]/255);
    end
    if ismember(2,active_pf)
        xx = (timing_pf(2)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
        annotation('line',[xx,xx],[arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [60,110,220]/255);
    %   annotation('textarrow', [xx,xx],[arrow_tail, arrow_head],'String', '2', 'FontSize',arrow_fontsize ,'LineWidth',2,'Color', [160,80,160]/255);
    end
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
    annotation('line', [xx,xx], [arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [170,80,170]/255);
    xx = (abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
    annotation('line', [xx,xx], [arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [240,160,20]/255);     
    xlim([min(t2),max(t2)]);     set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   % ylabel('Timing');   
 
    ylim_magnitude = 0.9; 
         
    % CF & PF
    subplot('position', [0.13 0.70 1-0.26 0.14]);
    plot(t,y_pf, 'LineWidth',2, 'Color', [150,75,150]/255);  hold on;
    plot(t,y_cf, 'LineWidth',2, 'Color', [240,160,20]/255);        
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.73, 0.71], 'LineWidth', 2, 'Color', [170,80,170]/255);  
    xx = (abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.73, 0.71], 'LineWidth', 2, 'Color', [240,160,20]/255);     
    xlim([min(t2),max(t2)]); ylim([-0.3, 0.7]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('CF & PF');  
    
    % IN2
    subplot('position', [0.13 0.54 1-0.26 0.14]);    
    plot(t,-y_in_absent(2,:), 'LineWidth',2,'Color',[60,110,220]/255);
    xx = (timing_pf(2)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.57, 0.55], 'LineWidth', 2, 'Color', [60,110,220]/255);    
    xlim([min(t2),max(t2)]); ylim([-0.3, 0.7]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('IN2');       

    % IN1
    subplot('position', [0.13 0.34 1-0.26 0.18]);     
    plot(t,y_in2_absent_delay(1,:), 'LineWidth',2,'Color',[60,110,220]/255); hold on;
    plot(t,-y_in_absent(1,:), 'LineWidth',2,'Color', [255,60,60]/255);     
    xx = (timing_pf(1)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.37, 0.35], 'LineWidth', 2, 'Color', [250,60,60]/255);  
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.37, 0.35], 'LineWidth', 2, 'Color', [170,80,170]/255);      
    xlim([min(t2),max(t2)]); ylim([-ylim_magnitude, ylim_magnitude]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('IN1');    
    
    % PC
    subplot('position', [0.13 0.1 1-0.26 0.22]);
    pgon_pf = polyshape(t, y_pf);
    pgon_cf = polyshape(t, y_cf_truncated1);
    plot(intersect(pgon_pf, pgon_cf), 'EdgeColor', 'none', 'FaceColor', [132,132,132]/255);    hold on;
    p3=plot(t,y_in_total_absent_delay, '--',  'LineWidth',1, 'Color', [255,60,60]/255); 
    p4=plot(t,y_pf, 'LineWidth',2, 'Color', [150,75,150]/255);    
    p5=plot(t,y_cf_truncated1, 'LineWidth',3, 'Color', [240,160,20]/255);
    p1=plot(t,y_cf, ':',  'LineWidth',2, 'Color', [240,160,20]/255);    
    set(gca,'FontSize',14, 'ytick',[]);  xlabel('time'); ylabel('PC'); 
    xlim([min(t2),max(t2)]); ylim([-ylim_magnitude+0.2, ylim_magnitude-0.3]);     
    sgtitle(['CF-IN2 absent'], 'FontSize',15);

% --------------------------------------------------------------------------------------------------------------------------------    
    % Example plot showing PF timing when CF-IN2 is present
    f2=figure('Position',[1500 500 600 800]);
    subplot('position', [0.13 0.86 1-0.26 0.06]); set(gcf,'color','w');
    
    if ismember(1, active_pf)
        xx = (timing_pf(1)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
        annotation('line',[xx,xx],[arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [250,70,70]/255);
        %annotation('textarrow', [xx ,xx],[arrow_tail, arrow_head],'String', '1', 'FontSize',arrow_fontsize ,'LineWidth',2,'Color', [160,80,160]/255);
    end
    if ismember(2,active_pf)
        xx = (timing_pf(2)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
        annotation('line',[xx,xx],[arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [60,110,220]/255);
    %   annotation('textarrow', [xx,xx],[arrow_tail, arrow_head],'String', '2', 'FontSize',arrow_fontsize ,'LineWidth',2,'Color', [160,80,160]/255);
    end
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
    annotation('line', [xx,xx], [arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [170,80,170]/255);
    xx = (abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13; 
    annotation('line', [xx,xx], [arrow_tail, arrow_head], 'LineWidth', 2, 'Color', [240,160,20]/255);     
    xlim([min(t2),max(t2)]);     set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   % ylabel('Timing');   
 
   
    % CF & PF
    subplot('position', [0.13 0.70 1-0.26 0.14]);
    plot(t,y_pf, 'LineWidth',2, 'Color', [150,75,150]/255);  hold on;
    plot(t,y_cf, 'LineWidth',2, 'Color', [240,160,20]/255);    
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.73, 0.71], 'LineWidth', 2, 'Color', [170,80,170]/255);  
    xx = (abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.73, 0.71], 'LineWidth', 2, 'Color', [240,160,20]/255);      
    xlim([min(t2),max(t2)]); ylim([-0.3, 0.7]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('CF & PF');  
    
    % IN2
    subplot('position', [0.13 0.54 1-0.26 0.14]);    
    plot(t,-y_in_present(2,:), 'LineWidth',2,'Color',[60,110,220]/255);
    xx = (timing_pf(2)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.57, 0.55], 'LineWidth', 2, 'Color', [60,110,220]/255);  
    xx = (abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.57, 0.55], 'LineWidth', 2, 'Color', [240,160,20]/255);         
    xlim([min(t2),max(t2)]); ylim([-0.3, 0.7]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('IN2');     
    
    % IN1
    subplot('position', [0.13 0.34 1-0.26 0.18]);     
    plot(t,y_in_present_delay(1,:),'LineWidth',2,'Color',[60,110,220]/255);  hold on;
    plot(t,-y_in_present(1,:), 'LineWidth',2,'Color', [255,60,60]/255); 
    xx = (timing_pf(1)+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.37, 0.35], 'LineWidth', 2, 'Color', [250,60,60]/255);  
    xx = (2.5+abs(min(t2)))/(max(t2)-min(t2))*0.74+0.13;
    annotation('line', [xx,xx], [0.37, 0.35], 'LineWidth', 2, 'Color', [170,80,170]/255);     
    xlim([min(t2),max(t2)]); ylim([-ylim_magnitude, ylim_magnitude]); 
    set(gca,'FontSize',14, 'xtick',[], 'ytick',[]);   ylabel('IN1');      
    
    % PC
    subplot('position', [0.13 0.1 1-0.26 0.22]);
    pgon_pf = polyshape(t, y_pf);
    pgon_cf = polyshape(t, y_cf_truncated2);
    plot(intersect(pgon_pf, pgon_cf), 'EdgeColor', 'none', 'FaceColor', [132,132,132]/255);hold on;
    p3=plot(t,y_in_total_present_delay, '--',  'LineWidth',1, 'Color', [255,60,60]/255); 
    p4=plot(t,y_pf, 'LineWidth',2, 'Color', [150,75,150]/255);    
    p5=plot(t,y_cf_truncated2, 'LineWidth',3, 'Color', [240,160,20]/255);
    p1=plot(t,y_cf, ':',  'LineWidth',2, 'Color', [240,160,20]/255);
    set(gca,'FontSize',14, 'ytick',[]);  xlabel('time'); ylabel('PC'); 
    xlim([min(t2),max(t2)]); ylim([-ylim_magnitude+0.2, ylim_magnitude-0.3]);     
    sgtitle(['CF-IN2 present'], 'FontSize',15);    
    
    
end
%}

%% Marr-Albus model illustration
%{
tt = -5:0.1:40;
yy_cf = double_exp(tt, 1, -1, 8, 2);
yy_pf = double_exp(tt-2.5, 1, -1, 2, 0.5);
yy_cf_inhib = 0.2*double_exp(tt, 1, -1, 8, 2);
fma = figure('Position',[300,100,700,400]);
pgon_pf = polyshape(tt, yy_pf);
pgon_cf = polyshape(tt, yy_cf);
pgon_cf_inhib = polyshape(tt, yy_cf_inhib);
plot(intersect(pgon_pf, pgon_cf), 'EdgeColor', 'none', 'FaceColor', [132,132,132]/255);    hold on;
plot(intersect(pgon_pf, pgon_cf_inhib), 'EdgeColor', 'none', 'FaceColor', [64,64,64]/255);
plot(tt,yy_pf,'LineWidth',3, 'Color', [160,70,160]/255); hold on;
plot(tt,yy_cf,':', 'LineWidth',3, 'Color', [240,140,10]/255);
plot(tt,yy_cf_inhib,  'LineWidth', 3,'Color',[240,140,10]/255);
set(gcf,'color','w'); set(gca,'FontSize',15,'xtick',[], 'ytick',[]); 
ylim([0,0.5]); xlabel('time'); xlim([min(tt), max(tt)]);
title('Marr-Albus');
%}
%% function

function y = double_exp2(x, peak, tau1, tau2, t1, t2)
    x_rise = x(x>t1);
    x_pre_rise = x(x<=t1);
    x_rise = x_rise(x_rise<=t2);
    x_fall = x(x>t2);
    
    y_pre = x_pre_rise * 0;
    y_rise = peak * ( 1 - exp(-1*(x_rise-t1)/tau1));
    y_fall = peak * (exp(-1*(x_fall-t2)/tau2) - exp(-1*(x_fall-t1)/tau1));    
    y = [y_pre, y_rise, y_fall];    
end

function y = rect(x, dir)
    if dir > 0
        x(x<0) = 0;
    elseif dir < 0 
        x(x>0) = 0;
    end
    y = x;
end

function y = double_exp(x, A, B, a, b)
    y = A*exp(-1 * x/a) + B*exp(-1* x/b);

    if a > b
        y(y<0) = 0;
    else
        y(y>0) = 0;
    end
end
