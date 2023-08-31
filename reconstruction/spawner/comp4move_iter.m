clc; clear;

global h_sql

connsql();

omni_id_list = [4,11,12,13,15,16,17,19,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38];

cell_id = zeros(1,length(omni_id_list));
for i=1:length(omni_id_list)
   cell_id(i) = mysql(h_sql,sprintf('select id from cells where omni_id=%d',omni_id_list(i))); 
end
mysql(h_sql,'close')

for i=1:length(omni_id_list)
    
    comp4move(cell_id(i))
    
end