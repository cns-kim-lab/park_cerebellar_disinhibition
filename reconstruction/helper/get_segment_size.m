function [seg_size,n_seg] = get_segment_size( vol_path, seg )

seg_size = [];
n_seg = 0;
if( isempty(seg) )
	return;
else
	seg = uint32(seg);	
end
seg_size = zeros(1,numel(seg));

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
	[segID,segSize] = read_segment_size( full_path );

	idx = segID > 0;
	segID = segID(idx);
	segSize = segSize(idx);
	% assert( isequal(size(segID),size(segSize)) );

	% [seg_size] = segSize(seg);
	idx = ismember(segID,seg);
	[foo,IA,IB] = intersect(segID,seg);
	seg_size(IB) = segSize(IA);
	[n_seg] = numel(segID);
catch err
	seg_size = [];
	n_seg = 0;
end

end
