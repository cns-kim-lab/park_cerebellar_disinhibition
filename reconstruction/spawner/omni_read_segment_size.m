function [rtn_seg_list, rtn_seg_size] = omni_read_segment_size(vol_path, seg_list)

rtn_seg_list = [];
rtn_seg_size = [];

if( isempty(seg_list) )
	return;
end

seg_path = '.files/users/_default/segmentations/segmentation1/segments/';

page_size = 1000000;
page_idx = floor(seg_list/page_size); 

max_page_num = max(page_idx);

for page_num = 0:max_page_num

    seg_list_at_this_page = seg_list(page_idx==page_num);

    seg_file = sprintf('segment_page%d.data.ver4',page_num);
    full_path = [vol_path seg_path seg_file];

    [segID, segSize] = read_segment_size(full_path);
    idx = segID > 0;
    segID = segID(idx);
    segSize = segSize(idx);

    [~, IA, IB] = intersect(segID, seg_list_at_this_page);
    seg_size = zeros(size(seg_list_at_this_page));
    seg_size(IB) = segSize(IA);
    
    rtn_seg_list = [rtn_seg_list seg_list_at_this_page]; 
    rtn_seg_size = [rtn_seg_size seg_size];

end


end
