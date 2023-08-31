
%%
% % % % % 06.27 - modified code by je.son
function [path_of_vol_in_home,vol_coord_info]=lrrtm3_get_vol_info(vol_home,net_id,vol_id,mip_factor, dataset)
% function [path_of_vol_in_home,vol_coord_info]=lrrtm3_get_vol_info(vol_home,net_id,vol_id,mip_factor)

if ~exist('dataset', 'var')
    dataset = 1;
end
[param, ~] = lrrtm3_get_global_param(dataset);

% lrrtm3_param = lrrtm3_get_global_param();

scaling_factor = param.scaling_factor;
default_vol_size = param.default_vol_size;
default_vol_overlap = param.default_vol_overlap;
size_of_chunk = param.size_of_chunk;

path_of_vol_in_home=[];
vol_coord_info=[];

xyz=sscanf(vol_id,'x%02d_y%02d_z%02d');

search_pattern=sprintf('%sz%02d/y%02d/Net_%s_%s*.omni',vol_home,xyz(3),xyz(2),net_id,vol_id);
% search_pattern=sprintf('%s/z%02d/y%02d/Net_%s_%s*.omni',vol_home,xyz(3),xyz(2),net_id,vol_id);
t=dir(search_pattern);
if isempty(t)
    return
end

name_of_vol=t.name;
path_of_vol_in_home=sprintf('z%02d/y%02d/%s',xyz(3),xyz(2),name_of_vol);
id_st_sz=textscan(name_of_vol,'Net %s x%d y%d z%d st %d %d %d sz %d %d %d','delimiter','_');

vol_size=double([id_st_sz{8:10}]);
vol_size=ceil(vol_size./size_of_chunk).*size_of_chunk; %numbers in file name only considers data size. omni pads zeros to meet chunked size.

ijk = double([id_st_sz{2:4}]); 
offset = (ijk-1).*(default_vol_size-default_vol_overlap).*scaling_factor; 

vol_bbox=[offset+1 offset+vol_size];

mip_st = ceil(vol_bbox(1:3)/mip_factor);
mip_vol_size = ceil(vol_size/mip_factor);
mip_vol_bbox = [mip_st mip_st+mip_vol_size-1];

vol_coord_info.vol_size=vol_size;
vol_coord_info.vol_bbox=vol_bbox;
vol_coord_info.mip_vol_size=mip_vol_size;
vol_coord_info.mip_vol_bbox=mip_vol_bbox;

end