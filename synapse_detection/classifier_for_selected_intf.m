
addpath /data/research/cjpark147/code/matlab/mysql/
tic;

% lrrtm3
vol_size = [14592, 10240, 1024];
cleftprob_path = '/data/lrrtm3_wt_syn/assembly/assembly_cleft_prob_210503.h5';
vesicle_path = '/data/lrrtm3_wt_syn/assembly/vesicle_segmentation_210503_quick.h5';
intf_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_fixed_210503.h5';
seg_path = '/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_210503.h5';
%load('/data/lrrtm3_wt_syn/interface_relevant_info.mat');
%load('/data/lrrtm3_wt_syn/mat_data/cleft_detector_svm.mat');
load('/data/research/cjpark147/code/synapse_detection/mat_data/cleft_detector_svm_train.mat');
SVMModel = SVM_model_train;
load('/data/lrrtm3_wt_syn/assembly/mat_data/bbox_fixed');
omni_db_name = 'omni_20210503';


fid = fopen('/data/lrrtm3_wt_syn/synapse_det_info_raw_select.txt','w');
fid2 = fopen('/data/lrrtm3_wt_syn/interface_info_210503_select.txt','w');
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','intf_id', 'pre_post_ambiguity','seg_pre', 'seg_post', 'type_pre', 'type_post', ...
    'size_iso_mip0', 'contact_x', 'contact_y','contact_z','stp_x', 'stp_y', 'stp_z', 'stride_x', 'stride_y','stride_z');
fprintf(fid2,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','intf_id', 'seg_id1', 'seg_id2',  'type1', 'type2', ...
    'size_iso_mip0', 'contact_x', 'contact_y','contact_z','stp_x', 'stp_y', 'stp_z', 'stride_x', 'stride_y','stride_z');
celltype_map = cell(7,1);
celltype_map{1} = 'pc';
celltype_map{2} = 'pf';
celltype_map{3} = 'cf';
celltype_map{4} = 'in';
celltype_map{5} = 'gl';
celltype_map{6} = 'go';
celltype_map{7} = 'ud';

load_limit = 1024*1024*1024;
thickness = 2;              % interface thickness
intf_size_th = 200;         % interface size threshold
vc_dist = 5;               % vesicle-interface distance threshold
z_scaling = 4;
pointPrctile = 95;
upperPrctile = 99;
lowerPrctile = 85;
highProb = 0.9;
svm_theta = -0.1;     % 0.95 precision & 0.95 recall

%[row,~] = size(interface_info);

intf_ids = find(bbox_fixed(:,1));
bbox_load = bbox_fixed(:,4) .* bbox_fixed(:,5) .* bbox_fixed(:,6);
intf_ids_within_limit = [282120;296265;379603;282118;392787];

[row,~] = size(intf_ids);
predictions = zeros(row,1) ; % 1: negative  2: positive
seg_id_info = zeros(row,2);
cell_type_info = zeros(row,2);
intf_size_info = zeros(row,1);
bbox_info = zeros(row,6);
intf_id_info = zeros(row,1);
contact_info = zeros(row,3);
pre_post_ambiguity = zeros(row,1);      % 0: unambiguous    1: ambiguous

endpoint = numel(intf_ids_within_limit);
halfpoint = floor(numel(intf_ids_within_limit)/2);
startpoint = 1;

%% Start classification

