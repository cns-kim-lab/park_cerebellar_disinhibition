%
% % % % % % 06.27 - modified code by je.son
function [seg_list, seg_size] = lrrtm3_get_seglist_at_thresh(vol_id, seed_seg_id, thresh, dataset)

if ~exist('dataset', 'var')
    dataset = 1;
end
[param, dataset] = lrrtm3_get_global_param(dataset);

home_vols = param.home_vols;
% home_vols = sprintf('/data/lrrtm3_wt_omnivol/');

pos = strfind(vol_id,'_');
net_id = vol_id(1:pos-1);
vol_idx = vol_id(pos+1:end);
        
[vol_path_in_home, ~] = lrrtm3_get_vol_info(home_vols, net_id, vol_idx, 2, dataset);
vol_path = sprintf('%s%s%s',home_vols, vol_path_in_home);    
% vol_path = sprintf('%s/%s%s',home_vols, vol_path_in_home);    

mst_file_name = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst_mean.data',vol_path);
if ~exist(mst_file_name,'file')
    mst_file_name = sprintf('%s.files/users/_default/segmentations/segmentation1/segments/mst.data',vol_path);
end    
mst = omni_read_mst(mst_file_name);

mst = [[mst.node1]' [mst.node2]' [mst.affin]'];
mst = mst(mst(:,3)>thresh, 1:3);

max_node = max([mst(:,1); mst(:,2)]);
max_node = max(max_node, max(seed_seg_id));

[~,idx]=sort(mst(:,3),'descend');

cluster_id_of_node = 1:max_node;

for i=1:numel(idx)

    node1 = mst(idx(i),1);
    node2 = mst(idx(i),2);
    
    cluster1 = cluster_id_of_node(node1);
    cluster2 = cluster_id_of_node(node2);
    
    cluster_id_of_node(cluster_id_of_node==cluster2) = cluster1;
end

cluster_id_of_seed = cluster_id_of_node(seed_seg_id);
seg_list = find(ismember(cluster_id_of_node, cluster_id_of_seed));

[seg_list, seg_size] = omni_read_segment_size(vol_path, seg_list);

end