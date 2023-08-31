function cons1 = check_dup(task_id)

global h_sql

addpath /data/research/bahn/code/mysql/
%{
mysql('close'); 
%h_sql = mysql('open','kimserver101','omnidev','rhdxhd!Q2W');
h_sql = mysql('open','10.1.26.181','root','1234');
mysql(h_sql, 'use omni0714t');
%mysql(h_sql, 'use omni');
%}
connsql();

rst_dir = '/data/research/bahn/code/';
rst_file_name = sprintf('check_dup_tasks');
rst_path = [rst_dir rst_file_name];
fid = fopen(rst_path,'w');

[cons1,cons2,dup_seg,status,task1,cell1,task2,cell2]= ...
mysql(h_sql,sprintf(['select r.*,c.task_id as task_id_2,t.cell_id as cell_id_2 ' ...
    'from(select d.consensus_id_1,d.consensus_id_2,duplicated_segments,d.status,c.task_id as task_id_1,t.cell_id as cell_id_1 ' ...
    'from duplications as d join consensuses as c join tasks as t on d.consensus_id_1=c.id && c.task_id=t.id) ' ...
    ' as r join consensuses as c join tasks as t on r.consensus_id_2=c.id && c.task_id=t.id ' ...
    'where task_id_1=%d || t.id=%d;'],task_id,task_id));

clf


[task_progress_1, cell_1] = mysql(h_sql, sprintf(['select progress, cell_id from tasks where id=%d;'],task_id));
desc_progress_1 = mysql(h_sql, sprintf(['select description from enumerations ' ...
    'where table_name="tasks" && field_name="progress" && enum=%d;'],task_progress_1));
cell_name_1 = mysql(h_sql, sprintf(['select name from cells where id=%d'],cell_1));
fprintf(['Input task [%d] (progress: %s) (%d:%s)\n'], ...
    task_id, char(desc_progress_1), cell_1,char(cell_name_1));

for i=1:length(cons1)
    
    if status(i)==1
        continue
    end
    
    dup_task = setdiff([task1(i),task2(i)],task_id);
    [task_progress_2, cell_2] = mysql(h_sql, sprintf(['select progress, cell_id from tasks where id=%d;'],dup_task));
    desc_progress_2 = mysql(h_sql, sprintf(['select description from enumerations ' ...
        'where table_name="tasks" && field_name="progress" && enum=%d;'],task_progress_2));
    cell_name_2 = mysql(h_sql, sprintf(['select name from cells where id=%d'],cell_2));
    fprintf(['  duplicated task [%d] (progress: %s) (%d:%s)\n'], ...
        dup_task, char(desc_progress_2), cell_2, char(cell_name_2));
    
    Aseg = mysql(h_sql,sprintf('select segments from consensuses where id=%d;',cons1(i)));
    Aseg = regexp(Aseg, '\d*', 'Match');
    Aseg = cellfun(@str2num,Aseg{1});
    
    Bseg = mysql(h_sql,sprintf('select segments from consensuses where id=%d;',cons2(i)));
    Bseg = regexp(Bseg, '\d*', 'Match');
    Bseg = cellfun(@str2num,Bseg{1});
    
    if(task1(i)~=task_id)
        Cseg = Aseg;
        Aseg = Bseg;
        Bseg = Cseg;
    end
        
    
    AdB = sprintf('%d ',setdiff(Aseg,Bseg));
    BdA = sprintf('%d ',setdiff(Bseg,Aseg));
    
    segments = regexp(dup_seg{i}, '\d*', 'Match');
    segments = cellfun(@str2num,segments);
    duplicated_segments = sprintf('%d ',segments);
    
    fprintf('   A - B segments: ');
    fprintf(AdB);
    fprintf('\n');
    
    fprintf('   B - A segments: ');
    fprintf(BdA);
    fprintf('\n');
    
    fprintf('   A & B segments: ');
    fprintf(duplicated_segments);
    fprintf('\n');
    
    [seg] = mysql(h_sql, sprintf('select segments from consensuses where id=%d||id=%d;',cons1(i),cons2(i)));
    seg1 = regexp(seg{1}, '\d*', 'Match'); seg2 = regexp(seg{2}, '\d*', 'Match');
    seg1 = cellfun(@str2num,seg1); seg2 = cellfun(@str2num,seg2);
    
    if isempty(setdiff(seg1,seg2)) && isempty(setdiff(seg2,seg1))
        fprintf('   same segments task\n');
    end
    
    figure(i)
    draw_test(task1(i),task2(i));
    
    fprintf(fid, sprintf(['%d %d\n'],task1(i),task2(i)));
    %pause;
    
end

mysql('close'); 
fclose(fid);

end



































































