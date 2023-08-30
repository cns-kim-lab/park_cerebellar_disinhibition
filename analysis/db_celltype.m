
%   0   unknown
%   1   purkinje cell
%   2   parallel fiber
%   3   climbinig fiber
%   4   interneuron
%   5   glia
%   6   golgi
%   7   undecidable



addpath /data/lrrtm3_wt_code/matlab/mysql/;
h_sql = mysql( 'open', 'localhost', 'omnidev', 'rhdxhd!Q2W');
rtn = mysql(h_sql, 'use omni_20210503');
%query_example = sprintf('select omni_id from cell_metadata where id in (select meta_id from cells where status=%s) and type1=%s limit 400,10', '1', '0');


%% get unidentified cells
%{
query = sprintf('select m.omni_id from cell_metadata m inner join cells c on m.id=c.meta_id where c.status=1 and m.type1=0');
unidentified = mysql(h_sql, query);

filename = '/data/research/share/synapseDetection/unidentified_cells_210503.txt';
fid = fopen(filename,'w');
fprintf(fid,'omni_id,type,body\n');
for i=1:numel(unidentified)
    fprintf(fid,'%d,\n', unidentified(i));
end
fclose(fid);
%}

%% classify cell types 

%{
ngroup = floor(numel(unidentified)/50);

for i = 1:ngroup
    st = (i-1)*50+1;
    en = i*50;
    for j = st:en
        fprintf('%d ', unidentified(j));
    end
    fprintf('\n');
end
%}

%% update db cell-type info
%update_file = '/data/research/share/synapseDetection/unidentified_cells_200313.txt';
update_file = '/data/research/share/synapseDetection/unidentified_cells_210503_final.txt';
s = tdfread(update_file, ',');
%s = tdfread(update_file, '\t');

omni_id = s.omni_id;
celltype = s.type;
body = s.body;


for i = 1:length(omni_id)
    this_id = uint64(omni_id(i));
    this_type = 0;
    this_body = body(i);
    str = celltype(i,:);
    str(isspace(str)) = [];
    
    switch str
        case ('pc')
            this_type = 1;
        case ('pf')
            this_type = 2;
        case ('cf')
            this_type = 3;
        case ('in')
            this_type = 4;
        case ('glia')
            this_type = 5;
        case ('gc')
            this_type = 6;
        case ('und')
            this_type = 7;
        otherwise
            fprintf('%s %d', 'Typo in update file. See ID = ', this_id);
    end
    query_update = sprintf('update cell_metadata set type1=%d, type2=%d where omni_id=%d' , this_type, this_body, this_id);
    mysql(h_sql,query_update);

end
%}