for ridx=startpoint:halfpoint
 
    stp = max([1,1,1], [bbox_fixed(intf_ids_within_limit(ridx),1:2) - vc_dist,  bbox_fixed(intf_ids_within_limit(ridx),3) - ceil(vc_dist/z_scaling) ]);   % bbox x,y,z
    enp = min(vol_size, stp - [1,1,1] + [bbox_fixed(intf_ids_within_limit(ridx),4:5) + vc_dist *2, bbox_fixed(intf_ids_within_limit(ridx),6) + ceil(vc_dist/z_scaling)*2]);
    num_elem = enp - stp + 1;
    cleft_net_output = h5read(cleftprob_path, '/main', stp, num_elem);
    intf_vol = h5read(intf_path, '/main', stp, num_elem);
    cells_segment_vol = h5read(seg_path, '/main', stp, num_elem);
    vesicle_seg_vol = h5read(vesicle_path, '/main', stp, num_elem);
    vesicle_seg_vol = vesicle_seg_vol .* uint32(cells_segment_vol > 0 );
    
    intf_idx = find(intf_vol == intf_ids_within_limit(ridx));    
    cprob = cleft_net_output(intf_idx);
    
    % compute intf sizes
    intf_vol_iso_mip0 = imresize3(intf_vol,'Scale', [1,1,4],'Method', 'nearest');
    intf_size_iso_mip0 = round(numel(find(intf_vol_iso_mip0 == intf_ids_within_limit(ridx)))/2);    
    intf_size_info(ridx,1) = intf_size_iso_mip0;
    intf_size = numel(intf_idx);
    intf_id_info(ridx,1) = intf_ids_within_limit(ridx);
    
    % svm classifier
    if (intf_size > intf_size_th)
        prct = prctile(cprob, pointPrctile);
        interprct = prctile(cprob, upperPrctile) - prctile(cprob, lowerPrctile);
        [~,score] = predict(SVMModel, [prct, interprct]);
        label = double(score(:,2) > svm_theta) + 1;             
        predictions(ridx,1) = label;    % nonsyn(1), syn(2)
        bbox_info(ridx,:) = [stp, num_elem];
    end
    
    % very large interfaces
    if sum(cprob > highProb, 'all') > (intf_size_th *2)
        predictions(ridx,1) = 2;
        bbox_info(ridx,:) = [stp, num_elem];
    end
    
    % get seg id and cell type
    h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
    rtn = mysql(h_sql, ['use ', omni_db_name]);
    
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
    

    if predictions(ridx,1) == 2
        % match vesicle segments.   cell types { 1-PC, 2-PF, 3-CF, 4-IN, 5-GLI, 6-GOL} 
        vc_seg_match = extract_gtsegid_of_vc(vesicle_seg_vol, cells_segment_vol);
        if ~isempty(vc_seg_match)
            vc_seg_match_vc = vc_seg_match(:,1);   vc_seg_match_seg = vc_seg_match(:,2);
            se = strel('sphere',1);
            bw_vc = vesicle_seg_vol > 0;
            bw_vc = imerode(bw_vc, se);
            vc_surf = (uint32(vesicle_seg_vol) .* uint32(~bw_vc));
   %{     
            % to be deleted
            h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
            rtn = mysql(h_sql, ['use ', omni_db_name]);
            
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
            %}
            [ix,iy,iz] = ind2sub(size(intf_vol), find(intf_vol == intf_ids_within_limit(ridx)));
            
            nearest_vc1 = 0; nearest_vc2 = 0;
            dist = 1000;  dist2 = 1000;
            contact_size = 0;  contact_size2 = 0;
            contact_loc2 = -1000; % to avoid warning msg
            
            if ismember(cell_type1, [2,3,4])
                vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id1);
                if numel(vc_of_seg) > 0
                    [vc_id, dist, contact_size, contact_loc] = get_nearest_vc(vc_surf, vc_of_seg, ix, iy, iz);
                    
                    contact_info(ridx,:) = contact_loc + stp - 1;
                end
            end
            
            if ismember(cell_type2, [2,3,4])
                vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id2);
                if numel(vc_of_seg) > 0
                    [vc_id2, dist2, contact_size2, contact_loc2] = get_nearest_vc(vc_surf, vc_of_seg, ix, iy, iz);
                end
            end
            
            if dist > vc_dist && dist2 > vc_dist                        % if no vesicle exists within vc_dist from intf
                predictions(ridx,1) = 1;                                % predict value 1
                
            elseif dist <= vc_dist && dist2 <= vc_dist                    % if both seg have vc within vc_dist
                % there is a chance that both segments have vc 
                % which cause ambiguous pre/post synapse decisions.
                pre_post_ambiguity(ridx,1) = 1;
                if contact_size >= contact_size2        % if vc in seg1 has larger contacts
                    % do nothing
                elseif contact_size < contact_size2    % if vc in seg2 has larger contacts
                    seg_id_info(ridx,:) = [seg_id2, seg_id1];             % swap seg id positions
                    cell_type_info(ridx,:) = [cell_type2, cell_type1];    % swap cell type positions
                    contact_info(ridx,:) = contact_loc2 + stp - 1;
                end
                
            elseif dist2 <= vc_dist                                      % if vc in seg2 is within vc_dist and vc in seg1 is not within vc_dist.
                seg_id_info(ridx,:) = [seg_id2, seg_id1];                 % swap seg id positions
                cell_type_info(ridx,:) = [cell_type2, cell_type1];        % swap cell type positions
                contact_info(ridx,:) = contact_loc2 + stp - 1;
            end
        else                            % if vc doesn't exist
            predictions(ridx,1) = 1;
        end
    end
        
