function [all_pth, brnch_pth, brnch_rts] = backtracking4teasar_old (dbf, dsf, pdrf, indfrom, p_scale, p_const, rt_ind, vol_size)

    % Find farthest voxel

    [~, max_ind] = max(dsf(:));

    % 7. Shortest path
    all_pth = [];
    brnch_pth = [];
    x_pth = []; y_pth = []; z_pth = []; brnch = [];
    now_ind = max_ind;
    

    while now_ind ~= rt_ind && ~ismember(now_ind,all_pth)
        all_pth(end+1) = now_ind;
        brnch(end+1) = now_ind;
        now_pnt = ind2pnt(vol_size,now_ind);
        x_pth(end+1) = now_pnt(1);
        y_pth(end+1) = now_pnt(2);
        z_pth(end+1) = now_pnt(3);
        now_ind = indfrom(now_ind);
    end

    % disp('get branch')

    brnch_rts = [];
    brnch_pth{1} = brnch;
    brnch_rts(1,1) = max_ind;
    brnch_rts(1,2) = rt_ind;

    % Label voxels near the skeleton
    for i=1:length(x_pth)

        radi = dbf( sub2ind(vol_size,x_pth(i),y_pth(i),z_pth(i)) ).* p_scale + p_const;
        x0 = x_pth(i); y0 = y_pth(i); z0 = z_pth(i);
        x1 = floor(x0 - radi); if x1<1; x1=1; end
        x2 = floor(x0 + radi); if x2>size(pdrf,1); x2=size(pdrf,1); end
        y1 = floor(y0 - radi); if y1<1; y1=1; end
        y2 = floor(y0 + radi); if y2>size(pdrf,2); y2=size(pdrf,2); end
        z1 = floor(z0 - radi); if z1<1; z1=1; end
        z2 = floor(z0 + radi); if z2>size(pdrf,3); z2=size(pdrf,3); end

        dsf(x1:x2,y1:y2,z1:z2) = 0;
        pdrf(x1:x2,y1:y2,z1:z2) = 0; 
    end

    % disp('removing voxels')

    % Repeat farthest voxel, shortest path and labeling


    nn=0;
    while ~all(all(all(dsf==0)))
        nn = nn + 1;
        [~, max_ind] = max(dsf(:));
        farthest = ind2pnt(vol_size,max_ind);

        x_pth = []; y_pth = []; z_pth = []; brnch = [];
        now_ind = max_ind;
        while now_ind ~= rt_ind && ~ismember(now_ind,all_pth)
            all_pth(end+1) = now_ind;
            brnch(end+1) = now_ind;
            now_pnt = ind2pnt(vol_size,now_ind);
            x_pth(end+1) = now_pnt(1);
            y_pth(end+1) = now_pnt(2);
            z_pth(end+1) = now_pnt(3);
            now_ind = indfrom(now_ind);
        end
        brnch_pth{end+1} = brnch;
        brnch_rts(end+1,1) = max_ind;
        brnch_rts(end,2) = now_ind;

        for i=1:length(x_pth)

            radi = dbf( sub2ind(vol_size,x_pth(i),y_pth(i),z_pth(i)) ).* p_scale + p_const;
            x0 = x_pth(i); y0 = y_pth(i); z0 = z_pth(i);
            x1 = floor(x0 - radi); if x1<1; x1=1; end
            x2 = floor(x0 + radi); if x2>size(pdrf,1); x2=size(pdrf,1); end
            y1 = floor(y0 - radi); if y1<1; y1=1; end
            y2 = floor(y0 + radi); if y2>size(pdrf,2); y2=size(pdrf,2); end
            z1 = floor(z0 - radi); if z1<1; z1=1; end
            z2 = floor(z0 + radi); if z2>size(pdrf,3); z2=size(pdrf,3); end

            dsf(x1:x2,y1:y2,z1:z2) = 0;
            pdrf(x1:x2,y1:y2,z1:z2) = 0;
        
        end
    end
end

function pnt = ind2pnt(vol_size,ind)
    pnt = zeros(size(ind,1),3);
    [pnt(:,1),pnt(:,2),pnt(:,3)] = ind2sub(vol_size,ind);
    
end