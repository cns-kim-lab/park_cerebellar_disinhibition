% Only for reassigned interface volume (id lists must not include gap)

function get_boundingbox(intf_path)

tic; 
addpath /data/research/cjpark147/code/hdf5_ref
%intf_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_reassigned_210503.h5';
[~,volsize,~] = get_hdf5_size(intf_path, '/main');
%load('/data/lrrtm3_wt_syn/interface_relevant_info.mat');

subvol_size = [1024,1024,256];
minp = [1,1,1];
last_cubeidx = [15,10,4];

%max_id = 865010;
max_id = 0;
for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + [1,1,1]);
            enp = min(volsize, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            subvol = h5read(intf_path, '/main', stp, num_elem);
            max_iid = max(subvol, [], 'all');
            if max_id < max_iid
                max_id = max_iid;
            end
            fprintf('%d, %d, %d\n', x,y,z);
        end
    end
end
%}

result = zeros(max_id, 6);
result(:,1:3) = result(:,1:3) + volsize;
%id_list = [1:max_id]';

%% Get bounding box

% There is a way to avoid using nested for loops.
% It was not possible for current dataset, because
% i couldn't find a way to disconnect 'holed' interfaces from each other.


for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + minp);
            enp = min(volsize, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            subvol = h5read(intf_path, '/main', stp, num_elem);
            idl = unique(subvol);
            idl(idl==0) = [];            
            bbox_info = zeros(numel(idl), 7);
            
            parfor i = 1:numel(idl)
                bw = (subvol == idl(i));
                bbox = regionprops3(bw, 'BoundingBox').BoundingBox;
                bbox = round(bbox);
                num_box = size(bbox,1);
                
                % convert bbox format from [stp, stride] to [stp, enp]
                if num_box > 1                    
                    bbbox = bbox(1,:);
                    bbbox(1,4:6) = bbbox(1,1:3) + bbbox(1,4:6) - 1;
                    for j = 1:num_box
                        bbbox(1,1:3) = min( bbox(j,1:3), bbbox(1,1:3));
                        bbox_enp =  bbox(j,1:3) + bbox(j,4:6) - 1;
                        bbbox(1,4:6) = max( bbox_enp, bbbox(1,4:6));
                    end
                    bbox = bbbox;
                elseif num_box == 1
                    bbox(1,4:6) = bbox(1,1:3) + bbox(1,4:6) - 1;
                    
                else
                    bbox = [0,0,0,0,0,0];
                end
                
                temp1 = bbox(1,1);
                temp2 = bbox(1,4);
                bbox(1,1) = bbox(1,2);
                bbox(1,4) = bbox(1,5);
                bbox(1,2) = temp1;
                bbox(1,5) = temp2;
                
                bbox(1,:) = bbox(1,:) + [stp, stp] - 1;
                bbox_info(i,:) = [idl(i), bbox(1,1:6)];
            end
            
            stp_update = min(result(bbox_info(:,1),1:3), bbox_info(:,2:4));
            enp_update = max(result(bbox_info(:,1),4:6), bbox_info(:,5:7));
            
            fprintf('  %d, %d, %d\n', x,y,z);            
            result(bbox_info(:,1),:) = [stp_update, enp_update];
        end
    end
end

stride = result(:,4:6) - result(:,1:3) + 1;
intf_bbox = result(:,:);
intf_bbox(:,4:6) = stride;
save('/data/lrrtm3_wt_syn/assembly/mat_data/intf_bbox.mat', 'intf_bbox');

toc;
                
end  
                
                
                