end


%%  Half point reached: save!

synapse_info_tbl = [intf_id_info, seg_id_info, cell_type_info, intf_size_info, contact_info, bbox_info];
save('/data/lrrtm3_wt_syn/mat_data/synapse_info_tbl_select.mat', 'synapse_info_tbl');


for i =startpoint:halfpoint
%for i = 1:numel(intf_ids_within_limit)

    val1 = cell_type_info(i,1);
    val2 = cell_type_info(i,2);
    fprintf(fid2, '%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', intf_id_info(i,1), seg_id_info(i,:), celltype_map{val1}, celltype_map{val2}, ...
            intf_size_info(i,1), contact_info(i,:), bbox_info(i,:));

    if predictions(i,1) == 2
        fprintf(fid, '%d,%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',intf_id_info(i,1), pre_post_ambiguity(i,1), seg_id_info(i,:), ...
            celltype_map{val1}, celltype_map{val2}, intf_size_info(i,1), contact_info(i,:), bbox_info(i,:));
    end
end

%nonsynapses = intf_ids(~ismember(intf_ids, synapses));
%save('/ldata/lrrtm3_wt_syn/synapse_ids.mat', 'synapses');
%save('/ldata/lrrtm3_wt_syn/nonsynapse_ids.mat', 'nonsynapses');
%save('/data/lrrtm3_wt_syn/pre_post_ambiguity.mat', 'pre_post_ambiguity');
save('/data/lrrtm3_wt_syn/mat_data/predictions.mat', 'predictions');


fprintf('\n **************************************************************** ' );
fprintf('\n Checkpoint: 1/2 of all interfaces classified  \n');
fprintf('\n **************************************************************** ' );

%fprintf('%s %d\n', 'classifying intfs beyond load limit...  N = ', numel(intf_ids_beyond_limit));
toc;

%}

%% Do classification for the last half

