function [ID1,ID2, BNDRY] = getContactSurface_thickness2(Vol, Axis)
    
    % zero padding around the surface of Vol
    [m,n,p] = size(Vol);
    V = zeros(m+2,n+2,p+2);
    V(2:end-1, 2:end-1, 2:end-1) = Vol;
    V2 = V;
    V2_ = V;
    
    if Axis == 'x' || Axis == 'X'
        V_shift = circshift(V,[1,0,0]);
        V2(m+2,:,:) = V(m+1,:,:);
        V_shift(2,:,:) = V(2,:,:);
        
        V_shift_ = circshift(V, [-1 0 0]);
        V2_(1,:,:) = V(2,:,:);
        V_shift_(m+1,:,:) = V(m+1,:,:);
    elseif Axis == 'y' || Axis == 'Y'
        V_shift = circshift(V, [0 1 0]);        
        V2(:,n+2,:) = V(:,n+1,:);
        V_shift(:,2,:) = V(:,2,:);
        
        V_shift_ = circshift(V, [0 -1 0]);
        V2_(:,1,:) = V(:,2,:);
        V_shift_(:,n+1,:) = V(:,n+1,:);        
    elseif Axis == 'z' || Axis == 'Z'
        V_shift = circshift(V,[0,0,1]);
        V2(:,:,p+2) = V(:,:,p+1);
        V_shift(:,:,2) = V(:,:,2);
        
        V_shift_ = circshift(V, [0 0 -1]);
        V2_(:,:,1) = V(:,:,2);
        V_shift_(:,:,p+1) = V(:,:,p+1);
    end

    P = (V2~=V_shift);          % Compute contact surfaces
    A = V.*P;                   % One cell id from each pair at contact points
    B = V_shift.*P;             % Coupled cell ids.
    A = A(2:end-1, 2:end-1, 2:end-1);       % remove zero paddings
    B = B(2:end-1, 2:end-1, 2:end-1);    
    ID1 = min(A,B);             % (ID1, ID2) pairs are unordered pairs, Pairs (1,2) and (2,1) are considered the same.
    ID2 = max(A,B);             
    
    P_ = (V2_~=V_shift_);
    A_ = V.*P_;
    B_ = V_shift_.*P_;
    A_ = A_(2:end-1, 2:end-1, 2:end-1);       % remove zero paddings
    B_ = B_(2:end-1, 2:end-1, 2:end-1);
    ID1_ = min(A_,B_);
    ID2_ = max(A_,B_);
    
    BNDRY = zeros(size(ID2));
    BNDRY(ID2<1) = ID2_(ID2<1);
    BNDRY = BNDRY + ID2;
    
    %remove backgroud-seg pair
    ID2(ID1<1) = 0;
    ID2_(ID1_<1) = 0;

    ID1(ID1<1) = ID1_(ID1<1);
    ID2(ID2<1) = ID2_(ID2<1);
%     ID1 = ID1 + ID1_;
%     ID2 = ID2 + ID2_;
end
