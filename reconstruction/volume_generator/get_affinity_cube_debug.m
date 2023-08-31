function [cube, valid] = get_affinity_cube_debug(cfg, ridx, chan_tbl, fwd_tbl)
    cube = zeros([chan_tbl{ridx,4} 3], 'single');    
    
    valid = 1;
    %get cfg info
    [path,~] = get_cfg(cfg, 'fwd_result_path');
    [fwd_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    
    chan_fr = chan_tbl{ridx,2};
    chan_to = chan_tbl{ridx,3};
  
    x = chan_fr(1);
    while 1
        y = chan_fr(2);
        while 1
            z = chan_fr(3);
            while 1     
                fridx = get_fwd_ridx_by_startpoint(fwd_tbl, [x,y,z]);
                if fridx < 1 
                    disp('@match cube not exist');
                    valid = 0;
                    return
                end
                fwd_filename = sprintf(fwd_naming, fwd_tbl{fridx,1});
%                 fwd_outname = [path fwd_filename '_output.h5']; %old
                fwd_outname = [path fwd_filename '_affinity.h5']; %new
                
                %check existence of affinity file
                if exist(fwd_outname, 'file') < 1
                    disp(['@affinity file not exist (fwd cube id:' num2str(fwd_tbl{fridx,1}) ')']);
                    valid = 0;
                    return
                end
                
                [cube, valid_] = reassemble_cube_debug(cube, fwd_tbl, fridx, chan_fr, chan_to, [x,y,z], fwd_outname);
                if valid_ ~= 1
                    fprintf('@reassemble will be failed, startp=%d,%d,%d\n', [x y z]);
                    valid = 0;
                    return
                end
                cube = reassemble_cube(cube, fwd_tbl, fridx, chan_fr, chan_to, [x,y,z], fwd_outname);
                en = min(chan_to, fwd_tbl{fridx,5});
                z = en(3)+1;
                if z >= chan_to(3) 
                    break
                end            
            end %third while
            y = en(2)+1;
            if y >= chan_to(2)
                break
            end        
        end %second while
        x = en(1)+1;
        if x >= chan_to(1)
            break
        end    
    end %first while
  
