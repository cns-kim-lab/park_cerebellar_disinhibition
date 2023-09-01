function upscale_volume_of_target_cells (input_h5_dir,input_h5_file_name,input_mip_level,output_mip_level,target_cell_omni_id_list,method,multiplier)

    %% parameters
    % multiplier = 100;
    % input_h5_dir = '/data/research/iys0819/cell_morphology_pipeline/volumes';
    output_h5_dir = input_h5_dir;
    %% choose one among 'cubic','linear','nearest'
    % method = 'nearest'; 
    upscale_factor = 2^(input_mip_level - output_mip_level);

    %%
    fprintf('Loading input h5 file\n');
    input_h5_file_path = sprintf('%s/%s.h5',input_h5_dir,input_h5_file_name); 
    vol_input = h5read(input_h5_file_path,'/main');
    vol_output = uint32(zeros(size(vol_input).*upscale_factor));
    fprintf('Done.\n');
    
    %%
    fprintf('Extracting subcellular component ids of target cells\n');
    [segment_list,pos_start,pos_end] = list_ids_of_subcelluar_components_of_target_cell (vol_input,target_cell_omni_id_list,multiplier);
    fprintf('Done.\n');

    %%
    fprintf('Upscaling each segments\n');
    for i = 1:length(segment_list)

        segment_id = segment_list(i);
        fprintf('\t %d',segment_id);
        segment_offset = pos_start(i,:)-1;
        segment_offset_new = segment_offset .* upscale_factor;

        vol_target = vol_input == segment_id;
        vol_target = vol_target(pos_start(i,1):pos_end(i,1),pos_start(i,2):pos_end(i,2),pos_start(i,3):pos_end(i,3));
        vol_target = imresize3(double(vol_target),upscale_factor,'Method',method);
        [x,y,z] = ind2sub(size(vol_target),find(logical(vol_target)));
        ind_vol_target = sub2ind(size(vol_output),x+segment_offset_new(1),y+segment_offset_new(2),z+segment_offset_new(3));
        vol_output(ind_vol_target) = uint32(segment_id);

    end
    fprintf('\nDone.\n');

    %%
    fprintf('Writing a new h5 file\n');
    output_h5_path = sprintf('%s/%s.isotropic_upscale_to_mip%d.%s.h5',output_h5_dir,input_h5_file_name,output_mip_level,method);
    h5create(output_h5_path,'/main',size(vol_output),'ChunkSize',[128 128 128],'Datatype','uint32');
    h5write(output_h5_path,'/main',vol_output);
    fprintf('Done.\n');
    fprintf('Output h5 file path : %s\n',output_h5_path);

end

function [segment_list,pos_start,pos_end] = list_ids_of_subcelluar_components_of_target_cell (vol_input,target_cell_omni_id_list,multiplier)

    segment_list = [];
    pos_start = [];
    pos_end = [];
    
    for i = 1:length(target_cell_omni_id_list)

        target_cell_omni_id = target_cell_omni_id_list(i);
        vol_target = floor(vol_input./multiplier) == target_cell_omni_id;
        sub_component_id_of_target_cell = setdiff(unique(vol_input(vol_target)),0);
        
        [x,y,z] = ind2sub(size(vol_target),find(vol_target));
        pos_start = [pos_start; ones(length(sub_component_id_of_target_cell),3).*[min(x) min(y) min(z)]];
        pos_end = [pos_end; ones(length(sub_component_id_of_target_cell),3).*[max(x) max(y) max(z)]];

        segment_list = [segment_list; sub_component_id_of_target_cell];

    end

end
