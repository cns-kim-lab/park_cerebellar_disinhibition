
spath = '/data/lrrtm3_wt_syn/segment_mip2_all_cells_200313.h5';
wpath = '/data/lrrtm3_wt_syn/segment_mip3_all_cells_200313.h5';

volsize = [14592, 10240, 1024]/4;
subvol_size = [1024, 1024, 256];
chunksize = [128, 128, 32];
minp = [1,1,1];
last_cubeidx = [4,3,1];
ds_rate = 2;
ds_rate_z = 1;
write_vol_size = [1824, 1280, 256];
% subvol size should be divisble by ds_rate


h5create(wpath, '/main', write_vol_size, 'Datatype','uint32', 'ChunkSize', chunksize);

for z = 1:last_cubeidx(3)
    for y = 1:last_cubeidx(2)
        for x = 1:last_cubeidx(1)
            
            cubeidx = [x,y,z];
            stp = max(minp, subvol_size .* (cubeidx - 1) + [1,1,1]);
            enp = min(volsize, subvol_size .* cubeidx);
            num_elem = enp - stp + 1;
            subvol = h5read(spath, '/main', stp, num_elem);
            
            stp_new = ceil( [stp(1:2) / ds_rate,  stp(3) / ds_rate_z]); 
            enp_new = ceil( [enp(1:2) / ds_rate,  enp(3) / ds_rate_z]);
            num_elem_new = enp_new - stp_new + 1;
            
            h5write(wpath, '/main', subvol(1:ds_rate:end,1:ds_rate:end,1:ds_rate_z:end), stp_new, num_elem_new);            
            
            fprintf('%d, %d, %d\n', x,y,z);
        end
    end
end