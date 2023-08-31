function [chan_coordinate_tbl, fwd_coordinate_tbl] = create_coordinate_table(cfg)
    %get config
    [ncube_chan, valid] = get_cfg(cfg, 'number_of_output_cube');
    [input_tile,~] = get_cfg(cfg, 'input_tile');
    [~,dims,~] = get_hdf5_size(input_tile, '/main');
    [cube_size, ~] = get_cfg(cfg, 'size_of_output_cube');
    [overlap,~] = get_cfg(cfg, 'channel_cube_overlap_pixel');
    [fov, ~] = get_cfg(cfg, 'fwd_net_fov');
    
    cube_size = str2num(cube_size);
    overlap = str2num(overlap);
    fov = str2num(fov);
    fovhalf = (fov-1)/2 +1;
    
    if valid ~= 1   %compute number of output cube
        ncube_chan = compute_number_of_output_cube(cfg, 'channel');
    else
        ncube_chan = str2num(ncube_chan);
    end
    if prod(ncube_chan(:)) < 1
        disp('invalid: number of chann output cube');
        return
    end

    %cubeidx, start, end (global), cube_size, sts
    chan_coordinate_tbl = cell(prod(ncube_chan(:)), 5);  
    start_cubeidx = get_start_cube_idx(cfg, 'channel', '', '');
    last_cubeidx = start_cubeidx +ncube_chan -1;
    ridx = 1;    
    for z=start_cubeidx(3):last_cubeidx(3)
        for y=start_cubeidx(2):last_cubeidx(2)
            for x=start_cubeidx(1):last_cubeidx(1)
                cubeidx = [x,y,z];
                chan_coordinate_tbl{ridx,1} = cubeidx;
                [chan_coordinate_tbl{ridx,2}, chan_coordinate_tbl{ridx,3}] = ...
                    get_start_end_point_of_chan(cubeidx, start_cubeidx, cube_size, overlap, dims);
                chan_coordinate_tbl{ridx,4} = chan_coordinate_tbl{ridx,3} -chan_coordinate_tbl{ridx,2} +1;
                chan_coordinate_tbl{ridx,5} = 'READY';
                ridx = ridx +1;
            end
        end
    end
    
    chan_start = chan_coordinate_tbl{1,2};
    chan_end = chan_coordinate_tbl{1,3};
    [row,~] = size(chan_coordinate_tbl);
    for iter=2:row
        chan_start = min(chan_start, chan_coordinate_tbl{iter,2});
        chan_end = max(chan_end, chan_coordinate_tbl{iter,3});
    end
    
    start_cubeidx = get_start_cube_idx(cfg, 'forward', [], max([1,1,1], chan_start-1));
    fwd_start = get_start_end_point_of_fwd(start_cubeidx, start_cubeidx, cube_size, fov, dims);
    ncube_fwd = compute_number_of_fwd_output_cube(cfg, fwd_start, chan_end);
    %cubeidx, global st-en, global valid st-en, local valid st-en, cube size    
    fwd_coordinate_tbl = cell(prod(ncube_fwd(:)), 8);   
    last_cubeidx = start_cubeidx +double(ncube_fwd) -1;
    ridx = 1;    
    for z=start_cubeidx(3):last_cubeidx(3)
        for y=start_cubeidx(2):last_cubeidx(2)
            for x=start_cubeidx(1):last_cubeidx(1)
                cubeidx = [x,y,z];
                [global_st, global_en] = get_start_end_point_of_fwd(cubeidx, start_cubeidx, cube_size, fov, dims);
                global_val_st = global_st +fovhalf;   %right equation
                global_val_en = global_en -fovhalf;
                valid_cube_size = cube_size;
                replace = int32( global_st <= fovhalf );
                global_val_st(replace>0) = global_st(replace>0);
                replace = int32( global_en >= dims );
                if nnz(replace) > 0
                    global_val_en(replace>0) = dims(replace>0);
                    valid_cube_size = global_val_en -global_val_st +1;
                end
                local_val_st = fovhalf +1;
                replace = int32( global_st <= fovhalf );
                local_val_st(replace>0) = 1;
                local_val_en = local_val_st +valid_cube_size -1;
                
                fwd_coordinate_tbl{ridx,1} = cubeidx;
                fwd_coordinate_tbl{ridx,2} = global_st;
                fwd_coordinate_tbl{ridx,3} = global_en;
                fwd_coordinate_tbl{ridx,4} = global_val_st;
                fwd_coordinate_tbl{ridx,5} = global_val_en;
                fwd_coordinate_tbl{ridx,6} = local_val_st;
                fwd_coordinate_tbl{ridx,7} = local_val_en;
                fwd_coordinate_tbl{ridx,8} = valid_cube_size;
                ridx = ridx +1;
            end
        end
    end
[chan_coordinate_tbl, fwd_coordinate_tbl] = summary_coordinate_table(cfg, chan_coordinate_tbl, fwd_coordinate_tbl);    
end

%% remove extra row
function [chan_tbl, fwd_tbl] = summary_coordinate_table(cfg, chan_tbl, fwd_tbl)
    %check chan_tbl redundant
    [num_cube,~] = get_cfg(cfg, 'number_of_output_cube');
    num_cube = str2num(num_cube);
    
    [crow,~] = size(chan_tbl);
    if crow ~= prod(num_cube)
        fprintf('@number of channel output cube mismatch (cfg %d, chan_tbl %d)\n', ...
            prod(num_cube), crow);        
    end
    
    %check fwd_tbl redundant
    [frow,~] = size(fwd_tbl);
    list = [];
    for fridx=1:frow
        flag = 0;
        for cridx=1:crow            
            stp_flag = (chan_tbl{cridx,2} >= fwd_tbl{fridx,4}) & (chan_tbl{cridx,2} <= fwd_tbl{fridx,5});            
            edp_flag = (chan_tbl{cridx,3} >= fwd_tbl{fridx,4}) & (chan_tbl{cridx,3} <= fwd_tbl{fridx,5});
            
            if prod(stp_flag | edp_flag) > 0
                flag = 1;
                break
            end     
        end
        if flag == 1
            continue
        end
        list = [list fridx];
    end    
    
    if isempty(list)
        return
    end
    
    fwd_tbl(list,:) = [];
end
