function vertical_vector = get_vertical_vectors_from_skeleton_directions_and_horizontal (dend_direction,horizontal_vector)

    vertical_vector = cross(dend_direction,horizontal_vector,2);
    % For 'horizontal' direction, we find the direction of the intersection line between 
    %                               dend_direction.*[x y z] == query_point 
    %                                                   and
    %                                                     z == query_point_z
    % The line dend_direction(1:2).*[x y]==0 is perpendicular to dend_direction(1:2) in xy plane.
    % Thus, the direction of the line is [-dend_direction(2), dend_direction(1), 0]

    vertical_vector = vertical_vector./vecnorm(vertical_vector,2,2);
    % Normalize.

    % ** For the case where dend_direction is parallel to the z direction,
    %    for now we naively suppose that there's no such point.
    %    It can be noticed when it is not the case, because it will cause an error for the procedures after, returning NaN value.
    vertical_vector_dot_prod_with_z = dot(vertical_vector,repmat([0 0 1],size(vertical_vector,1),1),2);
    inverted = vertical_vector_dot_prod_with_z < 0;
    vertical_vector(inverted,:) = -vertical_vector(inverted,:);

end
