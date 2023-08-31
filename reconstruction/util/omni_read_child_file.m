%% read child list from omni exported txt file
function [seg]=omni_read_child_file(FileChildList)

seg.lSprVxl=[];
seg.szSprVxl=[];
seg.nSprVxl=[];

%example:
%25637 : 0, 0, 552
%27270 : 25637, 0.949978, 46479

fi=fopen(FileChildList,'r');
List=fscanf(fi,'%d : %d, %f, %d\n',[4 inf]);
fclose(fi);

if isempty(List)
    return;
end

seg.lSprVxl=List(1,:);
seg.szSprVxl=List(4,:);
seg.nSprVxl=numel(seg.lSprVxl);

end
