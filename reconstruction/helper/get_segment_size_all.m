function [seg_id,seg_size] = get_segment_size_all( vol_path )

seg_path = '/users/_default/segmentations/segmentation1/segments/';
% page_size = 1000000;
% page_num = floor(max(seg)/page_size);
% if( page_num > 0 )
% 	disp(page_num);
% 	page_num = 0;
% end
page_num = 0;

seg_file = sprintf('segment_page%d.data.ver4',page_num);
full_path = [vol_path seg_path seg_file];
try
	[seg_id,seg_size] = read_segment_size( full_path );
catch err
        seg_id = [];
	seg_size = [];
end

seg_id=int32(seg_id);
seg_size=int32(seg_size);

end
