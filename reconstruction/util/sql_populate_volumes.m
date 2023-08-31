% % % % % 06.12 - modified code by je.son

function lrrtm3_sql_populate_volumes(dataset)
addpath /data/lrrtm3_wt_code/matlab/mysql/

if ~exist('dataset', 'var')
    dataset = 1;
end
[param, ~] = lrrtm3_get_global_param(dataset);
% lrrtm3_param = lrrtm3_get_global_param();

% 06.12 - kimserver106 DB
try
    h_sql = mysql('open','kimserver106','omnidev','rhdxhd!Q2W');
catch
    fprintf('stat - already db open, close and reopen\n');
    mysql(h_sql, 'close');
    h_sql = mysql('open','kimserver106','omnidev','rhdxhd!Q2W');
end

rtn = mysql(h_sql, 'use omni');

z_dirs = dir(sprintf('%sz*',param.home_vols));
% z_dirs = dir(sprintf('%s/z*',param.home_vols));

for z_it = 1:numel(z_dirs)

    y_dir_pattern = sprintf('%s/%s/y*',z_dirs(z_it).folder,z_dirs(z_it).name);
    y_dirs = dir(y_dir_pattern);
    
    for y_it = 1:numel(y_dirs)

        vol_pattern = sprintf('%s/%s/*.omni',y_dirs(y_it).folder,y_dirs(y_it).name);
        vol_files = dir(vol_pattern);
    
        for vol_it = 1:numel(vol_files)
            
            vol_file_name = vol_files(vol_it).name;
            vol_name_split = textscan(vol_file_name, '%s %s x%d y%d z%d %s %s %s %s %s %s %s %s','delimiter','_'); 

            net_id = vol_name_split{2}{1};
            vx = vol_name_split{3}(1);
            vy = vol_name_split{4}(1);
            vz = vol_name_split{5}(1);
            path = sprintf('%sz%02d/y%02d/%s', param.home_vols, vz, vy, vol_file_name);
%             path = sprintf('%s/z%02d/y%02d/%s', param.home_vols, vz, vy, vol_file_name);
            
            query = sprintf('select id from volumes where net_id=''%s'' and vx=%d and vy=%d and vz=%d',net_id,vx,vy,vz);
            exist_vol_id = mysql(h_sql, query);
            if ~isempty(exist_vol_id)
                fprintf('%s already in table\n',vol_file_name);
                continue;
            end
            query = sprintf(['insert into volumes (dataset_id,net_id,path,vx,vy,vz,status) ' ...
                              'values (%d,''%s'',''%s'',%d,%d,%d,0);'], param.dataset_id, net_id, path, vx, vy, vz);
            fprintf('%s\n',query);
            rtn = mysql(h_sql, query);
        end
    end
end

mysql(h_sql,'close');

end


