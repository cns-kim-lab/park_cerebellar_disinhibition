load('/data/research/cjpark147/conn_analysis/selected_cell_ids.mat');
load('/data/research/cjpark147/code/conn/mat/cfin_syn_id_order.mat');

in_ids = [in1_ids; in2_ids];
syn_info = get_syn_info('cf',in_ids);
ws = 110;
vol_size = [14592, 10240, 1024];
red = zeros(1,1,3);
red(1,1,1) = 0.99;  red(1,1,2) = 0.1;  red(1,1,3) = 0.1;

%cfpc_offdiag_point = [893001,8719,2508,377; 894720,8644,2576,605; 896971,8492,2481,902];
%cf772_merge_point = [772, 8661,2547,739];
cfin1_points = [95329,10277,3013,524; 148992,11804,2417,541; 437369,3384,2050,705; 515513,4308,1062,186; 709443,6613,1741,220];
center_points = cfin1_points;

% CF-IN manuscript extended figure 
cfin_info = readtable('/data/research/cjpark147/lrrtm3_wt_syn/cfin_syn_info_min6_fix_pos.txt');
center_points = [cfin_info.intf_id, cfin_info.contact_x, cfin_info.contact_y, cfin_info.contact_z];
skip_idx = find(~ismember(cfin_info.seg_pre, cf_ids));
[npoint,~] = size(cfin_syn_id_order);
page_counter =1 ;

% CF-IN synapse scores
scores = readtable('/data/research/cjpark147/lrrtm3_wt_syn/cfin_syn_scores.csv');
mu1 = mean(scores.person3);
mu2 = mean(scores.person1);
mu3 = mean(scores.person2);
mu4 = mean(scores.person4);
mu_avg = mean([mu1,mu2,mu3,mu4]);
for i = 1:npoint
%for i = 1:1
        idx = find(center_points(:,1) == cfin_syn_id_order(i));
        xc = center_points(idx,2);   yc = center_points(idx,3);    zc = center_points(idx,4);
        xc1 = max(xc - ws, 1);  xc2 = min(xc + ws, 14592);
        yc1 = max(yc - ws, 1);  yc2 = min(yc + ws, 10240);
        zc1 = max(zc - 5 , 1);   zc2 = min(zc + 5, 1024); 
        chan = h5read('/data/lrrtm3_wt_reconstruction/channel.h5', '/main', [xc1,yc1,zc1], [xc2-xc1+1, yc2-yc1+1, zc2-zc1+1]);     
        chan = permute(chan, [2,1,3]);
        
        this_intf = center_points(idx,1); idx2 = find(scores.intf_id == this_intf );
        this_score = [scores.person3(idx2), scores.person1(idx2), scores.person2(idx2), scores.person4(idx2)];
        mean_score = mean(this_score);        
        score_plot = [mean_score, 0, this_score];
        ftile = figure('Position',[100 100 1000 800]);
        set(gcf,'Color','w');
        tile = tiledlayout(3, 4, 'Padding','none', 'TileSpacing', 'compact');

        for j = 1:11
            ax=nexttile(tile);
            chan_gray = repmat(mat2gray(chan(:, :, j),[0,255]),[1,1,3]);           
            %{
            if ismember(j,[6]) % draw arrow
                chan_gray(ws,ws,:) = repmat(red,[1,1,1]);
                chan_gray(ws-1:ws+1, ws-1, :) = repmat(red,[3,1,1]);
                chan_gray(ws-2:ws+2, ws-2, : ) =repmat(red,[5,1,1]);
                chan_gray(ws-3:ws+3, ws-4:ws-3, :) =repmat(red,[7,2,1]);
                chan_gray(ws-4:ws+4, ws-5, :) = repmat(red,[9,1,1]);
                chan_gray(ws-1:ws,ws-12:ws-6,:) = repmat(red,[2,7,1]);            
            end
            %}
            if ismember(j,[6]) % point mark of syn
                chan_gray(ws-3:ws+3,ws-3:ws+3,:) = repmat(red,[7,7,1]);        
            end
            image(chan_gray); 
            
            if j < 6
                title(['z - ', num2str(6-j)],'FontSize',12); 
            elseif j > 6
                title(['z + ', num2str(j-6)],'FontSize',12); 
            else
                title('z','FontSize',12); 
            end
                
            set(gca,'xtick',[]); set(gca,'ytick',[]);        
            daspect(ax, [1 1 1]);
        end
        ax=nexttile(tile);
        b=bar(score_plot, 'BarWidth', 0.8, 'FaceColor',[70,45,70]/255); hold on;     
        b.FaceColor = 'flat'; b.CData(1,:) = [240,150,30]/255;

        ylabel('Score'); 
        set(gcf,'color','w'); set(gca,'FontSize',12, 'XTickLabel', {'AVG','','1','2','3','4'});
        plot([0.5,1.5],[mu_avg,mu_avg],'LineWidth',2.2,'Color',[245,70,70]/255 );
        plot([2.5,3.5],[mu1,mu1],'LineWidth',2.2,'Color',[245,70,70]/255 );
        plot([3.5,4.5],[mu2,mu2],'LineWidth',2.2,'Color',[245,70,70]/255 );
        plot([4.5,5.5],[mu3,mu3],'LineWidth',2.2,'Color',[245,70,70]/255 );
        plot([5.5,6.5],[mu4,mu4],'LineWidth',2.2,'Color',[245,70,70]/255 );
        daspect(ax, [1.6 1 1]);        
        
        title(tile, [num2str(center_points(idx,2)),', ', num2str(center_points(idx,3)),', ',num2str(center_points(idx,4))]);
        %title(tile, num2str(center_points(i,1)));
        %imwrite(getframe(gca).cdata, '/data/research/cjpark147/figure/test_01.tif');
