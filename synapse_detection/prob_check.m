% to view AI outputs using omni

addpath /data/research/cjpark147/code/hdf5_ref
jobconfig_path = '/data/research/kaffeuser/lrrtm3_syn_detection/cfg_cleft.txt';

assembly_size = [14592,10240,1024];
write_path = '/data/lrrtm3_wt_syn/assembly/vesicle_prob_check3.h5';
prob_path = '/data/lrrtm3_wt_syn/assembly/assembly_vesicle_prob.h5';

if ~isfile(write_path)
    h5create(write_path,'/main',assembly_size,'Datatype','uint32');
    h5write(write_path,'/main', zeros(assembly_size, 'uint32'));
end

jobcfg = parsing_jobconfig(jobconfig_path);
[chan_tbl, fwd_tbl] = create_coordinate_table(jobcfg);
[row,~] = size(fwd_tbl);

parfor i = 1:row
    stp = fwd_tbl{i,4};
    enp = fwd_tbl{i,5};
    prob = h5read(prob_path, '/main', stp, enp-stp+1);
    segments = uint32(round(prob,3) * 1000);
    h5write(write_path, '/main', segments, stp, enp-stp+1 );
    disp([num2str(i), ' ']);
end




