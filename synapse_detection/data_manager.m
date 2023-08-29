
function data_manager(task_number) 

task_dict = cell(10);
task_dict{1} = 'forward_cleft_net';             % requires GPU
task_dict{2} = 'forward_vesicle_net';           % requires GPU
task_dict{3} = 'get_boundary_and_interface';    
task_dict{4} = 'assemble_interface_cubes';      
task_dict{5} = 'reassign_interface_id';   
task_dict{6} = 'assemble_boundary_cubes';
task_dict{7} = 'assemble_fwd_cubes_cleft';
task_dict{8} = 'assemble_fwd_cubes_vesicle';
task_dict{9} = 'segment_vesicle_cloud';


addpath /data/research/cjpark147/code/hdf5_ref
addpath /data/research/cjpark147/synapse_detector/fwd
intf_path = '/data/lrrtm3_wt_syn/interface/';
bndry_path = '/data/lrrtm3_wt_syn/assembly/assembly_boundary.h5';
ws_output_path = '/data/lrrtm3_wt_syn/vesicles/';
seg_tile_path = '/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_210503.h5';
jobconfig_path = '/data/research/kaffeuser/lrrtm3_syn_detection/cfg_cleft.txt';
cleft_cfg_path = '/data/research/kaffeuser/lrrtm3_syn_detection/cfg_cleft.txt';
vesicle_cfg_path = '/data/research/kaffeuser/lrrtm3_syn_detection/cfg_vesicle.txt';
savename_cleftprob = 'cleft_prob_210503';
savename_vesicleprob = 'vesicle_prob_210503';
savename_intf = 'assembly_interface_relevant_210503';
%savename_intf = 'interface_all';

jobcfg = parsing_jobconfig(jobconfig_path);
[input_tile,~] = get_cfg(jobcfg, 'input_tile');
[cube_size, ~] = get_cfg(jobcfg, 'size_of_output_cube');
[overlap,~] = get_cfg(jobcfg, 'channel_cube_overlap_pixel');
cube_size = str2num(cube_size);
overlap = str2num(overlap);
chann_cube_size = cube_size + overlap/2; 
[~,assembly_size, ~] = get_hdf5_size(input_tile, '/main');

switch task_number
    case 1        
        fwd_jobmanager('cleft');
        
    case 2        
        fwd_jobmanager('vesicle');
        
    case 3        
        [chan_tbl, ~] = create_coordinate_table(jobcfg);
        [row,~] = size(chan_tbl);        
        parfor ridx=1:row
            cube_idx = chan_tbl{ridx,1};
            stp = chan_tbl{ridx,2};
            enp = chan_tbl{ridx,3};
            create_interface_cube(intf_path, seg_tile_path, cube_idx, stp, enp, 1);     
        end
        
    case 4       
        assemble_interface_cubes([intf_path, 'interface_relevant/'], savename_intf, chann_cube_size, overlap, assembly_size);
 %        assemble_interface_cubes('/data/lrrtm3_wt_syn/interface/interface_assemble_test2/','assemble_test', chann_cube_size, overlap, [4000,4000,1024]);    
 
    case 5        
        write_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_reassigned_210503.h5';
        intf_fixed_path = '/data/lrrtm3_wt_syn/assembly/interface_relevant_fixed_210503.h5';
        reassign_interface_id(['/data/lrrtm3_wt_syn/assembly/', savename_intf, '.h5'], write_path); 
        get_boundingbox(write_path); 
        correct_bbox(write_path, intf_fixed_path);       
        % Run get_boundingbox.mat and correct_bbox.mat to separate false merges, after reassign_interface_id is complete. 
    
    case 6        
        assemble_boundary_cubes([intf_path,'boundary/'], chann_cube_size, overlap,  assembly_size);
    
    case 7        
        assemble_fwd_output_cubes(cleft_cfg_path, savename_cleftprob,  assembly_size, -1, bndry_path);
    
    case 8        
        assemble_fwd_output_cubes(vesicle_cfg_path, savename_vesicleprob,  assembly_size, 1, bndry_path);
    
    case 9        
        fwd_assembly_path = '/data/lrrtm3_wt_syn/assembly/assembly_vesicle_prob_210503.h5';
        affinity_path = '/data/lrrtm3_wt_syn/assembly/vesicle_affinity_210503.h5';
        save_path = '/data/lrrtm3_wt_syn/assembly/vesicle_segmentation_210503_quick.h5';
        create_affinity_graph(fwd_assembly_path, affinity_path); 
        tic;
        segment_vesicle_cloud(save_path, affinity_path);
        toc;
                

end
end