%}        
        fprintf('%d..%d\n', i,this_intf);
        
        %{
        if page_counter == 2
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',9)],'pdf');
        elseif page_counter == 3 
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',45)],'pdf');
        elseif page_counter == 10
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',48)],'pdf');
        elseif page_counter == 9            
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',2)],'pdf');
        elseif page_counter == 45            
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',3)],'pdf');
        elseif page_counter == 48            
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',10)],'pdf');
        else
            %save_figure(ftile, ['/cfin_syn_list/aa',sprintf('%d',page_counter)],'pdf');
        end
        page_counter = page_counter + 1; 
        %}
        save_figure(ftile, ['/cfin_syn_list/cfin_syn',sprintf('%d',i)],'pdf');
        close all;
        %}       
        
end






center_points = [...
5420,10062,317,390; 
6385,9742,818,687; 
6790,9784,188,977;
13189,9118,1875,602;
23723,9038,2852,862;
28705,9671,3465,330;
38863,10116,4669,297;
40910,9405,4622,565;
47548,9239,5557,432;
95329,10274,3020,523;
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
312489,1472,5754,838;
324639,1228,7851,621;
330169,1645,8160,629;
332126,3001,9750,231;
332127,2685,9061,264;
341140,3304,1389,366;
341140,3434,1443,380;
356677,2241,3106,186;
391057,2691,6373,799;
423238,3446,1614,195;
425681,3475,2056,470;
425682,3866,1991,460;
437369,3389,2048,705;
446072,3788,3736,430;
448895,3833,3744,557;
460244,3943,4393,553;
491183,3614,7670,295;
498421,3978,8204,276;
508996,4321,9480,258;
515513,4308,1062,186;
532319,4523,2795,447;
556948,5120,4174,732;
566982,4469,5661,324;
596991,4412,8095,512;
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
917860,8283,5387,156;
949726,8668,2878,903;
];
%{
center_points = [...
5420,10062,317,390; 
5421,9792,486,368; @
6385,9742,818,687; 
6790,9784,188,977;
7089,9613,1108,214;@
13189,9118,1875,602;
15730,9774,2493,198;@
23723,9038,2852,862;
28705,9671,3465,330;
38863,10116,4669,297;
40910,9405,4622,565;
47548,9239,5557,432;
67091,9097,7751,493;@
95329,10274,3020,523;
95843,10425,2251,651;@
96427,10717,3447,569;
96428,10466,2715,746;@
96511,10365,2936,545;
96511,10590,2561,552;
104947,10979,3788,898;@
108331,11004,4859,322;
108377,10319,4573,311;
115100,10888,5443,311;
119046,10624,6281,150;@
121565,10480,6426,310;@
126884,10713,7168,452;
142123,11339,1170,365;@
148992,11812,2399,538;
150314,11966,2716,618;
150316,11934,2537,641;@
150317,12061,2753,596;
162087,11113,4227,650;@
200848,13005,2315,655;
206534,12100,3139,613;
286099,1891,3014,204;@
296845,1287,3234,581;
296968,2086,3871,620;@
302844,1344,4424,568;
309004,2022,5969,408;@
312489,1472,5754,838;
321403,1827,7685,9; @
322987,1597,7870,369; @
322988,1637,7687,377; @
324639,1228,7851,621;
324640,1413,7911,612;@
330169,1645,8160,629;
332126,3001,9750,231;
332127,2685,9061,264;
333158,2252,9083,603;@
341140,3304,1389,366;
341140,3434,1443,380;
346869,2255,2297,248;@
346982,2227,2860,199;@
356677,2241,3106,186;
368790,2844,4387,552;@
391057,2691,6373,799;
405857,2545,8429,247;@
423238,3446,1614,195;
425681,3475,2056,470;
425682,3866,1991,460;
437368,3668,2784,684;@
437369,3389,2048,705;
445109,3549,3173,352;@
446072,3788,3736,430;
448895,3833,3744,557;
448896,4015,3297,573;@
460244,3943,4393,553;
460457,3145,4540,581;@
480688,3828,6355,339;@
491183,3614,7670,295;
498421,3978,8204,276;
508996,4321,9480,258;
510636,4765,9358,291;@
515513,4308,1062,186;
532319,4523,2795,447;
532462,4980,2914,392;@
556948,5120,4174,732;
566982,4469,5661,324;
587192,4829,7875,463;@
596991,4412,8095,512;
610075,5150,267,236;@
613075,5199,908,520;
618936,5560,1686,414;@
618937,5443,1522,429;@
621054,5084,1430,565;
633423,5729,2400,799;@
653805,5907,4114,632;@
698666,6387,9181,199;@
708726,6967,752,862;@
709043,6967,1268,234;@
709443,6613,1741,220;
709445,6637,1625,203;@
711864,6782,1453,364;
722020,6136,2164,419;
737371,6615,3725,875;
743353,6490,5050,541;@
743354,6739,4793,587;@
744147,6652,4546,637;@
746298,6784,4924,799;
746300,6688,4894,812;@
754243,6835,5587,557;@
780181,6439,8665,199;@
787584,7511,8947,72;@
795109,8090,1049,414;@
795604,7282,494,391;
795605,7594,955,402;
798281,7081,1269,236;@
806816,7926,2647,251;@
806917,7951,2595,236;@
810530,7772,2978,430;@
817122,7446,3305,209;@
820539,7609,3364,411;
834398,7311,4731,543;@
842456,7595,5588,550;
847586,7413,6924,63;@
859161,7404,7108,434;
864503,7315,7490,872;@
864848,7268,7886,804;@
867215,7056,8433,76;@
874373,8734,9075,216;
879529,8617,979,403;
879530,8658,992,409;
887172,8184,1857,753;
896190,8700,2570,770;
917859,8160,5418,262;@
917860,8277,5422,137;@
917860,8283,5387,156;
922225,8379,5293,577;@
937472,8101,7206,519;@
943677,8725,8670,254;@
949726,8668,2878,903;
];
%}

