function rtn = lrrtm3_find_task_at_coord_using_sheet(coord, varargin)

global home_vols home_trace_files 
home_vols = sprintf('/data/lrrtm3_wt_omnivol/');
home_trace_files = sprintf('/data/lrrtm3_wt_omnivol/cell_trace_data/');

global sheet_name
sheet_name = 'Sheet 1';

rtn = [];

cell_data = lrrtm3_get_cell_data();

data_file = '~/lrrtm3_find_task_at_coord_data.mat';
if (exist('varargin','var') && any(strcmp(varargin,'r'))) || ~exist(data_file,'file')
    [~, cell_trace_data] = get_cell_trace_data(cell_data);
    child_file_data = get_child_files(cell_data);
    save(data_file,'cell_trace_data','child_file_data');
else
    load(data_file);
end

vol_seg_list = lrrtm3_find_vol_seg_at_coord(coord);

for i = 1:numel(vol_seg_list)
    
    vol_id = vol_seg_list(i).vol_id;
    segment = vol_seg_list(i).segment; 
    
    % set of child files always include the set of spread sheet tasks
    % search child files first, check if they exist in the sheet
    idx_vol = strcmp({child_file_data.vol_id}, vol_id);
    idx_seg = cellfun(@(x) ismember(segment, x), {child_file_data.seg_list});
    idx_list = find(idx_vol & idx_seg);
    
    for idx = idx_list % this includes child files of all users

        status = 'stashed';
        
        cell_name = child_file_data(idx).cell_name;        
        task_id = child_file_data(idx).task_id;
        user_id = child_file_data(idx).user_id;
        
        idx_cell = strcmp({cell_trace_data.cell_name},cell_name);
        idx_task = strcmp({cell_trace_data.task_id},task_id);
        
        if strcmp(user_id,'seed') 
            idx_trace_list = idx_task & idx_cell; 
            if any(idx_trace_list)
                status = 'normal';
            end
        else
            idx_user = strcmp({cell_trace_data.user_id},user_id);
            idx_trace_list = idx_task & idx_user & idx_cell;
            if any(idx_trace_list)
                status = 'normal';
            end                        
        end

        rtn = add_data(rtn, task_id, user_id, cell_name, status);                        
    end

end

if exist('varargin','var') && any(strcmp(varargin,'v'))
    print_result(rtn);
end


end

%%
function rtn = add_data(rtn, task_id, user_id, cell_name, status)

if ~isempty(rtn)
    idx = strcmp({rtn.task_id},task_id) & strcmp({rtn.user_id},user_id) & strcmp({rtn.cell_name},cell_name);
    if any(idx)
        return;
    end
    
    if strcmp(user_id,'seed')
        idx = strcmp({rtn.task_id},task_id) & strcmp({rtn.cell_name},cell_name);
        if any(idx)
            return;
        end
    end
    
    idx = strcmp({rtn.user_id},'seed') & strcmp({rtn.task_id},task_id) & strcmp({rtn.cell_name},cell_name);
    if any(idx)
        rtn(idx) = [];
    end
end


num_data = numel(rtn) + 1;
rtn(num_data).task_id = task_id; 
rtn(num_data).user_id = user_id; 
rtn(num_data).cell_name = cell_name; 
rtn(num_data).status = status;
        
end

%%
function print_result(task_data)

if isempty(task_data)
    fprintf('no data\n');
end

for i = 1:numel(task_data)
    fprintf('[%s] [user:%s] [cell:%s] [status: %s]\n',task_data(i).task_id,task_data(i).user_id,task_data(i).cell_name,task_data(i).status);
end

end

%% 
function child_file_data = get_child_files(cell_data)

global home_trace_files

child_file_data = [];
num_data = 0;

