
%% read child list from omni exported txt file
function mst = omni_read_mst(mst_file_name)

fi = fopen(mst_file_name,'r');

num_lines = 0;

while ~feof(fi)
    edge = fread(fi, 1, 'uint32');
    node1 = fread(fi, 1, 'uint32');
    node2 = fread(fi, 1, 'uint32');
    garbage = fread(fi, 4, 'bit8');
    affin = fread(fi, 1, 'double');
    garbage = fread(fi, 8, 'bit8');

    if isempty(edge)
        break;
    end
    
    num_lines = num_lines + 1;
    mst(num_lines).edge = edge;
    mst(num_lines).node1 = node1;
    mst(num_lines).node2 = node2;
    mst(num_lines).affin = affin;
end

fclose(fi);

end
