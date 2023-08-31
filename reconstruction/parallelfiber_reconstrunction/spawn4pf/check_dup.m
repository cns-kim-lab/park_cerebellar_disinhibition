function cons1 = check_dup(task_id)

global h_sql

connsql();

% rst_dir = '/data/lrrtm3_wt_pf_review/log/';
% rst_file_name = 'check_dup_tasks';
% rst_path = [rst_dir rst_file_name];
% fid = fopen(rst_path,'w');

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
cell_name_1 = mysql(h_sql, sprintf(['select cm.name from cells as c join cell_metadata as cm on c.meta_id=cm.id where c.id=%d'],cell_1));
fprintf(['Input task [%d] (progress: %s) (%d:%s)\n'], ...
    task_id, char(desc_progress_1), cell_1,char(cell_name_1));

for i=1:length(cons1)
    
    if status(i)~=0
        continue
    end
    
    dup_task = setdiff([task1(i),task2(i)],task_id);
    [task_progress_2, cell_2] = mysql(h_sql, sprintf(['select progress, cell_id from tasks where id=%d;'],dup_task));
    desc_progress_2 = mysql(h_sql, sprintf(['select description from enumerations ' ...
        'where table_name="tasks" && field_name="progress" && enum=%d;'],task_progress_2));
    [cell_name_2, cell_status_2] = mysql(h_sql, sprintf('select cm.name, c.status from cells as c join cell_metadata as cm on c.meta_id=cm.id where c.id=%d',cell_2));
    desc_cell_status_2 = mysql(h_sql, sprintf('select description from enumerations where table_name="cells" and field_name="status" and enum=%d;', cell_status_2));
    fprintf('  duplicated task [%d] (progress: %s) (%d:%s:%s)\n', ...
        dup_task, char(desc_progress_2), cell_2, char(desc_cell_status_2), char(cell_name_2));
    
    Aseg = mysql(h_sql,sprintf('select segments from consensuses where id=%d;',cons1(i)));
    Aseg = regexp(Aseg, '\d*', 'Match');
    Aseg = cellfun(@str2num,Aseg{1});
    
    Bseg = mysql(h_sql,sprintf('select segments from consensuses where id=%d;',cons2(i)));
    Bseg = regexp(Bseg, '\d*', 'Match');
    Bseg = cellfun(@str2num,Bseg{1});
    
    taskA = task1(i);
    taskB = task2(i);
    if(task1(i)~=task_id)
        Cseg = Aseg;
        Aseg = Bseg;
        Bseg = Cseg;
        taskB = task1(i);
        taskA = task2(i);
    end
    
    [net_id_A, vol_id_A] =  mysql(h_sql, sprintf('select v.net_id, v.id from tasks as t join volumes as v on t.volume_id = v.id where t.id=%d;', taskA));
    [net_id_B, vol_id_B] =  mysql(h_sql, sprintf('select v.net_id, v.id from tasks as t join volumes as v on t.volume_id = v.id where t.id=%d;', taskB));
    
    if net_id_A{1} == net_id_B{1}
        
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
    else
        
        fprintf('   differnt net id task\n');
        
        [~, dslA] = find_exist_tasks_this(taskA, vol_id_A, Aseg);
        [~, dslB] = find_exist_tasks_this(taskB, vol_id_B, Bseg);
        if ~isempty(dslA)
            fprintf('   duplicated segments A(%s): %s\n', net_id_B{1}, sprintf('%d ', dslA{4}{dslA{3}==taskB}));
        end
        if ~isempty(dslB)
            fprintf('   duplicated segments B(%s): %s\n', net_id_A{1}, sprintf('%d ', dslB{4}{dslB{3}==taskA}));
        end
    end
    
    figure(i)
    draw_test(task1(i),task2(i));
    
%     fprintf(fid, sprintf(['%d %d\n'],task1(i),task2(i)));
    pause;
    
end

mysql(h_sql, 'close'); 

end
