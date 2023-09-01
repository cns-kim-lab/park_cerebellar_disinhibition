function angle_degeneracy_removed = acos_degeneracy_removed (dot_product_main, dot_product_ref)
    sign_of_dot_product_ref = sign(dot_product_ref);
    sign_of_dot_product_ref(sign_of_dot_product_ref==0) = 1;
    angle_degeneracy_removed = acos(dot_product_main) .* sign_of_dot_product_ref;
end
