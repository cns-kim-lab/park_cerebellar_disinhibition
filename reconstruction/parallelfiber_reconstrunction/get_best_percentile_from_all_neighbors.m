%return values must "single"
function rtn = get_best_percentile_from_all_neighbors(neighbor_info, xaffin, yaffin, zaffin, segment_sizes)
    min_size_th = 3000;
	edge_th = 30;	
    
    nrows = size(neighbor_info,1);    
    %seg_id percentile_value #edge #voxels
    candidate_info = [];
    for iter=1:nrows
        xidx = str2num( neighbor_info{iter,2} );
        yidx = str2num( neighbor_info{iter,3} );
        zidx = str2num( neighbor_info{iter,4} );
        
        %convert to linear index
        affin = [xaffin(xidx) yaffin(yidx) zaffin(zidx)];        
        candidate_info = [candidate_info; single(neighbor_info{iter,1}) single(prctile(affin, 75)) ...
            single(numel(xidx)+numel(yidx)+numel(zidx)) single(segment_sizes(neighbor_info{iter,1}))];
    end    
    
    [ridx_few_edge,~] = find(candidate_info(:,3)<edge_th);
    [ridx_big_frag,~] = find(candidate_info(:,4)>min_size_th);
    rm_ridx = intersect(ridx_few_edge, ridx_big_frag);
    candidate_info(rm_ridx,:) = [];
    
    [r,~] = find(candidate_info(:,2) == max(candidate_info(:,2)));    
    rtn = single(candidate_info(r,1:2));
end