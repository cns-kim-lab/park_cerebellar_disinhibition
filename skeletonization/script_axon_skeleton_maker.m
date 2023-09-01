
vol = h5read(interneuron_axon_separated_seg_vol_h5_path, '/main');
% vol = h5read('/data/lrrtm3_wt_reconstruction/axon_separation.20210105.cb_cut.h5', '/main');
load('./additional_infos/axon_starting_point_include_new.mat')
load('./additional_infos/int_dend_and_axon_skeleton_20210122.mat', 'list_of_target_interneurons_axon_id_in_pruned_volume_new');
load('./additional_infos/int_dend_and_axon_skeleton_20210122.mat', 'list_of_target_interneurons_new');

%%
%To isotropic mip2 (-> Error occurs)
% vol = imresize3(vol, 'Scale', [1 1 4], 'Method', 'nearest');

%To isotropic mip3
vol_mip3 = imresize3(vol, 'Scale', [1 1 2], 'Method', 'nearest');
vol_mip3 = vol_mip3(1:2:end, 1:2:end, :);

% clear('vol');
%%
% ii = 1;

int_axon_branches = cell(numel(list_of_target_interneurons_new), 1);
int_axon_branch_termini = int_axon_branches;

for ii = 1:numel(list_of_target_interneurons_new)
    [branch_path_sub, branch_terminal]= get_interneuron_axon_skeleton(vol_mip3, list_of_target_interneurons_axon_id_in_pruned_volume_new(ii), round(axon_starting_point(ii, :)/8), ...
        1.2, 10, true, false, false);
    int_axon_branches{ii} = branch_path_sub;
    int_axon_branch_termini{ii} = branch_terminal;
end

%%
% Int-ID 19 has fragmemted axon.
% -> have to discard small fragmemts.
[branch_path_sub, branch_terminal]= get_interneuron_axon_skeleton(vol_mip3, list_of_target_interneurons_axon_id_in_pruned_volume_new(5), round(axon_starting_point(5, :)/8), ...
    1.2, 10, true, true, false);
int_axon_branches{5} = branch_path_sub;
int_axon_branch_termini{5} = branch_terminal;

%%
int_dendrite_branches = cell(numel(list_of_target_interneurons_new), 1);
int_dendrite_branch_termini = int_dendrite_branches;

for ii = 1:numel(list_of_target_interneurons_new)
    [branch_path_sub, branch_terminal]= get_interneuron_dend_skeleton(vol_mip3, list_of_target_interneurons_new(ii), 1.2, 5, true, false, false);
    int_dendrite_branches{ii} = branch_path_sub;
    int_dendrite_branch_termini{ii} = branch_terminal;
end

%%
% int-ID 26 and 30 (idx = 9, 12) have dendrite with a small, marginal fragment.
% -> let's get rid of it.

[int_idx_9_branches, ~] = get_interneuron_dend_skeleton(vol_mip3, 26, 1.2, 5, true, true, false);
[int_idx_12_branches, ~] = get_interneuron_dend_skeleton(vol_mip3, 30, 1.2, 5, true, true, false);

% -> seems no problem
%
int_dendrite_branches{9} = int_idx_9_branches;
int_dendrite_branches{12} = int_idx_12_branches;

% int-ID 68 (idx = 18) also has same issue, so corrected exactly same way.
%   (in command window)

%%
%
k = 9;

skel_voxels = vertcat(int_dendrite_branches{k}{:});
% skel_voxels = vertcat(int_idx_12_branches{:});
skel_voxels = skel_voxels*8;

figure;
scatter3(skel_voxels(:, 1), skel_voxels(:, 2), skel_voxels(:, 3), '.k');
axis equal
%