function all_neighbor = get_neighbor_set(all_pair, seeds)
    %find all pair seed included
    [ridx,~] = find(ismember(all_pair(:,1:2), seeds)>0);

    %find seed-seed pair and remove
    [n,bin] = histc(ridx, unique(ridx));
    ridx(find(ismember(bin, find(n>1))>0)) = [];

    %all neighbor-seed pair
    all_neighbor = uint32(all_pair(ridx, 1:2));
end