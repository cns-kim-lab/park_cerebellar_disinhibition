
% assemble Cleft-Net, Vesicle-Net output cubes and do masking 

function assemble_fwd_output_cubes(cfg_path, save_name, assembly_size, invert_mask, mask_path)
    addpath /data/research/cjpark147/code/hdf5_ref
    ChunkSize = [512,512,128];

    assembly_path = ['/data/lrrtm3_wt_syn/assembly/assembly_', save_name, '.h5'];
    if ~isfile(assembly_path)
        h5create(assembly_path, '/main', assembly_size, 'Datatype', 'single', 'ChunkSize', ChunkSize);
 %       h5write(assembly_path, '/main', zeros(assembly_size, 'single'));
    end
    jobcfg = parsing_jobconfig(cfg_path);
    [chan_tbl, fwd_tbl] = create_coordinate_table(jobcfg);
    [row,~] = size(fwd_tbl);

    for ridx=1:row
        stp = fwd_tbl{ridx,4};
        enp = fwd_tbl{ridx,5};
        [valid_prob_cube, valid] = get_valid_prob_cube(jobcfg, ridx, chan_tbl, fwd_tbl);

        if valid ~= 1
            disp('invalid fwd cubes');
            break;
        end
        
        num_elem = enp-stp+1;
        if invert_mask == 1
            mask = h5read(mask_path, '/main', stp, num_elem);
            valid_prob_cube = valid_prob_cube .* (mask == 0 );
        elseif invert_mask == 0
            mask = h5read(mask_path, '/main', stp, num_elem);
            valid_prob_cube = valid_prob_cube .* (mask > 0 );
        elseif invert_mask == -1
            
        end
        
        h5write(assembly_path, '/main', valid_prob_cube, stp, num_elem);
        disp(['assembled ', num2str(ridx), ' /', num2str(row), ' inference cubes ( ', save_name, ' )']); 

    end    

end

