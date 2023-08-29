%% Classification of relevant interfaces as synaptic or non-synaptic. 

% Evaluation mode only.
% (1) Compute two feature values of cleft probability for relevant interface regions
% (2) Preliminary classification using SVM on the two features.
% (3) Reduced false positives using vesicle segments 
% (4) Reduced false negative using high prob values.  



addpath /data/research/cjpark147/code/hdf5_ref
addpath /data/research/cjpark147/code/ref/
addpath /data/lrrtm3_wt_code/matlab/mysql/
    
    
thickness = 2;
interface_size_th = 200;
useAssembled = 1;
load('/data/research/share/synapseDetection/testvolume_gt.mat');
path = '/data/lrrtm3_wt_syn';    

if useAssembled
    interfaceFile = [path,'/assembly/assembly_interface_relevant_test.h5'];
    load('/data/lrrtm3_wt_syn/assembly/interface_translator_test.mat');      % maps 'assembled id' to 'testvolume id'
    load('/data/lrrtm3_wt_syn/interface/interface_relevant_test/mat_data/interface_relevant_test_info.mat');
    cleftProbFile = [path,'/assembly/assembly_cleft_prob_test.h5'];
    vesicleSegmentFile = [path,'/assembly/vesicle_segmentation_0906_1500_05_test.h5'];
    segmentFile = '/data/research/share/synapseDetection/testvolume_segmentation.h5';   
else
    cleftProbFile = '/data/research/cjpark147/kaffe/SynDetection/Dataset/ForwardDatasets/forward_21_35_test_output.h5';
    vesicleSegmentFile = '/data/research/share/synapseDetection/testvolume_vesicle_segmentation.h5';
    interfaceFile = '/data/research/share/synapseDetection/testvolume_interfaces_relevant_only.h5';
    segmentFile = '/data/research/share/synapseDetection/testvolume_segmentation.h5';   
    load('/data/research/share/synapseDetection/testvolume_interfaces_segpair.mat');
end
%cleftProbFile = '/ldata/research/cjpark147/kaffe/SynDetection/Dataset/ForwardDatasets/forward_21_35_test_output.h5';
%vesicleSegmentFile = '/ldata/research/share/synapseDetection/testvolume_vesicle_segmentation.h5';

CleftProb = h5read(cleftProbFile, '/main');
CellSegment = h5read(segmentFile, '/main');
Interface = h5read(interfaceFile, '/main');
Vesicle = h5read(vesicleSegmentFile, '/main');

Interface= Interface(1:992,1:992,1:248);
CellSegment = CellSegment(1:992,1:992,1:248);
Mask = Interface > 0;
CleftProb = single(CleftProb) .* single(Mask);
[s1,s2,s3] = size(CleftProb);
relevant_id = unique(Interface);     relevant_id(relevant_id==0) = [];


%% New testvolume synapse classification
% From experience: 85-95%ile range, 99%ile were the best
% 
% alternative: pointPrctile = [95 10], lowerPrctile = 75, upper = 99,
% high_prob = 0.9

pointPrctile = 99;
upperPrctile = 95;
lowerPrctile = 85;
highProb = 0.9;

load('/data/research/cjpark147/code/synapse_detection/cleft_detector_svm.mat');
load('/data/research/share/synapseDetection/testvolume_gt.mat');

if useAssembled
   
   temp1 = synapse_segs(ismember(synapse_segs, interface_translator));       
   temp2 = nonsynapse_segs(ismember(nonsynapse_segs, interface_translator));
   temp3 = vague_segs(ismember(vague_segs, interface_translator));
   
   synapse_segs = zeros(numel(temp1),1); 
   nonsynapse_segs = zeros(numel(temp2),1);
   vague_segs = zeros(numel(temp3),1);
   
   for i =1:numel(temp1)
       synapse_segs(i) = find(interface_translator == temp1(i));
   end
   
   for i=1:numel(temp2)
       nonsynapse_segs(i) = find(interface_translator == temp2(i));
   end
   
   for i=1:numel(temp3)
       vague_segs(i) = find(interface_translator == temp3(i));
   end   
end

%##########################################
% The code below evaluates classifier, using ground truth data. 

