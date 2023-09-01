
function rtn = find_vol_seg_about_multiple_coord(coord)

rtn = struct;
num_found_vols = 0;

size_of_chunk = [128 128 128];
scaling_factor = [1 1 4];
default_vol_size = [512 512 128];
default_vol_overlap = [32 32 8];
home_vols = '/data/lrrtm3_wt_omnivol/';
segmentation_path = '.files/segmentations/segmentation1/0/volume.uint32_t.raw';

coord = round(coord ./ scaling_factor);
ijk = floor((coord - 1)./(default_vol_size - default_vol_overlap)) + 1;
ijk_unique = unique(ijk,'rows','stable');
relevant_volume_ijk = [];

for i_o = -1:1
    for j_o = -1:1
        for k_o = -1:1
            
            ijk_o = ijk_unique + [i_o j_o k_o];
            
            offset = (ijk_o - 1).*(default_vol_size - default_vol_overlap);
            st = offset + 1;
            ed = offset + default_vol_size; 

            relevant_volume_or_not = false(size(ijk_unique,1),1);
            for n = 1:size(ijk_unique,1)
                relevant_volume_or_not(n) = any(all(st(n,:)<=coord,2) .* all(coord<=ed(n,:),2));
            end
            
            relevant_volume_ijk(end+1:end+sum(relevant_volume_or_not),:) = ijk_o(relevant_volume_or_not,:);
            relevant_volume_ijk = unique(relevant_volume_ijk,'rows','stable');
            
        end
    end
end


for n = 1:size(relevant_volume_ijk,1)
                       
            ijk_o = relevant_volume_ijk(n,:);

            offset = (ijk_o - 1).*(default_vol_size - default_vol_overlap);
            coord_in_vol = coord - offset; 
                
            pattern = sprintf('%s/z%02d/y%02d/Net_*_x%02d_y%02d_z%02d_*.omni',home_vols, ijk_o(3), ijk_o(2), ijk_o);
            files = dir(pattern);

            for ii = 1:numel(files)

                % 'Net %s x%d y%d z%d st %d %d %d sz %d %d %d'                
                file_name = files(ii).name; 
                pos = strfind(file_name, '_');
                net_id = file_name(pos(1)+1:pos(2)-1);
                vol_id = file_name(pos(2)+1:pos(5)-1);                
    
                [~, vol_coord_info] = get_vol_info(home_vols, net_id, vol_id, 1); 
                
                actual_vol_size = vol_coord_info.mip_vol_size;                
                relevant_coord_in_chunk = coord_in_vol(logical(all(coord_in_vol>=[1 1 1],2).*all(coord_in_vol<=actual_vol_size,2)),:);
                relevant_coord_in_chunk_ind = sub2ind(actual_vol_size,relevant_coord_in_chunk(:,1),relevant_coord_in_chunk(:,2),relevant_coord_in_chunk(:,3));
                
                file_folder = files(ii).folder;
                file_name = files(ii).name;
                path_vol_segmentation = sprintf('%s/%s%s',file_folder,file_name,segmentation_path);
                
                chunk = lrrtm3_get_vol_segmentation(path_vol_segmentation, vol_coord_info);
                segment = chunk(relevant_coord_in_chunk_ind);
                segment = unique(segment(segment~=0),'stable');             
                
                if isempty(segment) 
                    continue;
                end

                num_found_vols = num_found_vols + 1;
                rtn(num_found_vols).vol_id = sprintf('%s_%s',net_id,vol_id); 
                rtn(num_found_vols).segment = double(segment);
            end
            
end


end