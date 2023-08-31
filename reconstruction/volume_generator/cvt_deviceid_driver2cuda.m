%must be removed!!!!!!
function id = cvt_deviceid_driver2cuda(host_id, driverid)    
    if host_id == 102
        id = driverid;        
    elseif host_id == 103
        id = driverid;
    elseif host_id == 101
        switch(driverid)   
            case 0
                id = 2;
            case 1
                id = 1;
            case 2
                id = 0;
            case 3
                id = 3;
            case 4
                id = 4;
            case 5
                id = 5;
        end
    end
    