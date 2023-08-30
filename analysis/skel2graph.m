% cjpark
% Convert skeleton branches to one undirected graph
% (1) It converts the main branch (first order) to undirected graph.
% (2) Converts the next branch to another graph and joins it to neighboring parent
% graph.
% (3) Repeats until all branches are converted and joined.
% To be used for skeletons by TEASAR algorithm used in our lab.

% Input
% branches: cell array containing skeleton branches obtained from aniso/iso mip2 volume.
% If input is isotropic, set multiplier = 1. If it's aniso, set multiplier = 4. 
% compute_pathlength: logical 0 or 1. 
% is_interneuron_axon: logical 0 or 1. 
% omni_id: omni id (required if is_interneuron_axon = 1)

% Function returns (old ver)
% G: undirected graph where node represents skeleton voxel and edge
%   represents euclidean distance between adjacent voxels.
% d: dist of each node from soma(neurite initiation node)   (If input was
% aniso mip2, units of pathlength is iso mip2.)
% nodename: skeleton voxel coordinates + corresponding node names in G.
% ni_node: neurite initiation node, (nearest to soma)

% Function returns
% H struct with 3 fields 
% H.graph: undirected graph where node represents skeleton voxel and edge the
%       distance between adjacent voxels.
% H.root: name of the root node (target node)
% H.Node: struct with 3 fields
%       Pathlength (iso mip2), Coords, Name

%function [G, d, nodename, ni_node] = skel2graph(branches, compute_pathlength, is_axon, omni_id)
function H = skel2graph(branches, compute_pathlength, is_interneuron_axon, omni_id)

multiplier = 1;     % use 4 when input is anisotropic, use 1 when input is isotropic
if multiplier == 4
    vol = zeros(4000, 3000, 300, 'uint32');     %aniso mip2
elseif multiplier == 1
    vol = zeros(4000, 3000, 1200, 'uint32');    % iso mip2
end
%% Assign different ids to each branches

nb = numel(branches);
for i = 1:nb
    br = branches{1,i};    
    lin_idx = sub2ind(size(vol), br(:,1), br(:,2), br(:,3));
    vol(lin_idx) = i;    
end

%% Convert the main branch (first order) to undirected graph

