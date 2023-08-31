% % % % % % 06.27 - modified code by je.son

% function rtn = lrrtm3_find_task_at_coord(coord, varargin)
% function rtn = lrrtm3_find_task_at_coord(coord, varargin, mesh_path, opt)
function rtn = lrrtm3_find_task_at_coord(coord, varargin, dataset, mesh_path, opt)
addpath /data/lrrtm3_wt_code/matlab/mysql/

if ~exist('dataset', 'var')
    dataset = 1;
end
[~,dataset] = lrrtm3_get_global_param(dataset);

% % % 0618 - check using reconstruction file
if exist('mesh_path') && ~exist('opt', 'var')
    lrrtm3_find_cell_recon_at_coord(mesh_path, coord);
elseif exist('mesh_path') && strcmp(opt, 'partition')
    lrrtm3_find_cell_recon_at_coord(mesh_path, coord, 'partition');    
end

% 06.11 - change connection information
global h_sql
try
    h_sql = mysql('open','kimserver106','omnidev','rhdxhd!Q2W');
catch    
    fprintf('stat - already db open, close and reopen\n');    
    mysql(h_sql, 'close');
    h_sql = mysql('open','kimserver106','omnidev','rhdxhd!Q2W');
end

r = mysql(h_sql, 'use omni');
if r <= 0
    fprintf('db connection fail\n');
    return;
end

vol_seg_list = lrrtm3_find_vol_seg_at_coord(coord, dataset);

rtn = [];
num_data = 0;

query = sprintf('select description from enumerations where table_name=''tasks'' and field_name=''progress'' order by enum');
task_progress_strings = mysql(h_sql, query);

query = sprintf('select description from enumerations where table_name=''tasks'' and field_name=''status'' order by enum');
task_status_strings = mysql(h_sql, query);

for i = 1:numel(vol_seg_list)
    
    vol_id = vol_seg_list(i).vol_id;
    nxyz = textscan(vol_id, '%s x%02d y%02d z%02d','delimiter','_');
    segment = vol_seg_list(i).segment; 

% % %     06.11 - modified code , including 'cell_metadata' table
    query = sprintf(['select t.id, c.id, cm.name, t.status, t.progress, t.latest_consensus_version, s.version, s.segments ' ...
                     'from tasks t ' ... 
                     'inner join cells c on t.cell_id = c.id ' ...
                     'inner join consensuses s on t.id = s.task_id '...
                     'inner join volumes v on t.volume_id = v.id '...           
                     'inner join cell_metadata cm on cm.id = c.meta_id '...
                     'where v.dataset_id = 1 and v.net_id = ''%s'' and v.vx = %d and v.vy = %d and v.vz = %d'],nxyz{1}{1},nxyz{2},nxyz{3},nxyz{4});


% % %   0618 - original code
%     query = sprintf(['select t.id, c.id, c.name, t.status, t.progress, t.latest_consensus_version, s.version, s.segments ' ...
%                      'from tasks t ' ... 
%                      'inner join cells c on t.cell_id = c.id ' ...
%                      'inner join consensuses s on t.id = s.task_id '...
%                      'inner join volumes v on t.volume_id = v.id '...                                
%                      'where v.dataset_id = 1 and v.net_id = ''%s'' and v.vx = %d and v.vy = %d and v.vz = %d'],nxyz{1}{1},nxyz{2},nxyz{3},nxyz{4});

    [task_id, cell_id, cell_name, task_status, task_progress, latest_consensus_version, consensus_version, segment_list_string] = mysql(h_sql, query);
    
    for j = 1:numel(task_id) 
        segment_list = str2double(split(strtrim(segment_list_string{j}),' '))';
        if ~any(segment_list==segment)
            continue;
        end
        
        num_data = num_data + 1;
        rtn(num_data).task_id = task_id(j);
        rtn(num_data).cell_name = cell_name{j};
        rtn(num_data).cell_id = cell_id(j);
        rtn(num_data).status = task_status_strings{task_status(j)+1};
        rtn(num_data).task_progress = task_progress_strings{task_progress(j)+1};
        rtn(num_data).consensus_version = consensus_version(j);
        rtn(num_data).latest_consensus_version = latest_consensus_version(j);
    end
    
end

mysql(h_sql, 'close');

if exist('varargin','var') && any(strcmp(varargin,'v'))
    print_result(rtn);
end


end

%%
function print_result(task_data)

if isempty(task_data)
    fprintf('no data\n');
end

for i = 1:numel(task_data)
    fprintf('task [%d] (consensus version: %d/%d) (status: %s) (progress: %s) (%d: %s)\n', ...
        task_data(i).task_id, task_data(i).consensus_version, task_data(i).latest_consensus_version, task_data(i).status, task_data(i).task_progress, task_data(i).cell_id, task_data(i).cell_name);
end

end
