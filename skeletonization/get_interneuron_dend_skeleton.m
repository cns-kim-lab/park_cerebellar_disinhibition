
% Input :
% 'target_volume_h5' : path to the target h5 file. Expected to be segment_mip2_all_cells.
% 'target_segment_omni_id' : omni id of the target PF.
% 'close_or_not' : decide whether we apply 'prepare_skeleton_for_skeletonization' which includes closing operation.
% 'largest_cc_only' : Error occurs if the segment is disconnected. Given 1, leave the largest connected component only.
% 'draw_figure' : draw figure or not.

% Output :
% 'branch_path_sub' : cell array of the subscripts of the voxels in each branch path, in terms of the target volume in the inputs.

%function branch_path_sub = get_interneuron_axon_skeleton(target_volume_h5, target_segment_omni_id, close_or_not, largest_cc_only, draw_figure)
function [branch_path_sub, branch_terminal, dbf]= get_interneuron_dend_skeleton(volume, target_segment_omni_id, p_scale, p_const, close_or_not, largest_cc_only, draw_figure)

    fprintf('Loading the target volume...\n');
%    volume = h5read(target_volume_h5,'/main');
    offset_original = [0 0 0];                                                                 % Set offset_original if the target volume has nonzero offset.
    fprintf('Done.\n');

    
    fprintf('Extracting a boolean array for the target segment from the original volume...\n');  
    [volume_new,offset_new] = cut_volume_to_fit_target_segment_dend_plus_cellbody (volume, target_segment_omni_id, largest_cc_only);
    vol_size = size(volume_new);
    volume_new_cellbody = volume(offset_new(1)+1:offset_new(1)+vol_size(1),offset_new(2)+1:offset_new(2)+vol_size(2),offset_new(3)+1:offset_new(3)+vol_size(3));
    volume_new_cellbody = volume_new_cellbody == target_segment_omni_id*100+99;
    fprintf('Done.\n');

    % rt_pnt = select_root_voxel (volume_new,dbf);
    rt_pnt = locate_cellbody_center (volume_new_cellbody);
    rt_ind = sub2ind(vol_size,rt_pnt(1),rt_pnt(2),rt_pnt(3));

    if close_or_not
        fprintf('Applying morphological operations to PF segment...\n');
        volume_new = remove_face (volume_new);
        cc_volume_new = bwconncomp(volume_new);
        num_cc_volume_new = length(cc_volume_new.PixelIdxList);
        iteration_count = 0;
        while num_cc_volume_new ~= 1
            volume_new = prepare_volume_for_skeletonization (volume_new);                              % Change the morphological operations if the results are not good.
            volume_new_cellbody = prepare_volume_for_skeletonization (volume_new_cellbody);
            
            volume_new = remove_face (volume_new);
            volume_new_cellbody = remove_face (volume_new_cellbody);
            
            cc_volume_new = bwconncomp(volume_new);
            num_cc_volume_new = length(cc_volume_new.PixelIdxList);
            iteration_count = iteration_count + 1;
        end
        fprintf('Components are connected after %d dilations.\n',iteration_count);
        fprintf('Done.\n');
    end
   
    fprintf('Applying TEASAR algorithm...\n');
    dbf = bwdist(~volume_new);
    dbf = double(dbf);

    
    [pdrf, indfrom, ~] = ...
        dijkstra_root2all(dbf, vol_size, rt_pnt, 1);
    pdrf = pdrf.*volume_new;

    [dsf, ~, ~] = ...
        dijkstra_root2all(dbf, vol_size, rt_pnt, 0);
    dsf = dsf.*((volume_new-volume_new_cellbody)>0);