for ridx=(halfpoint+1):endpoint
  
    stp = max([1,1,1], [bbox_fixed(intf_ids_within_limit(ridx),1:2) - vc_dist,  bbox_fixed(intf_ids_within_limit(ridx),3) - ceil(vc_dist/z_scaling) ]);   % bbox x,y,z
    enp = min(vol_size, stp - [1,1,1] + [bbox_fixed(intf_ids_within_limit(ridx),4:5) + vc_dist *2, bbox_fixed(intf_ids_within_limit(ridx),6) + ceil(vc_dist/z_scaling)*2]);
    num_elem = enp - stp + 1;
    cleft_net_output = h5read(cleftprob_path, '/main', stp, num_elem);
    intf_vol = h5read(intf_path, '/main', stp, num_elem);
    cells_segment_vol = h5read(seg_path, '/main', stp, num_elem);
    vesicle_seg_vol = h5read(vesicle_path, '/main', stp, num_elem);
    vesicle_seg_vol = vesicle_seg_vol .* uint32(cells_segment_vol > 0 );
    
    intf_idx = find(intf_vol == intf_ids_within_limit(ridx));    
    cprob = cleft_net_output(intf_idx);
    
   % compute intf sizes
    intf_vol_iso_mip0 = imresize3(intf_vol,'Scale', [1,1,4],'Method', 'nearest');
    intf_size_iso_mip0 = round(numel(find(intf_vol_iso_mip0 == intf_ids_within_limit(ridx)))/2);    
    intf_size_info(ridx,1) = intf_size_iso_mip0;
    intf_size = numel(intf_idx);
    intf_id_info(ridx,1) = intf_ids_within_limit(ridx);
    
    % svm classifier
    if (intf_size > intf_size_th)
        prct = prctile(cprob, pointPrctile);
        interprct = prctile(cprob, upperPrctile) - prctile(cprob, lowerPrctile);
        [~,score] = predict(SVMModel, [prct, interprct]);
        label = double(score(:,2) > svm_theta)+1;
        predictions(ridx,1) = label;
        bbox_info(ridx,:) = [stp, num_elem];
    end
    
    % very large interfaces
    if sum(cprob > highProb, 'all') > (intf_size_th * 2)
        predictions(ridx,1) = 2;
        bbox_info(ridx,:) = [stp, num_elem];
    end

    
    h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
    rtn = mysql(h_sql,  ['use ', omni_db_name]);
    
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
    
    
    if predictions(ridx,1) == 2
        % match vesicle segments.   cell types { 1-PC, 2-PF, 3-CF, 4-IN, 5-GLI, 6-GOL} 
        vc_seg_match = extract_gtsegid_of_vc(vesicle_seg_vol, cells_segment_vol);
        if ~isempty(vc_seg_match)
            vc_seg_match_vc = vc_seg_match(:,1);   vc_seg_match_seg = vc_seg_match(:,2);
            se = strel('sphere',1);
            bw_vc = vesicle_seg_vol > 0;
            bw_vc = imerode(bw_vc, se);
            vc_surf = (uint32(vesicle_seg_vol) .* uint32(~bw_vc));
   
            %{
            h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
            rtn = mysql(h_sql,  ['use ', omni_db_name]);
            
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
            %}
            
            [ix,iy,iz] = ind2sub(size(intf_vol), find(intf_vol == intf_ids_within_limit(ridx)));
            
            nearest_vc1 = 0; nearest_vc2 = 0;
            dist = 1000;  dist2 = 1000;
            contact_size = 0;  contact_size2 = 0;
            contact_loc2 = -1000; % to avoid warning msg
            
            if ismember(cell_type1, [2,3,4])
                vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id1);
                if numel(vc_of_seg) > 0
                    [vc_id, dist, contact_size, contact_loc] = get_nearest_vc(vc_surf, vc_of_seg, ix, iy, iz);
                    
                    contact_info(ridx,:) = contact_loc + stp - 1;
                end
            end
            
            if ismember(cell_type2, [2,3,4])
                vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id2);
                if numel(vc_of_seg) > 0
                    [vc_id2, dist2, contact_size2, contact_loc2] = get_nearest_vc(vc_surf, vc_of_seg, ix, iy, iz);
                end
            end
            
            if dist > vc_dist && dist2 > vc_dist                        % if no vesicle exists within vc_dist from intf
                predictions(ridx,1) = 1;                                % predict value 1
                
            elseif dist <= vc_dist && dist2 <= vc_dist                    % if both seg have vc within vc_dist
                 pre_post_ambiguity(ridx,1) = 1;
                if contact_size >= contact_size2        % if vc in seg1 has larger contacts
                    % do nothing
                elseif contact_size < contact_size2    % if vc in seg2 has larger contacts
                    seg_id_info(ridx,:) = [seg_id2, seg_id1];             % swap seg id positions
                    cell_type_info(ridx,:) = [cell_type2, cell_type1];    % swap cell type positions
                    contact_info(ridx,:) = contact_loc2 + stp - 1;
                end
                
            elseif dist2 <= vc_dist                                      % if vc in seg2 is within vc_dist and vc in seg1 is not within vc_dist.
                seg_id_info(ridx,:) = [seg_id2, seg_id1];                 % swap seg id positions
                cell_type_info(ridx,:) = [cell_type2, cell_type1];        % swap cell type positions
                contact_info(ridx,:) = contact_loc2 + stp - 1;
            end
        else                            % if vc doesn't exist
            predictions(ridx,1) = 1;
        end
    end
        
end

toc;

%%  Save!

synapse_info_tbl = [intf_id_info, seg_id_info, cell_type_info, intf_size_info, contact_info, bbox_info];
save('/data/lrrtm3_wt_syn/mat_data/synapse_info_tbl_select.mat', 'synapse_info_tbl');

for i = (halfpoint+1):endpoint
    val1 = cell_type_info(i,1);
    val2 = cell_type_info(i,2);
    fprintf(fid2, '%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', intf_id_info(i,1), seg_id_info(i,:), celltype_map{val1}, celltype_map{val2}, ...
            intf_size_info(i,1), contact_info(i,:), bbox_info(i,:));
        
    if predictions(i,1) == 2
        fprintf(fid, '%d,%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',intf_id_info(i,1), pre_post_ambiguity(i,1), seg_id_info(i,:), ...
            celltype_map{val1}, celltype_map{val2}, intf_size_info(i,1), contact_info(i,:), bbox_info(i,:));
    end
end

%nonsynapses = intf_ids(~ismember(intf_ids, synapses));
%save('/ldata/lrrtm3_wt_syn/synapse_ids.mat', 'synapses');
%save('/ldata/lrrtm3_wt_syn/nonsynapse_ids.mat', 'nonsynapses');
%save('/data/lrrtm3_wt_syn/pre_post_ambiguity.mat', 'pre_post_ambiguity');
save('/data/lrrtm3_wt_syn/mat_data/predictions.mat', 'predictions');

