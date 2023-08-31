function EMtoSeg(jobconfig_path, check_flag)
    if ~isdeployed
        check_flag = num2str(check_flag);
    end
        
    disp(['test_flag=' check_flag]);
    if str2num(check_flag) == 1  %check job_table
        test_phase = 1;
        fwd_jobmanager;
        return
    end
    clear test_phase;
    fwd_jobmanager;
    affinity2omni;
end
