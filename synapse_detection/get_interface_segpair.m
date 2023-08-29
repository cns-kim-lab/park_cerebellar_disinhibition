% This code will save a list of segment id pairs associated with given
% interfaces. 

% 'Splitted-and-assembled' interface cube has different interface IDs compared to the
% original cube. 
% This code is written thoughtlessly to re-compute the segment ID
% pairs, rather than assembling lists of segment pairs.  


%interface = h5read('/data/lrrtm3_wt_syn/interfaces/assembly/assembly_all_interfaces.h5', '/main');
interface = h5read('/data/lrrtm3_wt_syn/assembly/assembly_interface_relevant_test.h5', '/main');
origin = h5read('/data/research/share/synapseDetection/testvolume_interfaces_relevant_only.h5','/main');
cellSeg = h5read('/data/research/share/synapseDetection/testvolume_segmentation.h5', '/main');

origin = origin(1:992,1:992,1:248);
interface = interface(1:992, 1:992, 1:248);
id = unique(interface); id(1) = [];
oid = unique(origin); oid(1) = []; 
interface_translator = zeros(max(id),1);   % maps interface id of assembled volume to original interface id
diff = zeros(numel(id),1);
domina = zeros(numel(id),1);


for i=1:numel(id)
    this_id = id(i);
    if (mod(i,100) == 0)
        disp (['Checked ',  num2str(i), ' interfaces']);
    end
    x = origin(interface==this_id);
    x = double(x);
    [counts, elm] = hist(x, unique(x));
    [val, argmax] = max(counts);
    id1 = elm(argmax);
    interface_translator(this_id) = id1;
    y = origin(origin==id1);
    diff(i) = abs(numel(x) - numel(y));    
    domina(i) = counts(argmax)/numel(x);
    
    
    %    if diff > 50
 %       disp(['mis-assembled id ',num2str(id1), '  result id ', num2str(id(i)), ' diff ', num2str(diff)]);
  %  end
    
end

%save('/data/lrrtm3_wt_syn/assembly/interface_translator_test.mat','interface_translator');

%}

miss = oid(~ismember(oid, interface_translator));
miss_size= zeros(length(miss),1);
for i = 1:length(miss)
   x = origin(origin==miss(i));
   miss_size(i) = numel(x);
end
%}