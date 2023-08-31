function connsql()

global h_sql

fid = fopen('/data/lrrtm3_wt_code/matlab/spawn/connection/connset');
conninfo = textscan(fid,'%s','delimiter', '\n');
conninfo = conninfo{1};

for i=1:length(conninfo)
    pos = strfind(conninfo{i,1},': ') + 2;
    conninfo{i,1} = conninfo{i,1}(pos:end);
end

addpath(conninfo{1,1});
%mysql('close'); 

h_sql = mysql('open',conninfo{2,1},conninfo{3,1},conninfo{4,1});

rtn_step = mysql(h_sql, ['use ' conninfo{5,1}]);



end
