% mcc -m -I ../ -I ../watershed_new/ -I ../watershed_ref/ -I ../hdf5_ref/ auto_omnivol_generator.m -d ./compiled_version/
function auto_omnivol_generator(job_path, phase, check_flag)
    if ~isdeployed
        check_flag = num2str(check_flag);
        phase = num2str(phase);
    end    
    jobconfig_path = [job_path 'cfg_phase' phase '.txt'];    
    if str2num(check_flag) == 1 %check job_table 
        disp('test flag SET');
        test_phase = 1;
        fwd_jobmanager;        
        return
    end
    clear test_phase;
    omnification_cube;
end

% function auto_omnivol_generator(job_path, phase, check_flag)    %old version
%     if ~isdeployed
%         check_flag = num2str(check_flag);
%         phase = num2str(phase);
%     end
%     
%     jobconfig_path = [job_path 'cfg_phase' phase '.txt'];
%     
%     if str2num(check_flag) == 1 %check job_table 
%         disp('test flag SET');
%         test_phase = 1;
%         fwd_jobmanager;        
%         return;
%     end
%     clear test_phase;
% %     fwd_jobmanager; %fwd 
%     affinity2omni;  %affinity to watershed
%      
% %     %move job_table file to phase directory
% %     mv_src = [job_path '*table*' phase '.txt'];
% %     mv_dst = [job_path 'phase' phase '/'];
% %     syscmd = ['mv ' mv_src ' ' mv_dst];
% %     disp(syscmd);
% %     system(syscmd);
% %    
%     pause(2*60);    %wait for nfs update
%     
%     %watershed to omnivolume
%     [omni_vol_path] = get_cfg(jobcfg, 'omni_create_path');
%     syscmd = [omni_vol_path 'Cfg' phase '_makebatch1.sh'];
%     disp(syscmd);
%     system(syscmd);
%                           
%     pause(1*60);    %wait for nfs update
%     omni_postprocess;  %merge yaml file 
% end