%{

center_points = [...
5420,10062,317,390;
5421,9792,486,368;
6385,9742,818,687;
6790,9784,188,977;
7089,9613,1108,214;
13189,9118,1875,602;
15730,9774,2493,198;
23723,9038,2852,862;
28705,9671,3465,330;
38863,10116,4669,297;
40910,9405,4622,565;
47548,9239,5557,432;
67091,9097,7751,493;
95329,10274,3020,523;
95843,10425,2251,651;
96427,10717,3447,569;
96428,10466,2715,746;
96511,10365,2936,545;
96511,10590,2561,552;
104947,10979,3788,898;
108331,11004,4859,322;
108377,10319,4573,311;
115100,10888,5443,311;
119046,10624,6281,150;
121565,10480,6426,310;
126884,10713,7168,452;
142123,11339,1170,365;
148992,11812,2399,538;
150314,11966,2716,618;
150316,11934,2537,641;
150317,12061,2753,596;
162087,11113,4227,650;
200848,13005,2315,655;
206534,12100,3139,613;
286099,1891,3014,204;
296845,1287,3234,581;
296968,2086,3871,620;
302844,1344,4424,568;
309004,2022,5969,408;
312489,1472,5754,838;
321403,1827,7685,9;
322987,1597,7870,369;
322988,1637,7687,377;
324639,1228,7851,621;
324640,1413,7911,612;
330169,1645,8160,629;
332126,3001,9750,231;
332127,2685,9061,264;
333158,2252,9083,603;
341140,3304,1389,366;
341140,3434,1443,380;
346869,2255,2297,248;
346982,2227,2860,199;
356677,2241,3106,186;
368790,2844,4387,552;
391057,2691,6373,799;
405857,2545,8429,247;
423238,3446,1614,195;
425681,3475,2056,470;
425682,3866,1991,460;
437368,3668,2784,684;
437369,3389,2048,705;
445109,3549,3173,352;
446072,3788,3736,430;
448895,3833,3744,557;
448896,4015,3297,573;
460244,3943,4393,553;
460457,3145,4540,581;
480688,3828,6355,339;
491183,3614,7670,295;
498421,3978,8204,276;
508996,4321,9480,258;
510636,4765,9358,291;
515513,4308,1062,186;
532319,4523,2795,447;
532462,4980,2914,392;
556948,5120,4174,732;
566982,4469,5661,324;
587192,4829,7875,463;
596991,4412,8095,512;
610075,5150,267,236;
613075,5199,908,520;
618936,5560,1686,414;
618937,5443,1522,429;
621054,5084,1430,565;
633423,5729,2400,799;
653805,5907,4114,632;
698666,6387,9181,199;
708726,6967,752,862;
709043,6967,1268,234;
709443,6613,1741,220;
709445,6637,1625,203;
711864,6782,1453,364;
722020,6136,2164,419;
737371,6615,3725,875;
743353,6490,5050,541;
743354,6739,4793,587;
744147,6652,4546,637;
746298,6784,4924,799;
746300,6688,4894,812;
754243,6835,5587,557;
780181,6439,8665,199;
787584,7511,8947,72;
795109,8090,1049,414;
795604,7282,494,391;
795605,7594,955,402;
798281,7081,1269,236;
806816,7926,2647,251;
806917,7951,2595,236;
810530,7772,2978,430;
817122,7446,3305,209;
820539,7609,3364,411;
834398,7311,4731,543;
842456,7595,5588,550;
847586,7413,6924,63;
859161,7404,7108,434;
864503,7315,7490,872;
864848,7268,7886,804;
867215,7056,8433,76;
874373,8734,9075,216;
879529,8617,979,403;
879530,8658,992,409;
887172,8184,1857,753;
896190,8700,2570,770;
917859,8160,5418,262;
917860,8277,5422,137;
917860,8283,5387,156;
922225,8379,5293,577;
937472,8101,7206,519;
943677,8725,8670,254;
949726,8668,2878,903;
];

%}









