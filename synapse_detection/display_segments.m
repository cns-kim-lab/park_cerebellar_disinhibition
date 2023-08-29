

vesicle_path = '/data/lrrtm3_wt_syn/vesicle_segment_final.h5';
intf_path = '/data/lrrtm3_wt_syn/interface_relevant_fixed.h5';
seg_path = '/data/lrrtm3_wt_syn/segment_mip0_all_cells_200313.h5';

cp_path = '/data/lrrtm3_wt_syn/assembly_cleft_prob.h5';
vp_path ='/data/assembly_vesicle_prob.h5'; 



stp = [7759,741,251];
num_el = [1196, 326, 40];
s = h5read(seg_path, '/main', stp, num_el);
i = h5read(intf_path, '/main', stp, num_el);
v = h5read(vesicle_path, '/main', stp, num_el);

remap_id = 1;

if remap_id
    sid = unique(s);
%    sid(sid==0) = [];
    smax = max(sid);
    map = zeros(smax+1,1);
    new_id = [1:numel(sid)]';
    map(sid) = new_id;
    map = [0; map];
    s = map(s+1);
end

if remap_id
    iid = unique(i);
%    iid(iid==0) = [];
    smax = max(iid);
    map = zeros(smax+1,1);
    new_id = [1:numel(iid)]';
    map(iid) = new_id;
    map = [0; map];
    i = map(i+1);
end

if remap_id
    vid = unique(v);
    vid(vid==0) = [];
    smax = max(vid);
    map = zeros(smax+1,1);
    new_id = [1:numel(vid)]';
    map(vid) = new_id;
    map = [0; map];
    v = map(v+1);
end
%}

slice = 20;

scolor = cool(numel(sid)+1);
scolor(1,:) = [0 0 0];
image(s(:,:,slice));
colormap(scolor);

figure;
icolor = cool(numel(iid)+1);
icolor(1,:) = [0 0 0];
image(i(:,:,slice));
colormap(icolor);

figure;
vcolor = cool(numel(vid)+1);
vcolor(1,:) = [0 0 0];
image(v(:,:,slice));
colormap(vcolor);

%}







