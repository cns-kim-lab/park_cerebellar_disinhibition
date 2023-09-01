%%
function vol = lrrtm3_get_vol_segmentation(path_vol_segmentation, vol_coord_info, dataset)

if ~exist('dataset', 'var')
    dataset = 1;
end
[param, ~] = lrrtm3_get_global_param(dataset);

size_of_chunk = param.size_of_chunk;
size_of_uint32 = param.size_of_uint32;
size_of_chunk_linear = param.size_of_chunk_linear;
% global size_of_chunk size_of_uint32 size_of_chunk_linear

mip_vol_size_in_chunks=ceil(vol_coord_info.mip_vol_size./size_of_chunk);
mip_vol_size=mip_vol_size_in_chunks.*size_of_chunk;
vol=zeros(mip_vol_size,'uint32');

fp=fopen(path_vol_segmentation,'r');

for x=1:mip_vol_size_in_chunks(1)
    for y=1:mip_vol_size_in_chunks(2)
        for z=1:mip_vol_size_in_chunks(3)
            sub=[x y z];
            idx_chunk=sub2ind(mip_vol_size_in_chunks,sub(1),sub(2),sub(3));
            offset=(size_of_uint32*(idx_chunk-1)*size_of_chunk_linear);
            fseek(fp,offset,'bof');
            chunk=reshape(fread(fp,size_of_chunk_linear,'*uint32'),size_of_chunk);
            st=([x y z]-1).*size_of_chunk+1;
            ed=([x y z]).*size_of_chunk;
            vol(st(1):ed(1),st(2):ed(2),st(3):ed(3))=chunk;
        end
    end
end
fclose(fp);

mip_vol_size = vol_coord_info.mip_vol_size;
vol = vol(1:mip_vol_size(1), 1:mip_vol_size(2), 1:mip_vol_size(3));

end
