
% % % % % 06.27 - descriptor
% input
% 1. 'datasetName'
%     - lrrtm3 == 1 : lrrtm3 dataset
% 
% 
function [param, datasetNo] = lrrtm3_get_global_param(datasetName)
switch datasetName
    case {'lrrtm3', 1}
        [param, datasetNo] = get_lrrtm3_dataset_info();
    otherwise    
        error('stat - no dataset name\n');
end
end

function [param, datasetNo] =  get_lrrtm3_dataset_info()
datasetNo = 1;
% path 
param.home_vols = sprintf('/data/lrrtm3_wt_omnivol/');
% param.home_reconstruction = sprintf('/data/research/jeson/00_lrrtm3_wt_reconstruction/');
param.home_reconstruction = sprintf('/data/lrrtm3_wt_reconstruction/');
param.home_trace_files = sprintf('/data/lrrtm3_wt_omnivol/cell_trace_data');
param.segmentation_path = '.files/segmentations/segmentation1/0/volume.uint32_t.raw';
param.omni_exe_path = '/data/omni/omni.omnify/omni.omnify';
param.home_trace_files = '/data/lrrtm3_wt_omnivol/cell_trace_data/';

% data volume dimension
param.size_of_chunk = [128 128 128];
param.size_of_chunk_linear = prod(param.size_of_chunk);
param.size_of_uint32 = 4;
param.scaling_factor = [1 1 4];
param.default_vol_size = [512 512 128];
param.default_vol_overlap = [32 32 8];
param.size_of_data = [14592 10240 1024];

% database
param.dataset_id = 1;
end