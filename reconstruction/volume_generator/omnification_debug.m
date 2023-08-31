jobconfig_path = '/data/research/jwgim/lrrtm3_omnification/NetKslee/cfg.txt';
if exist('jobconfig_path', 'var') < 1
    fprintf('@jobconfig_path needed\n');
    return
end

if ~isdeployed
    addpath('/data/research/jwgim/matlab_code/');
end
   
%config file parsing
jobcfg = parsing_jobconfig(jobconfig_path);

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

%% loop from here
cnt = 0;
tot = 31*22*9;
for vidx_z=1:9
    for vidx_y=1:22
        for vidx_x=1:31
            cnt = cnt +1;
            vidx = [vidx_x vidx_y vidx_z];
            time_ = sprintf('%s', datetime('now'));
            fprintf('\n# %d/%d, cube %d,%d,%d\n',cnt, tot, vidx);

            % change start_cube_idx (based on query result)
            jobcfg{cidx,2} = sprintf('%d,%d,%d', vidx);    

            %chan: cubeidx, start, end (global), cube_size
            %fwd : cubeidx, global st-en, global valid st-en, local valid st-en, cube size
%             [chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table_debug(jobcfg); 
            [chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(jobcfg); 
%             print_table(chan_coordinate_tbl, fwd_coordinate_tbl);
            
            [row,~] = size(chan_coordinate_tbl);
            idx_list = 1:row;
            for ridx = idx_list
                cubeidx = chan_coordinate_tbl{ridx,1};
                %get assembled cube
                [cube, valid] = get_affinity_cube_debug(jobcfg, ridx, chan_coordinate_tbl, fwd_coordinate_tbl);   
%                 [cube, valid] = get_affinity_cube(jobcfg, ridx, chan_coordinate_tbl, fwd_coordinate_tbl);   
                if valid ~= 1
                    fprintf('@can''t find needed cube (%d), pass this job\n', ridx);
                    chan_coordinate_tbl{ridx,5} = 'PASS';
                    print_table(chan_coordinate_tbl, fwd_coordinate_tbl);
                    continue
                end 
            end
%             return
        end
    end
end

%%
function print_table(chan_tbl, fwd_tbl)
    [row, ~] = size(chan_tbl);
    fprintf('[channel coordinate table (#%d)]\n', row);
    fprintf('cube_idx |   start   |   end    |   size\n');
    for ridx=1:row
        fprintf('%d,%d,%d | %d,%d,%d | %d,%d,%d | %d,%d,%d\n', ...
            chan_tbl{ridx,1}, chan_tbl{ridx,2}, chan_tbl{ridx,3}, chan_tbl{ridx,4});
    end
    
    fprintf('\n');
    [row,~] = size(fwd_tbl);
    fprintf('[forward coordinate table (#%d)]\n', row);
    fprintf('cube_idx |  start(valid)  |  end(valid)\n');
    for ridx=1:row
        fprintf('%d,%d,%d | %d,%d,%d | %d,%d,%d\n', ...
            fwd_tbl{ridx,1}, fwd_tbl{ridx,4}, fwd_tbl{ridx,5});
    end
end
