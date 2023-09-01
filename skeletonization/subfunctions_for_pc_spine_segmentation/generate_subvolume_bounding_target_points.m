function [subvol, offset] = generate_subvolume_bounding_target_points (target_points, size_of_vol, margin, truncate_to_even_or_not)

    if size(target_points,2) == 1
        target_points_global_ind = target_points;
        [x,y,z] = ind2sub(size_of_vol,target_points_global_ind);
        target_points_global_sub = [x y z];
        clear x y z;
    elseif size(target_points,2) == 3
        target_points_global_sub = target_points;
        %target_points_global_ind = sub2ind(vol_size,target_points_global_sub(:,1),target_points_global_sub(:,2),target_points_global_sub(:,3));
    end

    lower_bound_for_target_points = min(target_points_global_sub,[],1);
    upper_bound_for_target_points = max(target_points_global_sub,[],1);
    
    if truncate_to_even_or_not
        offset = floor((lower_bound_for_target_points -1 -margin)./2).*2;
        end_of_range = ceil((upper_bound_for_target_points + margin)./2).*2;
        size_of_subvol = end_of_range - offset;
    else
        offset = lower_bound_for_target_points - 1 - margin;
        end_of_range = upper_bound_for_target_points + margin;
        size_of_subvol = end_of_range - offset;
    end

    subvol = false(size_of_subvol);
    target_points_local_sub = target_points_global_sub - offset;
    target_points_local_ind = sub2ind(size_of_subvol,target_points_local_sub(:,1),target_points_local_sub(:,2),target_points_local_sub(:,3));
    subvol(target_points_local_ind) = true;  
    
%     if truncate_to_even_or_not
%         lower_bound_for_target_points = (floor((min(target_points_global_sub,[],1)-1)./2)).*2+1;
%         upper_bound_for_target_points = (floor((max(target_points_global_sub,[],1)-1)./2)).*2+2;
%     else
%         lower_bound_for_target_points = min(target_points_global_sub,[],1);
%         upper_bound_for_target_points = max(target_points_global_sub,[],1);
%     end
% 
%     size_of_subvol = upper_bound_for_target_points - lower_bound_for_target_points + 1 + margin.*2;
%     offset = lower_bound_for_target_points -1 -margin;
%     
%     subvol = false(size_of_subvol);
%     target_points_local_sub = target_points_global_sub - offset;
%     target_points_local_ind = sub2ind(size_of_subvol,target_points_local_sub(:,1),target_points_local_sub(:,2),target_points_local_sub(:,3));
%     subvol(target_points_local_ind) = true;

end