
%% Fraction of reconstruction
%{
chunksize = [512,512,128];
overlap = [32, 32, 8];
recon_rate = zeros(29,20,8);
for i = 3:1:29
    for j = 3:1:20
        for k = 2:1:8

            % Get subvol's global location
            stp = (chunksize - overlap) .* ([i,j,k]-1) + 1;
            enp = stp + (chunksize - overlap) - 1;
            num_elem = enp - stp + 1;

            % Fraction of segmented voxels
            subvol = h5read('/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_210503.h5','/main', stp, num_elem);
            recon_rate(i,j,k) = nnz(subvol)/numel(subvol);
        end
        fprintf('%d, %d\n', i, j);
    end
end
%save('/data/research/cjpark147/code/conn/about_data_volume/fraction_of_reconstruction.mat','recon_rate');
%}
% recon_fraction = sum(recon_rate,'all')/numel(recon_rate);
% recon fraction = 0.562 (x1~2, x30~31, y1~2, y21~y22, z1, z9 subvolumes are not included.) 


%% Random sampling of non-reconstructed voxels for non-reconstructed cell-type estimation.

%{
subvol_list = [3,11,4; 6,11,4; 9,11,4; 12,11,4; 15,11,3];   % linear sample
%subvol_list = [10,14,6; 21,17,5; 18,12,2; 13,3,3; 14,6,2];   % random sample
[nvol,~] = size(subvol_list);
chunksize = [512,512,128];
overlap = [32, 32, 8];
for i = 1:nvol

    % Get subvol's global location
    stp = (chunksize - overlap) .* (subvol_list(i,:)-1);
    enp = stp + chunksize - 1;
    num_elem = enp - stp + 1;
    
    % List of non-recon voxels given subvol
    subvol = h5read('/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_210503.h5','/main', stp, num_elem);
    %subvol = subvol(33:end-32, 33:end-32, 9:end-8);
    
    [nx,ny,nz] = ind2sub(size(subvol), find(subvol == 0));
    N = [nx+stp(1)+31, ny+stp(2)+31, nz+stp(3)+6];
    %N = [nx+stp(1)-1, ny+stp(2)-1, nz+stp(3)-1];
    % Randomly sample voxels 
    [np,~] = size(N);
    samples = N(randsample(np, 300),:)';
    n_total = numel(subvol);
    fprintf('%d,%d\n', np, n_total);
    %write_to_omni(samples, subvol_list(i,:));
end
%}

 %% Random sampling of reconstructed voxels for reconstructed cell-type estimation.

 %{
addpath /data/research/cjpark147/code/matlab/mysql/
omni_db_name = 'omni_20210503';
h_sql = mysql('open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
rtn = mysql(h_sql, ['use ', omni_db_name]);
  
subvol_list = [3,11,4; 6,11,4; 9,11,4; 12,11,4; 15,11,3];   % linear sample
%subvol_list = [10,14,6; 21,17,5; 18,12,2; 13,3,3; 14,6,2];   % random sample
[nvol,~] = size(subvol_list);
chunksize = [512,512,128];
overlap = [32, 32, 8];
reconcelltypes = zeros(500, 2);

for i = 1:nvol
    % Get subvol's global location
    stp = (chunksize - overlap) .* (subvol_list(i,:)-1);
    enp = stp + chunksize - 1;
    num_elem = enp - stp + 1;
    
    % List of non-recon voxels given subvol
    subvol = h5read('/data/lrrtm3_wt_reconstruction/segment_mip0_all_cells_210503.h5','/main', stp, num_elem);
    %subvol = subvol(33:end-32, 33:end-32, 9:end-8);
    [nx,ny,nz] = ind2sub(size(subvol), find(subvol ~= 0));
    N = [nx, ny, nz];
    [np,~] = size(N);
    samples = N(randsample(np, 100),:);
    n_total = numel(subvol);
    fprintf('%f\n', np/ n_total);
    
    %{
    for j = 1:length(samples)
        segid = subvol(samples(j,1), samples(j,2), samples(j,3));
        if segid == 37971
            this_type = 5;
        else
            query = sprintf('SELECT m.type1 FROM cells c INNER JOIN cell_metadata m ON m.id=c.meta_id WHERE c.status=1 AND m.omni_id=%d LIMIT 1;', segid);
            this_type = mysql(h_sql, query);
        end
        reconcelltypes((i-1)*length(samples)+j,1) = segid;
        reconcelltypes((i-1)*length(samples)+j,2) = this_type;
    end
    %}
end
mysql(h_sql, 'close');
%}


%% stats

%{
fid = fopen('/data/research/cjpark147/code/conn/about_data_volume/noseg_voxel_samples/celltype_done_x15_y11_z03.yml', 'r');
line = fgetl(fid);
types = zeros(100,1);
for i = 1:300
    line = fgetl(fid);
    if mod(i,3) == 0
        k = strfind(line, 'nt:');
        str = line(k+4:k+5);
        if isequal(str, 'pc')
            types(i/3,1) = 1;
        elseif isequal(str, 'pf')
            types(i/3,1) = 2;
        elseif isequal(str, 'cf')
            types(i/3,1) = 3;  
        elseif isequal(str, 'in')
            types(i/3,1) = 4;
        elseif isequal(str, 'gl')
            types(i/3,1) = 5;
        elseif isequal(str, 'go')
            types(i/3,1) = 6;
        end        
    end
end
pc = sum(types==1);
pf = sum(types==2);
cf = sum(types==3);
in = sum(types==4);
gl = sum(types==5);
go = sum(types==6);
fprintf('%s%d\n%s%d\n%s%d\n%s%d\n%s%d\n%s%d\n', 'pc-', pc, 'pf-', pf, 'cf-', cf, 'in-', in, 'gl-', gl, 'go-', go);
%}

% unrecon voxels
vpc = 1;
vpf = 40+14+23+6+14;
vcf = 0;
vin = 4;
vgl = 56+86+76+94+86;

% recon voxels
%vrecon = histc(reconcelltypes(:,2), unique(reconcelltypes(:,2)));
vrpc = 166;
vrpf = 213;
vrcf = 9;
vrin = 112;

%% Toss samples to omni_annotation tool. 

function write_to_omni(samples, vol_idx)

    SelectedSegments = 1;
    xds = 1;     yds = 1;   zds = 4;
    offset = [0,0,0];
    fgroup = fopen(sprintf('%s%d%s%d%s%d%s', 'annotationGroups_', vol_idx(1), '_', vol_idx(2), '_', vol_idx(3),'.yml'),'w');
    fpoint = fopen(sprintf('%s%d%s%d%s%d%s', 'annotationPoints_', vol_idx(1), '_', vol_idx(2), '_', vol_idx(3),'.yml'),'w');
    fprintf(fgroup, '%s\n', '---');
    fprintf(fpoint, '%s\n', '---');

    Label = {'1-1'};
    Group = unique(Label);

    % Create annotationGroups.yml
    for i = 1:length(Group)    
        str = strsplit(Group{i},'-');
        if ~(ismember(str2double(str{1}(1:end-2)), SelectedSegments) || ismember(str2double(str{2}(1:end-2)), SelectedSegments))
            Color = [185,215,160];
            fprintf(fgroup, '%s%d\n', '- id: ', i);
            fprintf(fgroup, '%s\n', '  enabled: true');    
            fprintf(fgroup, '%s%d%s%d%s%d%s%d%s%d%s\n', '  value: {segID: ', str2double(str{1}), ', name: contact to ', str2double(str{2}), ', visualize: true, color: [',Color(1), ', ',Color(2),', ',Color(3),']}' );
        end
    end
    fprintf(fgroup, '%s\n', '...');
    fclose(fgroup);

    % Create annotationPoints.yml
    for i = 1:length(samples)
        x = samples(1,i);   y = samples(2,i);   z = samples(3,i);
        str = Label(1);
        str2 = strsplit(str{1},'-');
        if ~(ismember(str2double(str2{1}(1:end-2)), SelectedSegments) || ismember(str2double(str2{2}(1:end-2)), SelectedSegments))
            xt = (x) * xds + offset(1);     yt = (y) * yds + offset(2);   zt = (z) * zds + offset(3);
            str3 = [', name: ', str2{2}, ', comment: ~, coord: ['];
            fprintf(fpoint, '%s%d\n%s\n%s%d%s%d%s%d%s%d%s\n', '- id: ', i, '  enabled: true', '  value: {groupID: ', find(strcmp(Group,Label(1))), str3, xt, ', ', yt, ', ', zt, '], linkedAnnotationID: 0}');
        end
    end
    fprintf(fpoint, '%s\n', '...');
    fclose(fpoint);
end