prct_syn = zeros(numel(synapse_segs),1) - 1;
prct_nonsyn = zeros(numel(nonsynapse_segs),1) - 1;
interprct_syn = zeros(numel(synapse_segs),1) - 1; 
interprct_nonsyn = zeros(numel(nonsynapse_segs),1) - 1;
gid_sizeth_list = zeros(numel(synapse_segs),1) - 1;
nogid_sizeth_list = zeros(numel(nonsynapse_segs),1) - 1;
prob_high_syn = zeros(numel(synapse_segs), 1) - 1; 
prob_high_nonsyn = zeros(numel(nonsynapse_segs),1) - 1;

disp('SVM cleft prediction on progress...');
tic;
% feature values for synaptic interfaces
parfor i =1:length(synapse_segs)
    this_id = synapse_segs(i);
    intfce_idx = find(Interface == this_id);
    prob = CleftProb(intfce_idx);
    if (length(intfce_idx) > interface_size_th)
        prct_syn(i) = prctile(prob,pointPrctile);          
        interprct_syn(i) = prctile(prob,upperPrctile) - prctile(prob,lowerPrctile);       
        gid_sizeth_list(i) = synapse_segs(i);       
    
        if sum(prob>highProb, 'all') > interface_size_th
            prob_high_syn(i) = synapse_segs(i);
        end
    end    
end

% feature values for non-synaptic interfaces
parfor i =1:length(nonsynapse_segs)
    this_id = nonsynapse_segs(i);
    intfce_idx = find(Interface == this_id);
    prob = CleftProb(intfce_idx);
    if (length(intfce_idx) > interface_size_th)        
        prct_nonsyn(i) = prctile(prob,pointPrctile);
        interprct_nonsyn(i) = prctile(prob,upperPrctile) - prctile(prob,lowerPrctile);
        nogid_sizeth_list(i) = nonsynapse_segs(i);
    
   % if (numel(find(prob>highProb))> interface_size_th)
        if sum(prob>highProb,'all') > interface_size_th
            prob_high_nonsyn(i) = nonsynapse_segs(i);
        end
    end
end

prct_syn = prct_syn(prct_syn >= 0);
prct_nonsyn = prct_nonsyn(prct_nonsyn >= 0);
interprct_syn = interprct_syn(interprct_syn >= 0);
interprct_nonsyn = interprct_nonsyn(interprct_nonsyn>=0);
gid_sizeth_list = gid_sizeth_list(gid_sizeth_list >= 0 );
nogid_sizeth_list = nogid_sizeth_list(nogid_sizeth_list >= 0);
prob_high_syn = prob_high_syn(prob_high_syn >= 0);
prob_high_nonsyn = prob_high_nonsyn(prob_high_nonsyn >= 0 );

gidX = [prct_syn, interprct_syn];   
nogidX = [prct_nonsyn, interprct_nonsyn];

[label_gid, score1] = predict(SVMModel, gidX);
[label_nogid, score2] = predict(SVMModel, nogidX);

fp = sum(ismember(label_nogid,2));
fn = sum(ismember(label_gid,1));
tp = sum(ismember(label_gid,2));
fp_id = nogid_sizeth_list(ismember(label_nogid,2));
fn_id = gid_sizeth_list(ismember(label_gid,1));
tp_id = gid_sizeth_list(ismember(label_gid,2));
tn_id = nogid_sizeth_list(ismember(label_nogid,1));
toc;
disp('cleft classification done');

%}

%% Get celltype info


    
segID = unique(interface_info(:,1:2));
addpath /data/research/cjpark147/code/matlab/mysql/;
password = 'rhdxhd!Q2W';
h_sql = mysql( 'open', 'localhost', 'omnidev', password);
rtn = mysql(h_sql, 'use omni_20200313');
cellType = zeros(numel(segID),1);
for i=1:length(segID)
    query = sprintf('select type1 from cell_metadata where omni_id=%s', num2str(segID(i)));
    cellType(i) = mysql(h_sql, query);
end
mysql('close');



%% Logical conditions

% A: (99%ile, 85-95%ile) < f(99%ile, 85-95%ile)
% B: vesicle match
% C: #voxels(p>0.9) > 200
% Logical conditions
  
% ########################
% Experimented on different rules:
% #0:  A  ∩ B
% #1: (A ∪ C) ∩ B
% #2: (A ∩ C)  ∩ B
% #3: (∼(A ∩ B) ∩ C) ∪ ( A ∩ B)
% Rule #1 was the best. 
% ########################

