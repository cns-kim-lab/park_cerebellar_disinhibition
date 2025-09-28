
% sfig 2c
a1= [54,46,0];  % CF random
a2= [90,10,0];  
a3= [96,0,4];  
a4= [10,90,0];   % PF random syn-o vs syn-r
a5= [84,16,0];  % nsyn-o vs nsyn-r
a6= [91,0,9];   % syn-r vs nsyn-r

colors = [255,255,255; 100,100,100; 200,200,200]/255;
f3f=figure('Position', [100 100 400 600]);
h= bar([a1;a2;a3;a4;a5;a6], 'stacked');
for i = 1:numel(h)
    h(i).FaceColor = colors(i,:);
end
ylim([0,120]);
set(gcf,'color','w');
set(gca,'FontSize',22);
legend({'Obs = Rand', 'Obs < Rand', 'Obs > Rand'}, 'Location', 'north','Orientation', 'horizontal');
ylabel('#Trials');
xticks(1:6);
xticklabels({'Syn-o vs Syn-r', 'Nsyn-o vs Nsyn-r', 'Syn-r vs Nsyn-r', 'Syn-o vs Syn-r', 'Nsyn-o vs Nsyn-r', 'Syn-r vs Nsyn-r'})
save_figure(f3f, 'sfig2c','svg');


% sfig 2e
a1= [63,37,0];  % CF random
a2= [87,13,0];  
a3= [86,0,14];  
a4= [45,55,0];   % PF random syn-o vs syn-r
a5= [48,52,0];  % nsyn-o vs nsyn-r
a6= [92,0,8];   % syn-r vs nsyn-r

colors = [255,255,255; 100,100,100; 200,200,200]/255;
f3f=figure('Position', [100 100 400 600]);
h= bar([a1;a2;a3;a4;a5;a6], 'stacked');
for i = 1:numel(h)
    h(i).FaceColor = colors(i,:);
end
ylim([0,120]);
set(gcf,'color','w');
set(gca,'FontSize',22);
legend({'Obs = Rand', 'Obs < Rand', 'Obs > Rand'}, 'Location', 'north','Orientation', 'horizontal');
ylabel('#Trials');
xticks(1:6);
xticklabels({'IN1-o vs IN1-r', 'IN2-o vs IN2-r', 'IN1-r vs IN2-r', 'IN1-o vs IN1-r', 'IN2-o vs IN2-r', 'IN1-r vs IN2-r'})
save_figure(f3f, 'sfig2e','svg');
