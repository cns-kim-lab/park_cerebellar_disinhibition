% requires
% getParallelFiberSkeleton.m
% dijkstra_root2all.cpp
% dijkstra_rootall.mexa64
% backgracking4teasar_old.m

% skeletonize l-PFs and t-PFs separately  

%% l-PF skeletonization

load('./additional_infos/pf_nott.mat');
load('./additional_infos/pf.mat');
spath = '/data/lrrtm3_wt_reconstruction/segment_mip2_all_cells_200313.h5'; % path to segmentation volume
write_path = '/data/research/cjpark147/conn_analysis/pf_skeletons.h5';

seg = h5read(spath, '/main');
vol_size = size(seg);
target_ids = pf_notT_ids;

%write_vol = zeros(vol_size, 'uint32');
skel_skips = [];
skel_branches = cell(numel(target_ids),2);

morph = 1;
draw_figure = 0;
tic;
for i = 1:numel(target_ids)
    killer_pf_id = target_ids(i);
    save('/data/research/cjpark147/conn_analysis/killer_pf_id.mat', 'killer_pf_id');
    [skel,dbf] = getParallelFiberSkeleton(seg, target_ids(i), morph, draw_figure);
    skel_branches{i,1} = target_ids(i);
    
    if ~isequal(skel,-1)        % if skeleton was successfully obtained
        
        branch_lengths = cellfun(@numel, skel)/3;       
        [~,idx] = max(branch_lengths);
        branches = skel{idx};
        skel_branches{i,2} = branches;
        
%        lin_idx = sub2ind(vol_size, branches(:,1), branches(:,2), branches(:,3));    
%        fprintf('%s%d\n', 'number of skel voxels: ', numel(lin_idx));
%        write_vol(lin_idx) = target_ids(i);
    else
        skel_skips = [skel_skips, target_ids(i)];
    end
    
    if mod(i,10) ==0
        fprintf('--------------------------------------\n');
        fprintf('%6d%s%d\n', i, ' /', numel(target_ids));
        fprintf('--------------------------------------\n');
    end
end
toc;

morph = 1;
draw_figure = 0;

for i = 1:numel(target_ids)
    killer_pf_id = target_ids(i);
    save('/data/research/cjpark147/conn_analysis/killer_pf_id.mat', 'killer_pf_id');
    skel = getParallelFiberSkeleton(seg, target_ids(i), morph, draw_figure);
    skel_branches_maybe_pf_t{i,1} = target_ids(i);
    
    if ~isequal(skel,-1)        % if skeleton was successfully obtained
        
        branch_lengths = cellfun(@numel, skel)/3;       
       
      %  branches = skel(branch_lengths > 50);
        branches = skel;
        skel_branches_maybe_pf_t{i,2} = branches;
        
%        lin_idx = sub2ind(vol_size, branches(:,1), branches(:,2), branches(:,3));    
%        fprintf('%s%d\n', 'number of skel voxels: ', numel(lin_idx));
%        write_vol(lin_idx) = target_ids(i);
    else
        skel_skips_t = [skel_skips_t, target_ids(i)];
    end
    
    if mod(i,10) ==0
        fprintf('--------------------------------------\n');
        fprintf('%6d%s%d\n', i, ' /', numel(target_ids));
        fprintf('--------------------------------------\n');
    end
end
toc;

%save('/data/research/cjpark147/conn_analysis/skel_branches_maybe_t_add.mat','skel_branches_maybe_pf_t');
%save('/data/research/cjpark147/conn_analysis/skel_skips_t.mat', 'skel_skips_t');
%h5create(write_path, '/main', vol_size, 'Datatype', 'uint32');
%h5write(write_path, '/main', write_vol);
%}