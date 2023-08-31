
function rtn = lrrtm3_find_vol_seg_at_coord(coord, verbose, dataset)

rtn = [];

% % % % % 06.27 - modified code by je.son
if ~exist('dataset', 'var')
    dataset = 1;
end
[param,~] = lrrtm3_get_global_param(dataset);

%     global size_of_uint32 size_of_chunk_linear size_of_chunk scaling_factor home_vols
%     size_of_chunk = [128 128 128];
%     size_of_chunk_linear = prod(size_of_chunk);
%     size_of_uint32 = 4;
%     scaling_factor = [1 1 4];
%     home_vols = sprintf('/data/lrrtm3_wt_omnivol/');
%     segmentation_path = '.files/segmentations/segmentation1/0/volume.uint32_t.raw';
% 
%     default_vol_size = [512 512 128];
%     default_vol_overlap = [32 32 8];


% % % % % 06.27 - constant variable
size_of_chunk = param.size_of_chunk;
size_of_chunk_linear = param.size_of_chunk_linear;
size_of_uint32 = param.size_of_uint32;
scaling_factor = param.scaling_factor;
home_vols = param.home_vols;
segmentation_path = param.segmentation_path;
default_vol_size = param.default_vol_size;
default_vol_overlap = param.default_vol_overlap;

coord = round(coord ./ scaling_factor);
ijk = floor((coord - 1)./(default_vol_size - default_vol_overlap)) + 1;

num_found_vols = 0;

for i_o = -1:1
    for j_o = -1:1
        for k_o = -1:1
            
            ijk_o = ijk + [i_o j_o k_o];
            
            offset = (ijk_o - 1).*(default_vol_size - default_vol_overlap);
            st = offset + 1;
            ed = offset + default_vol_size; 

            if ~(all(st<=coord) && all(coord<=ed))
                continue;
            end

            pattern = sprintf('%s/z%02d/y%02d/Net_*_x%02d_y%02d_z%02d_*.omni',home_vols, ijk_o(3), ijk_o(2), ijk_o);
            files = dir(pattern);

            for ii = 1:numel(files)

                % 'Net %s x%d y%d z%d st %d %d %d sz %d %d %d'                
                file_name = files(ii).name; 
                pos = strfind(file_name, '_');
                net_id = file_name(pos(1)+1:pos(2)-1);
                vol_id = file_name(pos(2)+1:pos(5)-1);                
    
                [~, vol_coord_info] = lrrtm3_get_vol_info(home_vols, net_id, vol_id, 1); 
                
                actual_vol_size = vol_coord_info.mip_vol_size; 
                actual_vol_size_in_chunk = actual_vol_size ./ size_of_chunk;
                
                coord_in_vol = coord - offset; 
                sub_chunk = floor((coord_in_vol-1)./size_of_chunk)+1;
                ind_chunk = sub2ind(actual_vol_size_in_chunk, sub_chunk(1), sub_chunk(2), sub_chunk(3));
                file_offset = (size_of_uint32*(ind_chunk-1)*size_of_chunk_linear);
            
                file_folder = files(ii).folder; 
                file_name = files(ii).name; 
                
                f=fopen(sprintf('%s/%s%s',file_folder,file_name,segmentation_path), 'r');
                fseek(f,file_offset,'bof');
                chunk = reshape(fread(f,size_of_chunk_linear,'*uint32'),size_of_chunk);
                fclose(f);
                
                sub_in_this_chunk = coord_in_vol-(sub_chunk-1).*size_of_chunk;
                segment = chunk(sub_in_this_chunk(1),sub_in_this_chunk(2),sub_in_this_chunk(3));
                
                if segment == 0 
                    continue;
                end

                num_found_vols = num_found_vols + 1;
                rtn(num_found_vols).vol_id = sprintf('%s_%s',net_id,vol_id); 
                rtn(num_found_vols).segment = double(segment);
            end
            
        end
    end
end

if exist('verbose','var') && strcmp(verbose,'v')
    print_result(rtn);
end

end

function print_result(vol_seg)

if isempty(vol_seg)
    return;
end

for i = 1:numel(vol_seg)
    fprintf('%s\t%d\n',vol_seg(i).vol_id, vol_seg(i).segment);
end

end
