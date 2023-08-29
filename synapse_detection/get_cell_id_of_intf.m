% an interface stems from two contacting segments.
% get the two segment id.

addpath /data/research/cjpark147/code/matlab/mysql/

%% get seg id and cell type

tic;
spath = '/data/lrrtm3_wt_syn/segment_mip0_all_cells_200313.h5';
ipath = '/data/lrrtm3_wt_syn/interface_relevant_fixed.h5';
load('/data/lrrtm3_wt_syn/bbox_fixed.mat');

[row,col] = size(bbox_fixed);
interface_info = zeros(row, col+4);
seg_id_list = zeros(row,2);
cell_type_list = zeros(row,2);


parfor ridx = 1:row
    
    h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
    rtn = mysql(h_sql, 'use omni_20200313');
    seg = h5read(spath, '/main', bbox_fixed(1:3), bbox_fixed(4:6));
    intf = h5read(ipath, '/main', bbox_fixed(1:3), bbox_fixed(4:6));
    
    bw = (intf == ridx);
    se = strel('sphere',1);
    di = imdilate(bw,se);
    su = di - bw;
    su_id = seg(su);
    su_id(su_id == 0) = [];
    
    seg_id1 = mode(su_id, 'all');   % the most frequent seg id
    su_id(su_id == seg_id1) = [];
    seg_id2 = mode(su_id, 'all');   % second most frequent id
    
    seg_id_list(ridx,:) = [seg_id1, seg_id2];

    
    query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id1);
    cell_type1 = mysql(h_sql, query);
    query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', seg_id2);
    cell_type2 = mysql(h_sql, query);
    
    cell_type_list(ridx,:) = [cell_type1, cell_type2];
    mysql(h_sql, 'close');

end

interface_info(:,1:2) = seg_id_list;
interface_info(:,3:4) = cell_type_list;
interface_info(:,5:end) = bbox_fixed;
save('/data/lrrtm3_wt_syn/intf_info_fixed.mat','interface_info');

toc;