for j = 1:numel(cell_data)

    cell_name = cell_data(j).cell_name;
    pattern = sprintf('%s/%s/*_*.child', home_trace_files, cell_name);
    files = dir(pattern);

    for i = 1:numel(files)
        child_folder = files(i).folder;
        child_file = files(i).name;

        % net_x_y_z_seg.user_id.child
        pos = strfind(child_file,'_');
        if numel(pos)<4
            fprintf('file name error: %s\n', child_file);
            continue;
        end
        vol_id = child_file(1:pos(4)-1);

        pos = strfind(child_file,'.');
        if numel(pos)<2
            fprintf('file name error: %s\n', child_file);
            continue;
        end
        user_id = child_file(pos(1)+1:pos(2)-1);
        task_id = child_file(1:pos(1)-1);
        if strcmp(user_id,'cons')
            task_id = sprintf('%s.cmpr',task_id);
        end

        seg = omni_read_child_file(sprintf('%s/%s',child_folder, child_file));
        seg_list = seg.lSprVxl; 

        num_data = num_data + 1;
        child_file_data(num_data).vol_id = vol_id;
        child_file_data(num_data).task_id = task_id;
        child_file_data(num_data).user_id = user_id;
        child_file_data(num_data).seg_list = seg_list;
        child_file_data(num_data).cell_name = cell_name;
    end
    
end

end

%%
function [vol_list, cell_trace_data] = get_cell_trace_data(cell_data)

vol_list = [];
cell_trace_data = [];

access_token_sheet = gdrive_helper_refresh_access_token('sheet');

num_data = 0;

for j = 1:numel(cell_data)

    cell_name = cell_data(j).cell_name;
    tasks = get_all_tasks(access_token_sheet, cell_name);

    for i = 1:numel(tasks)
        task_id = tasks(i).id; 
        pos = strfind(task_id, '.cmpr'); 
        if ~isempty(pos)
%             task_id = task_id(1:pos-1);
            if isempty(tasks(i).user) || strcmp(tasks(i).user,'')
                user_id='';
            else
                user_id='cons';
            end
        else
            if isempty(tasks(i).user) || strcmp(tasks(i).user,'')
                user_id = 'seed';
            else
                user_id = tasks(i).user;
            end
        end

        pos = strfind(task_id, '_');
        vol_id = task_id(1:pos(end)-1);
        vol_list = [vol_list; {vol_id}];
        
        num_data = num_data + 1; 
        cell_trace_data(num_data).cell_name = cell_data(j).cell_name;
        cell_trace_data(num_data).task_id = task_id;
        cell_trace_data(num_data).user_id = user_id;
    end

end

vol_list = unique(vol_list);
    
end

%%
function rtn_tasks = get_all_tasks(access_token_sheet, cell_name)

rtn_tasks=[];

global sheet_name

sheet_key = gdrive_get_spreadsheet_key(cell_name);
sheet_metadata = gdrive_get_sheet_metadata(access_token_sheet, sheet_key);

for i=1:numel(sheet_metadata.sheet)
    if strcmp(sheet_metadata.sheet(i).title, sheet_name)
        num_rows = sheet_metadata.sheet(i).num_rows;
        break;
    end
end

range = sprintf('A2:G%d',num_rows);
raw_tasks = gdrive_get_cell_value(access_token_sheet, sheet_key, sheet_name, range);
num_rows = numel(raw_tasks);

%status common: nofile, null (ignore task, in such case as needing human work)
%status trace tasks: new (newly spawned, need further spawning check), traced, done (after comparison)
%status comp tasks: compared, newvol, done (after spawning)

%status 'null': time_end not written, 'traced': time_end written but status not yet set

num_tasks=0;
for i=1:num_rows

    if isempty(raw_tasks{i})
        continue;
    end

    raw_tasks{i}{8}=[];
    
    num_tasks=num_tasks+1;
    rtn_tasks(num_tasks).sheet_row=i+1;
    rtn_tasks(num_tasks).id=raw_tasks{i}{1};
    rtn_tasks(num_tasks).parent=raw_tasks{i}{2};
    rtn_tasks(num_tasks).user=raw_tasks{i}{3};
    timeend=raw_tasks{i}{6};
    rtn_tasks(num_tasks).status=raw_tasks{i}{7};

    if ~isempty(strfind(rtn_tasks(num_tasks).id,'.cmpr')) % a comparison task
        if ~isempty(timeend) && isempty(rtn_tasks(num_tasks).status)
            rtn_tasks(num_tasks).status='compared'; %find children
        end
    else
        if isempty(rtn_tasks(num_tasks).status) && ~isempty(timeend)
            rtn_tasks(num_tasks).status='traced'; %compare tasks if both traced
        end
    end

end

end