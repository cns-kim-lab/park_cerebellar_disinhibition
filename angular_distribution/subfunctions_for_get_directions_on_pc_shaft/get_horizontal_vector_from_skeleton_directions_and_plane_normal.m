function horizontal_vector = get_horizontal_vector_from_skeleton_directions_and_plane_normal (dend_direction,plane_normal_vector)

    % horizontal_vector = [dend_direction(:,2) -dend_direction(:,1) zeros(size(dend_direction,1),1)];
    horizontal_vector = cross(dend_direction,repmat(plane_normal_vector,size(dend_direction,1),1),2);
    
    % For 'horizontal' direction, we find the direction of the intersection line between 
    %                               dend_direction.*[x y z] == query_point 
    %                                                   and
    %                                                     z == query_point_z
    % The line dend_direction(1:2).*[x y]==0 is perpendicular to dend_direction(1:2) in xy plane.
    % Thus, the direction of the line is [-dend_direction(2), dend_direction(1), 0]

    horizontal_vector = horizontal_vector./vecnorm(horizontal_vector,2,2);
    % Normalize.

    % ** For the case where dend_direction is parallel to the z direction,
    %    for now we naively suppose that there's no such point.
    %    It can be noticed when it is not the case, because it will cause an error for the procedures after, returning NaN value.

end
