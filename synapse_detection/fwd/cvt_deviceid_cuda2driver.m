function id = cvt_deviceid_cuda2driver(host_id, cudaid)  
    if host_id == 2
        id = cudaid;
    elseif host_id == 102 
        id = cudaid;
    elseif host_id == 103
        id = cudaid;
    elseif host_id == 104
        id = cudaid;
    elseif host_id == 105
        id = cudaid;
    elseif host_id == 101
        switch(cudaid)  
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
