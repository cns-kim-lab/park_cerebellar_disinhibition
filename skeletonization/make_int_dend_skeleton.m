

%% 
% int-ID 26 and 30 (idx = 9, 12) have dendrite with a small, marginal fragment.
% -> let's get rid of it.


[int_idx_9_branches, ~, dbf_9] = get_interneuron_dend_skeleton(vol_mip3, 26, 1.2, 5, true, true, false);
[int_idx_12_branches, ~, dbf_12] = get_interneuron_dend_skeleton(vol_mip3, 30, 1.2, 5, true, true, false);
[int_idx_18_branches, ~, dbf_18] = get_interneuron_dend_skeleton(vol_mip3, 30, 1.2, 5, true, true, false);

% -> seems no problem

int_dendrite_branches{9} = int_idx_9_branches;
int_dendrite_branches{12} = int_idx_12_branches;
int_dendrite_branches{18} = int_idx_18_branches;
int_dendrite_dbf{9} = dbf_9;
int_dendrite_dbf{12} = dbf_12;
int_dendrite_dbf{18} = dbf_18;


% int-ID 68 (idx = 18) also has same issue, so corrected exactly same way.
%   (in command window)
%}