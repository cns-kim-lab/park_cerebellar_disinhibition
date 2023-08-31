function addpaths()
    %common
    addpath /data/lrrtm3_wt_code/matlab/
    addpath /data/lrrtm3_wt_code/matlab/mysql/
    addpath /data/lrrtm3_wt_code/matlab/hdf5/
    addpath /data/research/jwgim/matlab_code/auto_cube_generate/
    addpath /data/research/jwgim/matlab_code/hdf5_ref/
    
%    %for deploy version
%    addpath /data/lrrtm3_wt_code/matlab/pf_reconstruction/
%    addpath /data/lrrtm3_wt_code/matlab/pf_reconstruction/spawn4pf/    
    
     %for test version
     addpath /data/research/jwgim/matlab_code/pf_reconstruction/deploy/
     addpath /data/research/jwgim/matlab_code/pf_reconstruction/deploy/spawn4pf/
     fprintf('TEST VERSION\n');    
end
