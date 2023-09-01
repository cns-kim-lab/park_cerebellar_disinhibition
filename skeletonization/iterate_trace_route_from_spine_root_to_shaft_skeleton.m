mat_dir = '/data/research/iys0819/cell_morphology_pipeline/result/skeleton_pc_spine';
% h5_dir = '/data/research/iys0819/cell_morphology_pipeline/volumes';
% shaft_h5_file_path = sprintf('%s/shaft_spine_separation.iso_mip1.e7.th20000.d14.ds_to_iso_mip3.h5',h5_dir);
vol_iso_mip3 = h5read(shaft_h5_file_path, '/main'); % path to h5 file of isotropic mip3 volume with shaft-spine separated PCs
target_cell_id_list = load_target_PC_dendrite_id_list;

for i = 1:length(target_cell_id_list)
    target_cell_id = target_cell_id_list(i); 
    fprintf('trace route from spine root to shaft skeleton for cell %d\n',target_cell_id);
    [route_from_spine_root_to_shaft_skeleton,dbf_of_route_from_spine_root_to_shaft_skeleton] = trace_route_from_spine_root_to_shaft_skeleton (target_cell_id,vol_iso_mip3);
    result_file_name = sprintf('%s/route_from_spine_skeleton_to_shaft_skeleton_of_cell_%d.mat',mat_dir,target_cell_id);
    save(result_file_name,'route_from_spine_root_to_shaft_skeleton','dbf_of_route_from_spine_root_to_shaft_skeleton','target_cell_id','-v7.3');
end