fprintf('\n *************************************************** ' );
fprintf('\n Classification almost done.  Incredibly large interfaces may be remaining... \n');
fprintf('%s %d\n', 'Incredible large interfaces  N = ', numel(intf_ids_beyond_limit));
fprintf('\n *************************************************** \n' );


%% Functions

function [nearest_vc_id, dist, ncontacts, contact_loc] = get_nearest_vc(VC, vc_of_seg, ix, iy, iz)
% There may be faster way of doing this...   

    nearest = 1000;
    dist = 1000;
    nearest_vc_id = 0;
    ncontacts=0;
    contact_loc = [-1, -1, -1];
    [s1, s2, s3 ] = size(VC);
    
    for j = 1:numel(vc_of_seg)
        [vcx,vcy,vcz] = ind2sub(size(VC),find(VC==vc_of_seg(j)));
        
        if ~isempty(vcx)
            
            % First find proximal vesicle cloud.
            [~,d] = dsearchn([vcx(1:ceil(end/200):end), vcy(1:ceil(end/200):end), vcz(1:ceil(end/200):end)], ...
                [ix(1:ceil(end/200):end), iy(1:ceil(end/200):end), iz(1:ceil(end/200):end)]);
            
            min_dist = min(d);
            if min_dist <= nearest
                nearest = min_dist;
                nearest_vc_id = vc_of_seg(j);
            end
            
            % If multiple vesicle segments in proximity,
            % choose the one with largest contact.
            if min_dist < 200
                [ind,d] = dsearchn([ix, iy, iz], [vcx, vcy, vcz]);
                min_dist = min(d);
                k = find(d==min_dist);
                if min_dist < 10
                    val = sum(d==min_dist);
                    if ~isempty(d(d>min_dist))
                        val = val + sum(d==min(d(d>min_dist )));
                    end
                    if ncontacts < val
                        ncontacts = val;
                        dist = min_dist;
                        nearest_vc_id = vc_of_seg(j);
                        
                        % find the center point of contact on interface
                        contact_surface = [ix(ind(k)), iy(ind(k)), iz(ind(k))];
                        contact_surface = unique(contact_surface, 'rows');
                        z_heights =unique(contact_surface(:,3));
                        midline = zeros(numel(z_heights),1);
                        for jj = 1:numel(z_heights)
                            this_curve = contact_surface(contact_surface(:,3) == z_heights(jj),:);
                            linear_index = sub2ind([s1,s2,s3], this_curve(:,1), this_curve(:,2), this_curve(:,3));
                            midline(jj) = linear_index(ceil(end/2));
                        end                        
                        
                        [contact_loc(1),contact_loc(2), contact_loc(3)] = ind2sub([s1,s2,s3], midline(ceil(end/2)));
                    end
                end
            end
        end
    end
end

% extract presynapse segment id from vesicle cloud volume hdf5 file 
function vc_segid_match = extract_gtsegid_of_vc(vc_detect, gt_seg)
    %extract presynapse celltypes

    all_vc_id = unique(vc_detect(:));
    all_vc_id(all_vc_id==0) = [];

    nvc = numel(all_vc_id);
    if nvc == 0
        vc_segid_match = all_vc_id;
    else 
    
        vc_segid_match = all_vc_id;
        vc_segid_match = [vc_segid_match zeros([nvc 1],'uint32')];
        
        for iter=1:nvc
            idx = find(vc_detect==all_vc_id(iter));
            match_segids = unique(gt_seg(idx(:)));
            match_segids(match_segids==0) = [];
            %  sprintf('number of matches = %d', numel(match_segids));
            
            if numel(match_segids) > 1
                dominant = 0;
                for i=numel(match_segids)
                    size = numel(find(gt_seg(idx(:))==match_segids(i)));
                    if size > dominant
                        vc_segid_match(iter,2) = match_segids(i);
                    end
                end
            elseif numel(match_segids) == 1
                vc_segid_match(iter, 2) = match_segids(1);
            else
                warning(['Found no segment match for vesicle ', num2str(all_vc_id(iter))])
            end
            
            %    disp(['Vesicle ', num2str(iter), '  matched to ', num2str( vc_segid_match(iter, 2) )]);
        end
    
    end
end