condition_logic = 1;
target_id = [];

disp('applying logical conditions...')
switch(condition_logic)
    case 0
        target_id = [tp_id; fp_id];
    case 1
        id = [tp_id; fp_id; prob_high_syn; prob_high_nonsyn]; 
        target_id = unique(id);
        tp_id = unique([tp_id; prob_high_syn]);
        fp_id = unique([fp_id; prob_high_nonsyn]);
        fn_id(ismember(fn_id, prob_high_syn)) = [];
        tn_id(ismember(tn_id, prob_high_nonsyn)) = [];
    case 2
        id1 = [tp_id; fp_id];   id2 = [prob_high_syn; prob_high_nonsyn];
        target_id = intersect(id1,id2);
        tp_id = unique([target_id(ismember(target_id, tp_id)); 
        target_id(ismember(target_id, prob_high_syn))]);
        fp_id = unique([target_id(ismember(target_id, fp_id)); 
        target_id(ismember(target_id, prob_high_nonsyn))]);
        fn_id = gid_sizeth_list(~ismember(gid_sizeth_list, tp_id));
    case 3
        target_id = [tp_id; fp_id];               
end



%% Match high cleft-prob interfaces with vesicle segments 

% ########################################################
%
% To remove most of the spillover cases.
% For each cleft-positive interface
%   (1) Get cell segment id1, id2 for the interface.
%   (2) For segment ids that are of presynapse type
%       get vc id that is closest to the interface.
%       
% Cell types:   (1) Purkinje    (2) Parallel Fiber  (3) Climbing Fiber  
%               (4) Interneuron   (5) Glia        (6) Golgi
%
% ########################################################


disp('preparing to match interfaces with vesicle clouds')

vc_dist = 10;                                                % distance threshold
ni = numel(target_id);                                      % number of potential interfaces
tic;
vc_id = unique(Vesicle); vc_id(vc_id==0) = [];
toc;
tic;
vc_seg_match = extract_gtsegid_of_vc(Vesicle, CellSegment); % get neuron segment id containing a given vesicle
toc;
tic;
SE = strel('sphere',1);   
Bw_vc = Vesicle >0 ;
Bw_vc = imerode(Bw_vc,SE);
toc;
VC_surf = (uint32(Vesicle) .* uint32(~Bw_vc));              % get surface (i.e. outer-most) pixels of vesicle segmentation


intfce_vc_match1 = zeros([ni 3]) - 1;          % [vc id, dist, contact size]
intfce_vc_match2 = intfce_vc_match1;
interface_info1 = interface_info(:,1);  interface_info2 = interface_info(:,2);
vc_seg_match_vc = vc_seg_match(:,1);   vc_seg_match_seg = vc_seg_match(:,2);
tic;
disp('matching interfaces and vesicle segments...')


parfor i=1:ni
   
    seg_id1 = interface_info1(target_id(i));    seg_id2 = interface_info2(target_id(i));
    nearest_vc_id1 = 0; nearest_vc_id2 = 0;
    [ix,iy,iz] = ind2sub(size(Interface),find(Interface == target_id(i)));
    
    if ismember(cellType(segID==seg_id1), [2,3,4])                          % if seg qualifies as presynaptic                                                                          
        vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id1);           % get vesicle ids within seg_id1 segment

        if numel(vc_of_seg) > 0            
            [vesid,dist_from_intfce,con_size] = get_nearest_vc(VC_surf, vc_of_seg, ix, iy, iz);
            nearest_info =  [vesid,dist_from_intfce,con_size];
            intfce_vc_match1(i,:) = nearest_info; 
        end
    end
    
    if ismember(cellType(segID==seg_id2), [2,3,4])
        vc_of_seg = vc_seg_match_vc(vc_seg_match_seg == seg_id2);
        if numel(vc_of_seg) > 0
            [vesid,dist_from_intfce,con_size] = get_nearest_vc(VC_surf, vc_of_seg, ix, iy, iz);
            nearest_info =  [vesid,dist_from_intfce,con_size];
            intfce_vc_match2(i,:) = nearest_info; 
        end
    end
    
end



pos_intfce_vc_match = [target_id, zeros([ni 1])];