%    p_scale = 1.2;
%    p_const = 10;
    [~, branch_path, branch_terminal] = ...
        backtracking4teasar_old(dbf, dsf, pdrf, indfrom, p_scale, p_const, rt_ind, vol_size);
    
    branch_path_sub = cellfun(@(x) ind2pnt(vol_size,x'), branch_path, 'UniformOutput', false);
    branch_path_sub = cellfun(@(x) x + offset_new - offset_original, branch_path_sub, 'UniformOutput',false);
        
    fprintf('Done.\n');

    if draw_figure
    figure; hold on; cellfun(@(x) scatter3(x(:,1),x(:,2),x(:,3)),branch_path_sub); set(gca, 'DataAspectRatio', [4 4 1]);
    end

end

function [volume_new, offset_new] = cut_volume_to_fit_target_segment_dend_plus_cellbody (volume, target_segment_omni_id, largest_cc_only)

    volume_target = false(size(volume));
    volume_target (volume == target_segment_omni_id*100) = 1;
    volume_target (volume == target_segment_omni_id*100 + 99) = 1;

    if largest_cc_only
        volume_target = volume_target .* leave_the_largest_cc_only(volume_target);
    end
        
    [x,y,z] = ind2sub(size(volume_target),find(volume_target));
    min_x = min(x); min_y = min(y); min_z = min(z);
    max_x = max(x); max_y = max(y); max_z = max(z);

    volume_new = false(max_x-min_x+3,max_y-min_y+3,max_z-min_z+3);
    % +-1 around the min & max
    volume_new(2:end-1,2:end-1,2:end-1) = volume_target (min_x:max_x,min_y:max_y,min_z:max_z);
    offset_new = [min_x, min_y, min_z] - 2;

end

function volume = leave_the_largest_cc_only(volume)
    cc = bwconncomp(logical(volume));
    size_cc = cellfun(@length,cc.PixelIdxList);
    [~,largest_cc_ind] = max(size_cc);
    
    volume = false(size(volume));
    volume(cc.PixelIdxList{largest_cc_ind}) = true;
end

function volume = remove_face (volume)
    volume(1,:,:) = 0;
    volume(end,:,:) = 0;
    volume(:,1,:) = 0;
    volume(:,end,:) = 0;
    volume(:,:,1) = 0;
    volume(:,:,end) = 0;
end

function root_position = select_root_voxel (volume_new,dbf)
    
    vol_size = size(volume_new);
    seg_inds = find(volume_new);
    random_voxel = randi(numel(seg_inds));
    [sub_x,sub_y,sub_z] = ind2sub(vol_size,seg_inds(random_voxel));
    random_voxel_sub = [sub_x sub_y sub_z];

    [daf,~,~] = dijkstra_root2all(dbf,vol_size,random_voxel_sub,0);
    daf = daf.*volume_new;
    [~,root_position_ind] = max(daf(:));
    [root_position_x,root_position_y,root_position_z] = ind2sub(vol_size,root_position_ind);
    root_position = [root_position_x, root_position_y, root_position_z];

end

function root_position = locate_cellbody_center (volume_new_cellbody)

    cellbody_ind = find(volume_new_cellbody);
    [cellbody_sub_x,cellbody_sub_y,cellbody_sub_z] = ind2sub(size(volume_new_cellbody),cellbody_ind);
    root_position = round(median([cellbody_sub_x,cellbody_sub_y,cellbody_sub_z],1));
    
end


function volume_new_deformed = prepare_volume_for_skeletonization (volume_new)

    %se = strel('cuboid',[17 17 5]);
    %se = strel('cuboid', [3 3 3]);
    se = strel('sphere', 1);
    %volume_new_deformed = imclose(volume_new,se);
    volume_new_deformed = imdilate(volume_new,se);
    
end

function pnt = ind2pnt(vol_size,ind)

    pnt = zeros(size(ind,1),3);
    [pnt(:,1),pnt(:,2),pnt(:,3)] = ind2sub(vol_size,ind);
    
end

% Procedure
%
% 0. Preparation : remove singularities through successive morphological operations.  
%
%
% 1. Set a root point to the segment    : Give the position of a root voxel as subscripts in (cropped) volume used for analysis.
%                                       : Or, select a root voxel using DAF.
%
% 2. Get 'DBF' of the voxels in the segment, using 'bwdist' function.
%
% 
% 3. 'dijkstra_root2all' : DBF, volumeSize, root(subscripts), PenalizeOrNot==1 -> PDRF, indfrom
%           parameters  : propotional constant ('5000') and the power ('32') in the 'penalty' function in 'dijkstra_root2all.cpp'
%
% 4. 'dijkstra_root2all' : DBF, volumeSize, root(subscripts), PenalizeOrNot==0 -> DSF, indfrom_dsf
%
%
% 5. 'backtracking4teasar_old' : DBF, DSF, PDRF, indfrom, 'p_scale', 'p_const', root(linear index)
%           parameters  : p_scale, p_const
%                       : parameters that determine removal of a traced branch from the volume, to trace other branches.
%                       : For PCs, p_scale = 1.2; p_const = 20;
