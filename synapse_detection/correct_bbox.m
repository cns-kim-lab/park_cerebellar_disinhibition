% sometimes an incredibly large bounding box is assigned to an interface (merge error).
% correct the box using conncomp.

function correct_bbox(intf_path, intf_fixed_path)
addpath /data/research/cjpark147/synapse_detector/fwd
addpath /data/research/cjpark147/code/hdf5_ref

%intf_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_reassigned_210503.h5';
%intf_fixed_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_fixed_210503.h5';
load('/data/lrrtm3_wt_syn/assembly/mat_data/intf_bbox.mat');
[row,~] = size(intf_bbox);

%% Get large bounding box

empty_bbox = zeros(row,1);
big_bbox = cell(row,1);
tic;
for ridx = 1:row
%    load_limit = 500000000;    
%    if intf_bbox(ridx,4) * intf_bbox(ridx,5) * intf_bbox(ridx,6) < load_limit
        
        intf = h5read(intf_path, '/main', intf_bbox(ridx,1:3), intf_bbox(ridx,4:6));
        bw = (intf == ridx);
        cc = bwconncomp(bw, 26);
        
        if cc.NumObjects == 0
            empty_bbox(ridx,1) = 1;
        elseif cc.NumObjects > 1
            cc_size = cellfun('length', cc.PixelIdxList);
    %        [val, arg] = max(cc_size);
            big_bbox{ridx,1} = sort(cc_size);

        end
        
        if mod(ridx,1000) == 0
            fprintf('%d %s\n', ridx, 'interfaces done');
        end
%    else        
%    end
end
save('/data/lrrtm3_wt_syn/assembly/mat_data/big_bbox.mat','big_bbox');

ncc = cellfun(@numel, big_bbox);
id_mult = find(ncc>1);
save('/data/lrrtm3_wt_syn/assembly/mat_data/id_mult.mat','id_mult');
toc;
%}

%% Separate multiple contacts in the large bounding box

load('/data/lrrtm3_wt_syn/assembly/mat_data/id_mult.mat');
count = 0;
intf_size_thresh = 160;
bbox_new = [];

tic;
% split intf by connected components
for i = 1:numel(id_mult)
    
    cur_id = id_mult(i);
    stp = intf_bbox(cur_id,1:3);
    num_elem = intf_bbox(cur_id,4:6);    
    intf = h5read(intf_path, '/main', stp, num_elem);
    bw = (intf == cur_id);
    cc = bwconncomp(bw, 26);
    clear bw;
    
    for j = 1:cc.NumObjects
        if numel(cc.PixelIdxList{j}) > intf_size_thresh
            bw = zeros(size(intf));
            bw(cc.PixelIdxList{j}) = 1;
            cur_bbox = round(regionprops3(bw, 'BoundingBox').BoundingBox);
            
            stp_box = [stp(2), stp(1), stp(3)];
            cur_bbox(1:3) = cur_bbox(1:3) + stp_box - 1;    % global_coord (y,x,z)
            
            bbox_new = [bbox_new ; cur_bbox];
            count = count + 1;
            intf(cc.PixelIdxList{j}) = uint32(row + count);
            
        else
            intf(cc.PixelIdxList{j}) = 0;
        end
    end
    
    h5write(intf_fixed_path, '/main', intf, stp, num_elem);
    fprintf('%d\n', i);
end
        
temp1 = bbox_new(:,1);
temp2 = bbox_new(:,4);
bbox_new(:,1) = bbox_new(:,2);
bbox_new(:,4) = bbox_new(:,5);
bbox_new(:,2) = temp1;
bbox_new(:,5) = temp2; 

bbox_fixed = [intf_bbox; bbox_new];
rm_bbox = zeros(numel(id_mult),6);
bbox_fixed(id_mult,:) = rm_bbox;    % intf having id_mult as id no longer exists. 
toc;
save('/data/lrrtm3_wt_syn/assembly/mat_data/bbox_fixed.mat','bbox_fixed');
%}
end

%% correct bbox with size larger than load_limit

