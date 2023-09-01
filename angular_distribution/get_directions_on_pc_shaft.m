% target_cell_id_list = [18 11 13 21 20 81 49 82 50 78 83 48 175];
function get_directions_on_pc_shaft (target_cell_id)

    addpath ./subfunctions_for_get_directions_on_pc_shaft/
% for i=1:length(target_cell_id_list)
%% 0. load data
%     target_cell_id = target_cell_id_list(i);
    pc_shaft_skeleton_dir = '/data/research/iys0819/cell_morphology_pipeline/result/skeleton_pc_shaft';
    load(sprintf('%s/shaft_skeleton_of_cell_%d.ps_1.050_pc_10.mat',pc_shaft_skeleton_dir,target_cell_id));

    merged_extended_pos = cellfun(@(skel) cell2mat(skel'),extended_skeleton_of_ccs_pos,'UniformOutput',false);
    merged_extended_dbf = cellfun(@(dbf) cell2mat(dbf),extended_skeleton_of_ccs_dbf,'UniformOutput',false);

    merged_pos = cellfun(@(skel) cell2mat(skel'),skeleton_of_ccs_pos,'UniformOutput',false);
    merged_dbf = cellfun(@(dbf) cell2mat(dbf),skeleton_of_ccs_dbf,'UniformOutput',false);

%% 1. derive directional vectors along skeleton branches
    directional_vectors = cellfun(@(branch) get_directional_vector(branch,2),skeleton_of_ccs_pos,'UniformOutput',false);
    merged_dir = cellfun(@(skel) cell2mat(skel'),directional_vectors,'UniformOutput',false);

% %% 1-1. visualize the directional vectors
%     figure; hold on; cellfun(@(skel,dbf) scatter3(skel(:,1),skel(:,2),skel(:,3),dbf*30,[rand rand rand],'.'),merged_extended_pos,merged_extended_dbf);
%     set(gca,'DataAspectRatio',[1 1 1]);
%     cellfun(@(skel,direction) quiver3(skel(:,1),skel(:,2),skel(:,3),direction(:,1),direction(:,2),direction(:,3)),merged_pos,merged_dir);

%% 2. derive mean direction of skeleton  
    pc_surf_regress = [ones(size(merged_skeleton_total_pos,1),1) merged_skeleton_total_pos(:,1:2)]\merged_skeleton_total_pos(:,3);
    normal_of_mean_plane = [-pc_surf_regress(2) -pc_surf_regress(3) 1]./vecnorm([-pc_surf_regress(2) -pc_surf_regress(3) 1],2);

%% 2-1. visualize the mean plane described by the regression
    min_x = min(merged_skeleton_total_pos(:,1));
    min_y = min(merged_skeleton_total_pos(:,2));
    min_z = min(merged_skeleton_total_pos(:,3));
    max_x = max(merged_skeleton_total_pos(:,1));
    max_y = max(merged_skeleton_total_pos(:,2));
    max_z = max(merged_skeleton_total_pos(:,3));
    
    x_lattice_num = 50;  
    grid_x = linspace(min_x,max_x,x_lattice_num);
    lattice_size = grid_x(2)-grid_x(1);
    grid_y = [min_y:lattice_size:max_y];

    [mesh_y,mesh_x] = meshgrid(grid_y, grid_x);
    mesh_z = pc_surf_regress(1) + mesh_x.* pc_surf_regress(2) + mesh_y.*pc_surf_regress(3);
    %%
    figure; hold on; cellfun(@(skel,dbf) scatter3(skel(:,1),skel(:,2),skel(:,3),dbf*30,[rand rand rand],'.'),merged_extended_pos,merged_extended_dbf);
    set(gca,'DataAspectRatio',[1 1 1]);
    axis off;
    set(gcf,'Color','w');
    %%
    surf(mesh_x,mesh_y,mesh_z);
    midpoint = [grid_x(round(length(grid_x)/2)) grid_y(round(length(grid_y)/2)) mesh_z(round(length(grid_x)/2),round(length(grid_y)/2))];
    %%
    quiver3(midpoint(1),midpoint(2),midpoint(3),normal_of_mean_plane(1),normal_of_mean_plane(2),normal_of_mean_plane(3),100,'r','LineWidth',3);
    
%% 3. merge branches of directional vectors into an array

    merged_merged_dir = cell2mat(merged_dir');
    merged_merged_pos = cell2mat(merged_pos');
    merged_merged_dbf = cell2mat(merged_dbf);
    % uniqueness of voxels in skeleton_of_ccs_pos?
%     [unique_merged_merged_pos,uniqueness_merged_merged_pos] = unique(merged_merged_pos,'rows','stable');
    
%% 4. derive horizontal, vertical vectors

    horizontal_vector = get_horizontal_vector_from_skeleton_directions_and_plane_normal (merged_merged_dir,normal_of_mean_plane);
    vertical_vector = get_vertical_vectors_from_skeleton_directions_and_horizontal (merged_merged_dir,horizontal_vector);

%% 4-1. visualize horizontal, vertical vectors

    figure; hold on; cellfun(@(skel,dbf) scatter3(skel(:,1),skel(:,2),skel(:,3),dbf*30,[rand rand rand],'.'),merged_extended_pos,merged_extended_dbf);
    set(gca,'DataAspectRatio',[1 1 1]);
    quiver3(merged_merged_pos(:,1),merged_merged_pos(:,2),merged_merged_pos(:,3),merged_merged_dir(:,1),merged_merged_dir(:,2),merged_merged_dir(:,3));
    quiver3(merged_merged_pos(:,1),merged_merged_pos(:,2),merged_merged_pos(:,3),horizontal_vector(:,1),horizontal_vector(:,2),horizontal_vector(:,3));
    quiver3(merged_merged_pos(:,1),merged_merged_pos(:,2),merged_merged_pos(:,3),vertical_vector(:,1),vertical_vector(:,2),vertical_vector(:,3));

%% 5. save the result
    output_dir = '/data/research/iys0819/cell_morphology_pipeline/result/directions_on_skeleton_pc_shaft';
    output_file_name = sprintf('%s/directions_on_shaft_skeleton_of_cell_%d.mat',output_dir,target_cell_id);
    save(output_file_name,'merged_merged_dir','merged_merged_pos','merged_merged_dbf','normal_of_mean_plane','horizontal_vector','vertical_vector');
    clear
    
end
