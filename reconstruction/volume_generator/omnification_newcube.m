function omnification_newcube(notes, prefix, vidx, force)
    switch nargin
        case 0
            fprintf('parameter error. notes or specific volume info needed.\n');
            return
        case 1            
            process_type = 1;   %bynotes
        case 2
            fprintf('parameter error. volume index needed.\n');
            return
        case 3
            process_type = 2;   %specific
        case 4
            if ~isempty(force) && force
                process_type = 3;   %specific_foced
            else
                process_type = 2;   %specific
            end
        otherwise
            fprintf('parameter error. too many input arguments.\n');
            return
    end
    
    if process_type == 1    %bynotes
        if isempty(notes)
            return
        end
        pos = strfind(notes, '_');
        if isempty(pos)
            fprintf('target notes is not appropriate. (good examples: target_c1b or merge_c1a)\n');
            return
        end
        if strcmpi(notes(1:pos-1), 'merge')
            if strcmpi(notes(pos+1:end), 'c1a')
                to_be_net = 'C1b';
            elseif strcmpi(notes(pos+1:end), 'c1b')
                to_be_net = 'C1c';
            else
                fprintf('can''t decide target net_prefix.\n');
                return
            end
        elseif strcmpi(notes(1:pos-1), 'target')
            to_be_net = notes(pos+1:end);
            if ~strcmpi(to_be_net, 'c1b') && ~strcmpi(to_be_net, 'c1c')
                fprintf('this net_prefix is not available.\n');
                return
            end
        else
            fprintf('can''t decide target net_prefix.\n');
            return
        end
        to_be_net = [upper(to_be_net(1)) lower(to_be_net(2:end))];

        fprintf('Generates volumes to replace (%s)\n', to_be_net);
    else    %specific or specific forced
        if isempty(prefix) || isempty(vidx)
            fprintf('parameter error. please check again.\n');
            return
        end
        if ~strcmpi(prefix, 'c1b') && ~strcmpi(prefix, 'c1c')
            fprintf('parameter error. invalid net prefix. C1b or C1c is available.\n');
            return
        end
        if sum(vidx > [31 22 9])>0 || sum(vidx < [1 1 1]>0)
            fprintf('parameter error. invalid volume index. [1,1,1]~[31,22,9] is available.\n');
            return
        end
        
        to_be_net = [upper(prefix(1)) lower(prefix(2:end))];
        
        fprintf('Generates volume %s_%d,%d,%d\n', to_be_net, vidx);
    end
       
    jobconfig_path = sprintf('/data/research/jwgim/lrrtm3_omnification/NetKslee/cfg_%s.txt', to_be_net);
    if exist('jobconfig_path', 'var') < 1
        fprintf('@jobconfig_path needed\n');
        return
    end
    if ~isdeployed
        addpath('/data/research/jwgim/matlab_code/');
        addpath('/data/research/jwgim/matlab_code/auto_cube_generate/');
        addpath('/data/research/jwgim/matlab_code/hdf5_ref/');
        addpath('/data/research/jwgim/matlab_code/watershed_new/');
        addpath('/data/lrrtm3_wt_code/matlab/mysql/');

        joblist_chan_path = '/job_table_chan.txt';
    else
        joblist_chan_path = ['/job_table_chan_' phase '.txt'];
    end
    
    sql_server = 'kimserver106';
    sql_server_id = 'omnidev';    

    if process_type == 1    %bynotes
        %% get replace list
        vidx_list = get_replace_list(sql_server, sql_server_id, notes);
        if isempty(vidx_list)
            fprintf('can''t find match task.\n');
            return
        end
    else
        vidx_list = vidx;
    end

    %config file parsing
    jobcfg = parsing_jobconfig(jobconfig_path);
    [omni_create_path,~] = get_cfg(jobcfg, 'omni_create_path');
    [job_default_path,~] = get_cfg(jobcfg, 'job_default_path');
    [netname,~] = get_cfg(jobcfg, 'netname');
    [net_prefix,~] = get_cfg(jobcfg, 'omni_net_prefix');
    
    if process_type == 3    %specific_forced
        fprintf('remove old volume (%s_x%02d_y%02d_z%02d)\n', to_be_net, vidx);
        syscmd = sprintf('rm -rf %sz%02d/y%02d/Net_%s_x%02d_y%02d_z%02d_*.omni*', omni_create_path, vidx(3), vidx(2), to_be_net, vidx);
        disp(syscmd);
        system(syscmd);        
    end

    [row,~] = size(jobcfg);
    cidx = 0;
    for iter=1:row
        if strcmpi(jobcfg(iter,1), 'start_cube_idx')
            cidx = iter;
            break
        end
    end
    if cidx < 1
        fprintf('@start_cube_idx not found\n');
        return
    end

    [ws_high,valid] = get_cfg(jobcfg, 'watershed_high');
    if valid == 1
        ws_param_set = struct('high', str2num(ws_high), 'low', 0.01, 'dust', 500, ...
            'dust_low', 0.001, 'threads', 4, 'width', 256); 
    else
        ws_param_set = struct('high', 0.999, 'low', 0.01, 'dust', 500, ...
            'dust_low', 0.001, 'threads', 4, 'width', 256); 
    end
    norm_flag = 0;
    [normval,valid] = get_cfg(jobcfg, 'affinity_normalization');
    if valid == 1 && strcmpi(normval, 'sort')
        norm_flag = 1;  
        disp('affinity normalization: SORT');
    elseif valid==1 && strcmpi(normval, 'shift')
        norm_flag = 2;
        disp('affinity normalization: SHIFT');
    else
        disp('affinity normalization: OFF');
    end

    %% loop from here
    [row_vidx,~] = size(vidx_list);
    for list_idx=1:row_vidx
        time_ = sprintf('%s', datetime('now'));
        fprintf('%s job %d/%d, cube %d,%d,%d\n', time_, list_idx, row_vidx, vidx_list(list_idx,:));

        % change start_cube_idx (based on query result)
        jobcfg{cidx,2} = sprintf('%d,%d,%d', vidx_list(list_idx,:));    

        %chan: cubeidx, start, end (global), cube_size
        %fwd : cubeidx, global st-en, global valid st-en, local valid st-en, cube size
        [chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(jobcfg); 
        job_list_fullpath_chan = [job_default_path netname joblist_chan_path];

        [row,~] = size(chan_coordinate_tbl);
        idx_list = 1:row;
        for ridx = idx_list
            prj_exist = check_omni_prj_exist(omni_create_path, net_prefix, chan_coordinate_tbl, ridx);  
            if prj_exist == 1
                chan_coordinate_tbl{ridx,5} = 'DONE'; 
                fprintf('this job already done (%d)\n', ridx);
                continue
            end    

            cubeidx = chan_coordinate_tbl{ridx,1};
            seg_fname = sprintf('%sseg_x%dy%dz%d.h5', omni_create_path, cubeidx);
            %check existence of seg file
            if exist(seg_fname, 'file') < 1    
                %get assembled cube
                [cube, valid] = get_affinity_cube(jobcfg, ridx, chan_coordinate_tbl, fwd_coordinate_tbl);   
                if valid ~= 1
                    fprintf('can''t find needed cube (%d), pass this job\n', ridx);
                    chan_coordinate_tbl{ridx,5} = 'PASS';
                    continue
                end
                if norm_flag == 1   %normalization (histogram flaten)             
                    cube = affinityNorm(cube, 'matrix'); %for old unet
                elseif norm_flag == 2   %histogram shift 
                    cube = max(0.0, (cube - 0.001));    
                end

                %affinity to segment (WS)
                [~,~,~] = aff2seg_detail(cube, 'matrix', seg_fname, 1, ws_param_set);   %change function
            end

            %make omni project script
            create_omni_script(jobcfg, seg_fname, chan_coordinate_tbl, ridx);    

            %watershed to omnivolume (omni project)
            syscmd = sprintf('%smake_x%dy%dz%d.sh', omni_create_path, cubeidx);
            disp(syscmd);
            system(syscmd);
            syscmd = sprintf('rm -rf %smake_x%dy%dz%d.sh', omni_create_path, cubeidx);
            disp(syscmd);
            system(syscmd);

            ret = omni_postprocess_cube(chan_coordinate_tbl, ridx, omni_create_path, net_prefix);  %merge yaml file 
            if ret ~= 1 
                chan_coordinate_tbl{ridx,5} = 'DONE';
            end
        end       
    end
    if row_vidx > 0
        sql_populate_volumes(sql_server, sql_server_id, vidx_list, to_be_net);
    else
        fprintf('empty list\n');
    end

end %end of main function
%%
function volume_info = get_replace_list(sql_server, sql_server_id, notes)
    %connect db server & get list of merged volume
    global h_sql
    h_sql = mysql('open', sql_server, sql_server_id, 'rhdxhd!Q2W');    
    rtn = mysql(h_sql, 'use omni');
    
    fprintf('get_replace_list, connect to %s\n', sql_server);
    
    if rtn <= 0
        fprintf('db connection failed\n');
        return
    end

    query = sprintf('SELECT DISTINCT v.vx,v.vy,v.vz FROM volumes v INNER JOIN tasks t ON t.volume_id=v.id WHERE t.status IN (0,2,3) AND t.notes LIKE ''%%%s%%'';', ...
        lower(notes));
    [vx,vy,vz] = mysql(h_sql, query);
    volume_info = [vx';vy';vz']';

    %close db connection
    mysql(h_sql,'close');
end

%%
function failed = omni_postprocess_cube(chan_tbl, ridx, omni_root, net_prefix)
    failed = 0;
    meta_filename = 'projectMetadata.yaml';
    metao_filename = 'projectMetadata.yaml.old';
    meta_temp_filename = 'projectMetadata.yaml.temp';

    prj_exist = check_omni_prj_exist(omni_root, net_prefix, chan_tbl, ridx);  
    if prj_exist ~= 1
        disp(['@omni project not exist (rid=' num2str(ridx) ')']);
        chan_tbl{ridx,5} = 'MISSING';
        failed = 1;
        return
    end
        
    cube_idx = chan_tbl{ridx, 1};
    startp = chan_tbl{ridx, 2} .* [1,1,4];
    cube_size = chan_tbl{ridx, 4};
    
    omni_prj_path = sprintf('%sz%02d/y%02d/Net_%s_x%02d_y%02d_z%02d_st_%04d_%04d_%04d_sz_%d_%d_%d.omni.files', ...
        omni_root, cube_idx(3), cube_idx(2), net_prefix, cube_idx, startp, cube_size);
    
    fname = meta_filename;
    for iter=1:2    %1=.yaml, 2=.yaml.old
        chan_meta_path = sprintf('%sz%02d/y%02d/channel_info/x%02d_y%02d_z%02d/%s', '/data/lrrtm3_wt_omnivol/', ...
            cube_idx(3), cube_idx(2), cube_idx, fname); 
        seg_meta_path = [omni_prj_path '/' fname];
        save_meta_path = [omni_prj_path '/' meta_temp_filename];    
        merge_metadatafile(chan_meta_path, seg_meta_path, save_meta_path);

        syscmd = ['mv ' save_meta_path ' -f ' seg_meta_path];   %add -force option to prevent asking chmod overwrite
        disp(syscmd);
        system(syscmd);        
        syscmd = ['chmod 660 ' seg_meta_path]; %%chmod before mv to prevent asking chmod overwrite
        disp(syscmd);
        system(syscmd);
 
        fname = metao_filename; %chg file name (.yaml to .yaml.old)
    end
    syscmd = ['chown :kimlab_tracer ' omni_prj_path '/*yaml*'];
    disp(syscmd);
    system(syscmd);
end

%%
function save_tbl_as_file(filename, format, cellarray)
    fid = fopen(filename, 'w'); %overwirte
    [row, ~] = size(cellarray);
    for iter=1:row
        fprintf(fid, format, cellarray{iter,:});
    end
    fclose(fid);
end

%%
function sql_populate_volumes(sql_server, sql_server_id, vidx_list, to_be_net)
addpath /data/lrrtm3_wt_code/matlab/
addpath /data/lrrtm3_wt_code/matlab/mysql/
lrrtm3_param = lrrtm3_get_global_param(1);

h_sql = mysql('open', sql_server, sql_server_id,'rhdxhd!Q2W');
rtn = mysql(h_sql, 'use omni');

fprintf('populate_volume, connect to %s\n', sql_server);

for v_it = 1:size(vidx_list,1)
    vx = vidx_list(v_it,1);
    vy = vidx_list(v_it,2);
    vz = vidx_list(v_it,3);
    
    path_pattern = sprintf('%sz%02d/y%02d/Net_%s_x%02d_*.omni', ...
        lrrtm3_param.home_vols, vz, vy, to_be_net, vx);
    vol_files = dir(path_pattern);
    
    for vol_it = 1:numel(vol_files)

        vol_file_name = vol_files(vol_it).name;
        vol_name_split = textscan(vol_file_name, '%s %s x%d y%d z%d %s %s %s %s %s %s %s %s','delimiter','_'); 

        net_id = vol_name_split{2}{1};
        vx_ = vol_name_split{3}(1);
        vy_ = vol_name_split{4}(1);
        vz_ = vol_name_split{5}(1);
        path = sprintf('%sz%02d/y%02d/%s', lrrtm3_param.home_vols, vz_, vy_, vol_file_name);

        query = sprintf('select id from volumes where net_id=''%s'' and vx=%d and vy=%d and vz=%d',net_id,vx_,vy_,vz_);
        exist_vol_id = mysql(h_sql, query);
        if ~isempty(exist_vol_id)
            fprintf('%s already in table\n',vol_file_name);
            continue;
        end
        query = sprintf(['insert into volumes (dataset_id,net_id,path,vx,vy,vz,status) ' ...
                          'values (%d,''%s'',''%s'',%d,%d,%d,0);'], lrrtm3_param.dataset_id, net_id, path, vx, vy, vz);
        fprintf('%s\n',query);
        rtn = mysql(h_sql, query);
    end
end

mysql(h_sql,'close');
end