%{
load('/data/lrrtm3_wt_syn/assembly/mat_data/bbox_fixed_210503.mat');
load('/data/lrrtm3_wt_syn/assembly/mat_data/intf_bbox_210503.mat');
load_limit = 500000000;
size_dist = intf_bbox(:,4) .* intf_bbox(:,5) .* intf_bbox(:,6);
idlist = find(size_dist>=load_limit);
[max_id,~] = size(bbox_fixed);
minp = [1,1,1];
maxp = [14592, 10240, 1024];
subvol_size = [512,512,256];
last_cubeidx = [29,20,4];
count = 0;
intf_size_thresh = 200;
bbox_new = [];

for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + [1,1,1]);
            enp = min(maxp, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            subvol = h5read(intf_fixed_path, '/main', stp, num_elem);
            id_det = idlist(ismember(idlist, subvol));
            disp(id_det);                

            
            for i = 1:numel(id_det)
                cur_id = id_det(i);
                bw = (subvol==cur_id);
                [is_at_edge, dir] = at_vol_edge(1, bw);
                
                if ~is_at_edge
                    cc = bwconncomp(bw,26);
                    
                    for j = 1:cc.NumObjects
                        
                        if numel(cc.PixelIdxList{j}) > intf_size_thresh
                            
                            bw = zeros(size(subvol));
                            bw(cc.PixelIdxList{j}) = 1;
                            cur_bbox = round(regionprops3(bw, 'BoundingBox').BoundingBox);                            
                            stp_box = [stp(2), stp(1), stp(3)];
                            cur_bbox(1:3) = cur_bbox(1:3) + stp_box - 1;    % global_coord (y,x,z)                            
                            bbox_new = [bbox_new ; cur_bbox];
                            count = count + 1;
                            subvol(cc.PixelIdxList{j}) = uint32(max_id + count);
                    
                        else
                            
                            subvol(cc.PixelIdxList{j}) = 0;
                            
                        end
                    end
                    
                    h5write(intf_fixed_path, '/main', subvol, stp, num_elem);

                else
                    stp_e = stp;
                    enp_e = enp;
                    
                    while is_at_edge
                        
                        [subvol_new, stp_e, enp_e] = extend_vol(intf_fixed_path, subvol, maxp, dir, is_at_edge, stp_e, enp_e, cur_id);   
                        [is_at_edge, dir] = at_vol_edge(cur_id, subvol_new);                        
                        
                    end
                    
                    bw = (subvol_new==cur_id);
                    cc = bwconncomp(bw,26);
                    
                    for j = 1:cc.NumObjects                        
                        if numel(cc.PixelIdxList{j}) > intf_size_thresh
                            
                            bw = zeros(size(subvol_new));
                            bw(cc.PixelIdxList{j}) = 1;
                            cur_bbox = round(regionprops3(bw, 'BoundingBox').BoundingBox);                            
                            stp_box = [stp_e(2), stp_e(1), stp_e(3)];
                            cur_bbox(1:3) = cur_bbox(1:3) + stp_box - 1;    % global_coord (y,x,z)                            
                            bbox_new = [bbox_new ; cur_bbox];
                            count = count + 1;
                            subvol_new(cc.PixelIdxList{j}) = uint32(max_id + count);
                    
                        else
                            
                            subvol_new(cc.PixelIdxList{j}) = 0;
                            
                        end
                    end                    
                    num_elem_e = enp_e - stp_e + 1;
                    h5write(intf_fixed_path, '/main', subvol_new, stp_e, num_elem_e);

                end
            end

            fprintf('%s  %d, %d, %d\n', 'cubeidx' , x,y,z);
            save('/data/lrrtm3_wt_syn/assembly/bbox_new_210503.mat','bbox_new');
        end
    end
end


temp1 = bbox_new(:,1);
temp2 = bbox_new(:,4);
bbox_new(:,1) = bbox_new(:,2);
bbox_new(:,4) = bbox_new(:,5);
bbox_new(:,2) = temp1;
bbox_new(:,5) = temp2; 

%load('/data/lrrtm3_wt_syn/id_removed.mat')
id_removed = [id_mult; idlist];
bbox_fixed2 = [bbox_fixed; bbox_new];
rm_bbox = zeros(numel(idlist),6);
bbox_fixed2(idlist,:) = rm_bbox;  % intf having id_mult as id no longer exists. 
save('/data/lrrtm3_wt_syn/assembly/mat_data/bbox_fixed2_210503.mat','bbox_fixed2');
save('/data/lrrtm3_wt_syn/assembly/mat_data/id_removed.mat','id_removed');

toc;
%}

function [is_at_edge, dir] = at_vol_edge(ids, vol)
    dir_xm = 0; dir_ym = 0; dir_zm = 0;
    dir_xp = 0; dir_yp = 0; dir_zp = 0;
    is_at_edge = 0;

    a = vol(1,:,:);
    b = vol(end,:,:);
    c = vol(:,1,:);
    d = vol(:,end,:);
    e = vol(:,:,1);
    f = vol(:,:,end);
    
    m1 = ismember(ids, a);
    m2 = ismember(ids, b);
    m3 = ismember(ids, c);
    m4 = ismember(ids, d);
    m5 = ismember(ids, e);
    m6 = ismember(ids, f);    

    if sum(m1) > 0
        is_at_edge = 1;    
        dir_xm = 1;
    end
    if sum(m2) > 0
        is_at_edge = 1;
        dir_xp = 1;
    end
    if sum(m3) > 0
        is_at_edge = 1;
        dir_ym = 1;
    end
    if sum(m4) > 0
        is_at_edge = 1;
        dir_yp = 1;
    end
    if sum(m5) > 0
        is_at_edge = 1;
        dir_zm = 1;
    end        
    if sum(m6) > 0
        is_at_edge = 1;
        dir_zp = 1;
    end
    dir = [ dir_xm, dir_ym, dir_zm, dir_xp, dir_yp, dir_zp];        
end


function [new_vol, stp_e, enp_e] = extend_vol(vol_path, vol, max_size, dir, extend, stp, enp, id)
    minp = [1,1,1];
    extend_by = [200,200,50];
    if extend
        disp(['extend vol for id = ', num2str(id)]);
        stp_e = max(minp, stp - (extend_by .* dir(1:3)));
        enp_e = min(max_size, enp + (extend_by .* dir(4:6)));
        num_el = enp_e - stp_e + minp;
        new_vol = h5read(vol_path, '/main', stp_e, num_el);
        
    else
        new_vol = vol;
    end
end

%{

function [new_vol, stp_e, enp_e] = extend_vol(vol_path, vol, max_size, dir, extend, stp, enp, id)
    minp = [1,1,1];
    extend_by = [256,256,64];
    if extend
        disp(['extend vol for id = ', num2str(id)]);
        stp_e = max(minp, stp - (extend_by .* dir));
        enp_e = min(max_size, enp + (extend_by .* dir));
        num_el = enp_e - stp_e + minp;
        new_vol = h5read(vol_path, '/main', stp_e, num_el);
        
        [extend, dir] = at_vol_edge(id, new_vol);
        extend_vol(vol_path, vol, max_size, dir, extend, stp_e, enp_e, id);
    else
        new_vol = vol;
    end
end
        %}


        