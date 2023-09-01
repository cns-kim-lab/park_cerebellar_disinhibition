% branch : cell of branches, the unit of teasar skeletons without bifurcation
        % : Use prolonged version of componentwise skeletons
% n : parameter about evaluation of local slope
function directional_vectors = get_directional_vector (branch, n)

    branch_num = numel(branch);
    diff_mean_n_pairs = cell(1,branch_num);
    
    for i=1:branch_num
        % mean of the difference 2n voxels around the query point
        diff_mean_n_pairs{i} = mean_difference_of_n_pairs(branch{i},n);    
    end
        
    directional_vectors = augment_directional_vector_at_the_ends (branch,diff_mean_n_pairs);

end
    
% function dendritic_skeleton = dend_no_repeat (dendritic_skeleton)
    % 
    % branch_num = numel(dendritic_skeleton);
    %   
    % for i=branch_num:-1:2
        % dendritic_skeleton{i} = setdiff(dendritic_skeleton{i},dendritic_skeleton{i-1},'stable');
    % end
    % 
% end
    
function mean_diff = mean_difference_of_n_pairs (series_of_points, n)
    
    mean_diff = zeros(size(series_of_points,1)-2*n,size(series_of_points,2));
    for i=1:n
        mean_diff = mean_diff + series_of_points(2*n+2-i:end+1-i,:);
        mean_diff = mean_diff - series_of_points(n+1-i:end-n-i,:);
    end
    mean_diff = mean_diff./vecnorm(mean_diff,2,2);
    
end

function directional_vectors = augment_directional_vector_at_the_ends (branch,diff_mean_n_pairs)

    n = (size(branch{1},1)-size(diff_mean_n_pairs{1},1)) /2;
    directional_vectors = cellfun(@(x) [zeros(n,3); x; zeros(n,3)], diff_mean_n_pairs, 'UniformOutput',false);

    for k = 1:(n-1)
        directional_vectors = cellfun(@(x,y) ...
                             [x(1:n-k,:);...
                              mean_difference_of_n_pairs(y(1:2*(n-k)+1,:),n-k);...
                              x(n-k+2:end-n+k-1,:);...
                              mean_difference_of_n_pairs(y(end-2*(n-k):end,:),n-k);...
                              x(end-n+k+1:end,:)],...
                                                directional_vectors, branch, 'UniformOutput', false);
    end

    directional_vectors = cellfun(@(x) [x(2,:); x(2:end-1,:); x(end-1,:)], directional_vectors,'UniformOutput',false);

end
