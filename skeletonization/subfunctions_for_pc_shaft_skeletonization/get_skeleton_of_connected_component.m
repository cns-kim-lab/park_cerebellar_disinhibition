
% Input :
% 'target_volume_h5' : the target h5 file. Expected to be segment_mip2_all_cells.
% 'target_segment_omni_id' : omni id of the target PF.
% 'close_or_not' : decide whether we apply 'prepare_skeleton_for_skeletonization' which includes closing operation.
% 'draw_figure' : draw figure or not.

% Output :
% 'branch_path_sub' : cell array of the subscripts of the voxels in each branch path, in terms of the target volume in the inputs.

function [branch_path_sub, branch_path_dbf, branch_terminal_1_sub, branch_terminal_2_sub, dil_count] = get_skeleton_of_connected_component(target_connected_component, volume_size, rt_pnt, close_or_not, p_scale, p_const)

    offset_original = [0 0 0];                                                                 % Set offset_original if the target volume has nonzero offset.
    margin = 2;                     % create marginal rooms for pf bounding box.
    
        
    % [volume_new,offset_new] = cut_volume_to_fit_target_segment (volume, target_segment_omni_id);
    [volume_new,offset_new] = cut_volume_to_fit_target_segment (target_connected_component, volume_size, margin);
    dil_count = 0;
    
    if close_or_not
        fill_or_not = 0;
        [volume_new, dil_count] = prepare_volume_for_skeletonization (volume_new, fill_or_not);
        % Change the morphological operations if the results are not good.
        
        if numel(volume_new) == 1           % if morphological operation fails,
            branch_path_sub = -1;           % return -1 and end function 
            return;
        end
        
        volume_new_trim = false(size(volume_new));
        volume_new_trim(1+margin:end-margin,1+margin:end-margin,1+margin:end-margin) = volume_new(1+margin:end-margin,1+margin:end-margin,1+margin:end-margin);   % remove dilated segments in marginal area.
        volume_new = volume_new_trim;
        clear volume_new_trim;
    end

 %   fprintf('Applying TEASAR algorithm...\n');
    % fprintf('Obtaining DBF\n');
    dbf = bwdist(~volume_new);
    dbf = double(dbf);
    vol_size = size(volume_new);

    if isempty(rt_pnt)
        rt_pnt = select_root_voxel (volume_new,dbf);
    else
        rt_pnt = rt_pnt - offset_new;
    end
    
    rt_ind = sub2ind(vol_size,rt_pnt(1),rt_pnt(2),rt_pnt(3));
    
    % fprintf('Obtaining PDRF\n');
    [pdrf, indfrom, ~] = ...
        dijkstra_root2all(dbf, vol_size, rt_pnt, 1);
    pdrf = pdrf.*volume_new;

    % fprintf('Obtaining DSF from the source [%d, %d, %d]\n',rt_pnt+offset_new);
    [dsf, ~, ~] = ...
        dijkstra_root2all(dbf, vol_size, rt_pnt, 0);
    dsf = dsf.*volume_new;
   
    % fprintf('Backtracking branch paths using TEASAR algorithm\n');
%    p_scale = 1.2;
%    p_const = 20;
    [~, branch_path, branch_terminal] = ...
        backtracking4teasar_old(dbf, dsf, pdrf, indfrom, p_scale, p_const, rt_ind, vol_size);
    
    branch_path_dbf = cellfun(@(x) dbf(x), branch_path,'UniformOutput',false);
    
    branch_path_sub = cellfun(@(x) ind2pnt(vol_size,x'), branch_path, 'UniformOutput', false);
    branch_path_sub = cellfun(@(x) x + offset_new - offset_original, branch_path_sub, 'UniformOutput',false);
    
    branch_terminal_1_sub = arrayfun(@(x) ind2pnt(vol_size,x), branch_terminal(:,1), 'UniformOutput', false);
    branch_terminal_2_sub = arrayfun(@(x) ind2pnt(vol_size,x), branch_terminal(:,2), 'UniformOutput', false);
    
    branch_terminal_1_sub = cellfun(@(x) x + offset_new - offset_original, branch_terminal_1_sub, 'UniformOutput',false);
    branch_terminal_2_sub = cellfun(@(x) x + offset_new - offset_original, branch_terminal_2_sub, 'UniformOutput',false);
    
    
%    fprintf('Done.\n');

end

function [volume_new, offset_new] = cut_volume_to_fit_target_segment (target_connected_component, volume_size, margin)

    [x,y,z] = ind2sub(volume_size,target_connected_component);
    min_x = min(x); min_y = min(y); min_z = min(z);
    max_x = max(x); max_y = max(y); max_z = max(z);
    x = x - min_x + 1 + margin;
    y = y - min_y + 1 + margin;
    z = z - min_z + 1 + margin;
    volume_new = false(max_x-min_x+1+(margin*2),max_y-min_y+1+(margin*2),max_z-min_z+1+(margin*2));
    new_ind = sub2ind(size(volume_new),x,y,z);
    % +-margin around the min & max
    volume_new(new_ind) = true;
    offset_new = [min_x, min_y, min_z] - 1 - margin;

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

function [volume_new,count] = prepare_volume_for_skeletonization (volume_new, fill_or_not)
    
    se = strel('sphere',1); 
    cc = bwconncomp(volume_new);
    
    number_of_connected_components = cc.NumObjects;
    count = 0;
    
    while number_of_connected_components ~= 1
        volume_new = imdilate(volume_new,se);      % connect possibly-disjoint segments 
        cc = bwconncomp(volume_new);
%        fprintf('%s\n', 'dilating PF by 1 unit...');
        count = count + 1;
%        if count > 5
%            fprintf('%s%d\n', '----------------- too many dilations on pf ',  target_segment_omni_id);
%            volume_new_deformed = -1;   
%            break;
%        end

        fprintf('Number of connected components after %d times dilation: %d',count,cc.NumObjects);
        fprintf('\n');
    end
    

%    if count > 5
%        return;
%    end
  %  se = strel('cuboid',[9,9,5]);
  %  volume_new_deformed = imclose(volume_new_deformed, se);
  if fill_or_not
    volume_new = imfill(volume_new, 'holes');
  end
  
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
