% Get synapse information between pre and post cells
% pre = presynaptic ids or celltype in ('pc', 'in', 'cf', 'pf')
% post = postsynaptic ids or celltype in ('pc', 'in', 'cf', 'pf')
% syn_info = [interface id, prepost amb, pre id, post id, dummy1, dummy2,
% interface size, x_coord, y_coord, z_coord] anisotropic mip0


function syn_info = get_syn_info(pre,post)
    
syn_data_path = '/data/research/cjpark147/lrrtm3_wt_syn/synapse_det_info_210503.txt';
%syn_data_path = '/data/research/cjpark147/lrrtm3_wt_syn/lrrtm3_wt_syn/synapse_det_info_200313.txt';
syn_data = readtable(syn_data_path);
intf_id = syn_data.intf_id;
pre_post_amb = syn_data.pre_post_ambiguity;
seg_pre = syn_data.seg_pre;
seg_post = syn_data.seg_post;
type_pre = syn_data.type_pre;
type_post = syn_data.type_post;
intf_size = syn_data.size;
cx = syn_data.contact_x;
cy = syn_data.contact_y;
cz = syn_data.contact_z;

% if pre,post are given as omni ids
if isa(pre, 'double') && isa(post, 'double')
    idx = (ismember(seg_pre, pre) & ismember(seg_post, post));

% if pre is omni_id & post is celltype
elseif isa(pre, 'double') && isa(post, 'char')
    idx = (ismember(seg_pre, pre) & strcmp(type_post, post));

% if pre is celltype & post is omni id
elseif isa(pre, 'char')  && isa(post, 'double')
    idx = (strcmp(type_pre, pre) & ismember(seg_post, post));

% if pre & post are given as celltypes
elseif isa(pre, 'char') && isa(post, 'char')
    idx = (strcmp(type_pre, pre) & strcmp(type_post, post));
    
else
    warning('Please check input structure');
    return;
end


syn_info = [intf_id(idx), pre_post_amb(idx), seg_pre(idx), seg_post(idx), seg_pre(idx), seg_post(idx), intf_size(idx), cx(idx), cy(idx), cz(idx)];