br = branches{1,1};
terminal_points_mip2 = zeros(nb*2,3);
terminal_points_mip2(1,:) = br(1,:);
terminal_points_mip2(2,:) = br(end,:);
nodename = cell(2,1);
[nvoxel,~] = size(br);
s = 1:nvoxel-1;    
t = 2:nvoxel;
br_iso = br;
br_iso(:,3) = br_iso(:,3)*multiplier;    % force isotropy
weights = vecnorm((br_iso(2:end,:)-br_iso(1:end-1,:))');
node_names = cellstr('Node'+string(1:nvoxel));
G = graph(s,t,weights,node_names);

nodename{1,1} = br; 
nodename{2,1} = node_names';
ni_node = node_names{end};


%% Add the remaining branches to the graph

branch_nodes_incrementer = zeros(nb,1);
ws = 2;     % window size
for i = 2:nb
    % save terminal points of this branch for later use
    terminal_points_mip2(2*i-1,:) = branches{1,i}(1,:);
    terminal_points_mip2(2*i,:) = branches{1,i}(end,:);    
       
    % find the point where this branch meets its parent branch
    br_enp = branches{1,i}(end,:);
    surround_enp = vol(br_enp(1)-ws:br_enp(1)+ws, br_enp(2)-ws:br_enp(2)+ws, br_enp(3)-ws:br_enp(3)+ws);
    parent_of_br = unique(surround_enp);
    parent_of_br = setdiff(parent_of_br, [0,i]);
    most_frequent = 0; most_frequent_branch = 0;
    if numel(parent_of_br) > 1
        for j = 1:numel(parent_of_br)
            freq = sum(surround_enp == parent_of_br(j),'all');
            if freq > most_frequent && parent_of_br(j) < surround_enp((end+1)/2)
                most_frequent = freq;
                most_frequent_branch = parent_of_br(j);
            end
        end
        parent_of_br = most_frequent_branch;
    end
    
    [px,py,pz] = ind2sub(size(surround_enp), find(surround_enp==parent_of_br));
    p_idx =  br_enp + [px(1),py(1),pz(1)]-[ws+1,ws+1,ws+1];
    
    % distance between the end node of this branch to the parent branch
    bridge_weight = vecnorm(br_enp - p_idx);
    
    % convert a branch to edges and weights
    br = branches{1,i};
    br_iso = br;
    br_iso(:,3) = br_iso(:,3) * multiplier;  % force isotropy
    [nvoxel,~] =size(br);
    s_add = 1:nvoxel-1; 
    t_add = 2:nvoxel;
    weights_add = vecnorm((br_iso(2:end,:)-br_iso(1:end-1,:))');
    
    % update local branch nodes to global nodes by assigning new node id.
    [num_node,~] = size(G.Nodes);    
    s_add = s_add + num_node;
    t_add = t_add + num_node;
    branch_nodes_incrementer(i) = num_node;         
    
    % find the parent branching point's node id in graph G 
    node_bp = find(ismember(branches{1,parent_of_br},p_idx,'rows')) + branch_nodes_incrementer(parent_of_br);
    if degree(G,node_bp) == 3
        node_bp = node_bp -1;   % avoid having degree > 3
    end
    
    % find the end point's node id of this branch 
    [node_enp,~] = size(br);
    node_enp = node_enp + num_node;
    
    % bridge parent's branching point and this branch's end point
    s_add = [s_add, node_bp];
    t_add = [t_add, node_enp];
    weights_add = [weights_add, bridge_weight];
    
    node_names = cellstr('Node'+string(1+num_node:nvoxel+num_node));
  %  G = addnode(G,node_names);
    G = addedge(G,s_add,t_add,weights_add);
    
    nodename{1,1} = [nodename{1,1}; br];
    nodename{2,1} = [nodename{2,1}; node_names'];
    
end

% If the input is axon skeleton,find the axon initiation node again, 
% because root was chosen randomly when computing axonal skeletons. 
if is_interneuron_axon == 1
    addpath('/data/research/cjpark147/code/matlab');
    task_voxel_mip0 = get_voxels_of_the_axon_root_task(omni_id, '/data/research/cjpark147/conn_analysis/p_cell_partition_p_cells-cb_interneurons-axon.revised_20200702.txt');
    
    % from mip2 to mip0
    terminal_points_mip0 = terminal_points_mip2 * 4;
    
    % find nearest terminal points to task voxel
    [ridx,dist] = dsearchn(terminal_points_mip0, task_voxel_mip0(1:ceil(end/1000):end,:));    
    
    if isempty(ridx(dist<100))
        fprintf('%s %d\n', 'no terminal points in task omni_id', omni_id);
    else
        ni_coord = terminal_points_mip2(mode(ridx(dist<100)),:);
    end
    
    % axon skeleton of interneuron 36 is an exception case; the terminal
    % points of its branches are nowhere near the axon initial segment.
    if omni_id == 36
        voxel_of_axon_init = [3370,4810,508]/4;
        [ridx,~] = dsearchn(nodename{1,1}, voxel_of_axon_init);    
        ni_node = nodename{2,1}{ridx};
    else    
        nidx = ismember(nodename{1,1}, ni_coord, 'rows');
        ni_node = nodename{2,1}{nidx};
    end
end


% compute pathlengths of each node from soma
d = 'check input param';
if compute_pathlength
    num_nodes = length(nodename{2,1});
    d = zeros(num_nodes,1);
    for i = 1:num_nodes
        [~,d(i)] = shortestpath(G, ni_node, nodename{2,1}{i});
    end
end

% save results as a struct
H = struct();
H.graph = G;
H.root = ni_node;
node = struct();
node.Name = nodename{2,1};
node.Coord = nodename{1,1};
node.Pathlength = d;
H.Node = node;


end


%% functions

% object_coords = object coordinates in anisotropic mip2 segment volume
% nearest_skel_voxels = anisotropic mip2 coordinates of nearest skeleton voxels to synapses. 

function [idx, nearest_skel_voxels] = get_nearest_skel_voxels(skel_path, object_coords)
    [idx,~] = knnsearch(skel_path, object_coords);    
    nearest_skel_voxels = [skel_path(idx), skel_path(idx), skel_path(idx)];    
end
