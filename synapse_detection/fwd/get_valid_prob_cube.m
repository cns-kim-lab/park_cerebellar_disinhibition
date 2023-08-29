function [cube, valid] = get_valid_prob_cube(cfg, ridx, chan_tbl, fwd_tbl)
    cube = zeros(fwd_tbl{ridx,8}, 'single');    
    
    valid = 1;
    %get cfg info
    [path,~] = get_cfg(cfg, 'fwd_result_path');
    [fwd_naming,~] = get_cfg(cfg, 'fwd_input_cube_naming');
    
    fwd_fr = fwd_tbl{ridx,4};
    fwd_to = fwd_tbl{ridx,5};
  
    x = fwd_fr(1);
    while 1
        y = fwd_fr(2);
        while 1
            z = fwd_fr(3);
            while 1     
                fridx = get_fwd_ridx_by_startpoint(fwd_tbl, [x,y,z]);
                if fridx < 1 
                    disp('@match cube not exist');
                    valid = 0;
                    return
                end
                fwd_filename = sprintf(fwd_naming, fwd_tbl{fridx,1});
                fwd_outname = [path fwd_filename '_output.h5']; 
                
                %check existence of file
                if exist(fwd_outname, 'file') < 1
                    disp(['@file not exist (fwd cube id:' num2str(fwd_tbl{fridx,1}) ')']);
                    valid = 0;
                    return
                end
                
                cube = reassemble_prob_cube(cube, fwd_tbl, fridx, fwd_fr, fwd_to, [x,y,z], fwd_outname);
                en = min(fwd_to, fwd_tbl{fridx,5});
                z = en(3)+1;
                if z >= fwd_to(3) 
                    break
                end            
            end %third while
            y = en(2)+1;
            if y >= fwd_to(2)
                break
            end        
        end %second while
        x = en(1)+1;
        if x >= fwd_to(1)
            break
        end    
    end %first while
end