for i = 1:size(pos_intfce_vc_match, 1)
    if (intfce_vc_match1(i,2) < vc_dist && intfce_vc_match1(i,2) >= 0)
        pos_intfce_vc_match(i,2) = intfce_vc_match1(i,1);
    elseif (intfce_vc_match2(i,2) < vc_dist && intfce_vc_match2(i,2) >= 0)
        pos_intfce_vc_match(i,2) = intfce_vc_match2(i,1);
    end
end

pos_intfce_vc_no_match = pos_intfce_vc_match(pos_intfce_vc_match(:,2)==0);

tp2 = tp_id(~ismember(tp_id,pos_intfce_vc_no_match));
fp2 = fp_id(~ismember(fp_id,pos_intfce_vc_no_match));
fn2 = [fn_id; tp_id(ismember(tp_id,pos_intfce_vc_no_match))];
tn2 = [tn_id; fp_id(ismember(fp_id,pos_intfce_vc_no_match))];
toc;

    fprintf('\n interface-vesicle matching done. \n *** classification done *** \n');

%}

%{

if condition_logic == 1
    fn2 = gid_sizeth_list(~ismember(gid_sizeth_list, tp2));
end

if condition_logic == 2
    fn2 = gid_sizeth_list(~ismember(gid_sizeth_list, tp2));
end


if condition_logic == 3
    rescued = intersect(fn2,[prob_high_syn;prob_high_nonsyn]);
    tp2 = [tp2; rescued];
    fn2 = fn2(~ismember(fn2,rescued));
    fp2 = unique([fp2; prob_high_nonsyn]);
end

toc;

%}

%}
%% Functions


function [nearest_vc_id, dist, ncontacts] = get_nearest_vc(VC, vc_of_seg, ix, iy, iz)
% There may be faster way of doing this...   

    nearest = 1000;
    dist = 1000;
    nearest_vc_id = 0;
    ncontacts=0;
    
    for j = 1:numel(vc_of_seg)
        [vcx,vcy,vcz] = ind2sub(size(VC),find(VC==vc_of_seg(j)));            
        
        % First, find proximal vesicle cloud. 
        [~,d] = dsearchn([vcx(1:ceil(end/100):end), vcy(1:ceil(end/100):end), vcz(1:ceil(end/100):end)], ...
                           [ix(1:ceil(end/100):end), iy(1:ceil(end/100):end), iz(1:ceil(end/100):end)]);
 
        minimum = min(d);  
        if minimum <= nearest
            nearest = minimum;
            nearest_vc_id = vc_of_seg(j);
        end
        
        % There may be multiple vesicle segments in proximity.
        % Then, select the one with largest contact.
        if minimum < 500
            [~,d] = dsearchn([vcx, vcy, vcz], [ix, iy, iz]);
            minimum2 = min(d);
            if minimum2 < 10
                val = sum(d==minimum2 | d==min(d(d>minimum2 )));
                if ncontacts < val
                    ncontacts = val;
                    dist = minimum2;
                    nearest_vc_id = vc_of_seg(j);
                end
            end
        end                        
    end
end

% extract presynapse segment id from vesicle cloud volume hdf5 file by
% jwgim
function vc_segid_match = extract_gtsegid_of_vc(vc_detect, gt_seg)
    %extract presynapse celltypes

    all_vc_id = unique(vc_detect(:));
    all_vc_id(all_vc_id==0) = [];

    nvc = numel(all_vc_id);

    vc_segid_match = all_vc_id;
    vc_segid_match = [vc_segid_match zeros([nvc 1],'uint32')];
    
    parfor iter=1:nvc
        idx = find(vc_detect==iter);
        match_segids = unique(gt_seg(idx(:)));        
        match_segids(match_segids==0) = [];
      %  sprintf('number of matches = %d', numel(match_segids));

        if numel(match_segids) > 1
            dominant = 0;
             for i=numel(match_segids)
                 size = numel(find(gt_seg(idx(:))==match_segids(i)));
                 if size > dominant
                     vc_segid_match(iter,2) = match_segids(i);
                 end
             end
        elseif numel(match_segids) == 1
            vc_segid_match(iter, 2) = match_segids(1);
        else 
            warning(['Found no segment match for vesicle ', num2str(iter)]) 
        end
        
    %    disp(['Vesicle ', num2str(iter), '  matched to ', num2str( vc_segid_match(iter, 2) )]);

    end
end

function a = num_voxels_larger_than(intfce_prob, threshold)
    a = numel(find(intfce_prob > threshold));
end









        