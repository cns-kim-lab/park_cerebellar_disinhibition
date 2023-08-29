
% vesicle segmentation from the assembly of unet outputs.


function segment_vesicle_cloud(save_path, vesicle_unet_output)
    
    addpath('/data/research/cjpark147/code/watershed_new/');
    path_hdf5_watershed = sprintf(save_path);

    % % gaussian blur
    % sigma = 2.0;
    % inf_vol = imgaussfilt3(inf_vol, sigma);

    % inf_vol = permute(inf_vol, [2 1 3]);
     


    % wsth = 0.9;       %high
    % wsth_low = 0.85;     %low
    % wsdust = 3000;       %dust
    % wsdust_th = 0.9;    %dust_low

    %new parameter
    wsth = 0.9;       %high
    wsth_low = 0.6;     %low
    wsdust = 1500;       %dust
    wsdust_th = 0.5;    %dust_low

    % %test parameter for net022
    % wsth = 0.5;       %high
    % wsth_low = 0.3;     %low
    % wsdust = 1000;       %dust
    % wsdust_th = 0.5;    %dust_low


    wswidth = 128;      %width     set to an interger diver of whole assembly size
    wsthread = 16;      %nthread

    wsparam_set = struct('high', wsth, 'low', wsth_low, 'dust', wsdust, ...
        'dust_low', wsdust_th, 'threads', wsthread, 'width', wswidth);
    
 %    affinity = binary_to_affinity(vesicle_unet_output);     % To make inf_vol a 4-D tensor.
 %    [~,~,~] = aff2seg_detail(affinity, 'matrix', path_hdf5_watershed, 1, wsparam_set);

     
     [~,~,~] = aff2seg_detail(vesicle_unet_output, 'file', path_hdf5_watershed, 1, wsparam_set);
    
    %
    % label_vol = h5read(path_hdf5_watershed, '/main');
    % remove_false_positives(inf_vol, label_vol);

    % % lvol = watershed(inf_vol);
    % lvol = h5read(path_hdf5_watershed, '/main');
    % show_image(lvol);

    %

end


%% functions

function inf = apply_boundary_mask(inf, gt, inverse)
    if nargin<3 || ~inverse
        gt = single(gt>0);        
    else
        gt = single(gt==0);     %background pixel is 0
    end
    inf = inf .* gt;
end


%%
function affinity = binary_to_affinity(inf_vol)
    affinity = zeros([size(inf_vol) 3], 'single');
    
%     affin = abs(inf_vol(1:end-1,:,:)-inf_vol(2:end,:,:));    
%     label = single(inf_vol(2:end,:,:)>0.5);
%     affinity(2:end,:,:,1) = ((1.0-affin).*label) + (affin.*(~label));
%     
%     affin = abs(inf_vol(:,1:end-1,:)-inf_vol(:,2:end,:));
%     label = single(inf_vol(:,2:end,:)>0.5);
%     affinity(:,2:end,:,2) = ((1.0-affin).*label) + (affin.*(~label));
%     
%     affin = abs(inf_vol(:,:,1:end-1)-inf_vol(:,:,2:end));
%     label = single(inf_vol(:,:,2:end)>0.5);    
%     affinity(:,:,2:end,3) = ((1.0-affin).*label) + (affin.*(~label));
    
    affinity(:,:,:,1) = inf_vol;
    affinity(:,:,:,2) = inf_vol;
    affinity(:,:,:,3) = inf_vol;
end










































