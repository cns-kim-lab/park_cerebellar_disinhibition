%%
% % % 06.18 - description
% 'silent or var' = no print
% 'partition' = reconstruction have axon and dendrite


%% 
function cellID=lrrtm3_find_cell_recon_at_coord(mesh_path,coord,opt,dataset)

addpath /data/lrrtm3_wt_code/matlab/mysql/
addpath /data/research/jeson/matlab_code/lrrtm3_code/
% addpath /data/research/jk/e2198/bin/helper

if ~exist('dataset', 'var')
    dataset = 1;
end
[param,~] = lrrtm3_get_global_param(dataset);

postfix=param.segmentation_path;
scaling_factor = param.scaling_factor;
volume_size = param.size_of_data;
sizeChunkLinear=param.size_of_chunk_linear;
sizeofUint32=param.size_of_uint32;

% postfix='.files/segmentations/segmentation1/0/volume.uint32_t.raw';
% scaling_factor = [1 1 4];
% volume_size = [14592 10240 1024];
% sizeChunkLinear=prod(sizeChunk);
% sizeofUint32=4;

% % % % % 06.21 - read yaml file and parse data
[mipLevel, chunkDim] = read_yaml_file([mesh_path '.files/projectMetadata.yaml'], scaling_factor);
sizeChunk=[chunkDim chunkDim chunkDim];
mipFactor=2^mipLevel;

coord0=coord;
coord=floor( (coord0./scaling_factor)/mipFactor);

% sizeMeshOmniChunks0=[37 164 101];
sizeMeshOmniChunks0=ceil(volume_size./sizeChunk);
sizeMeshOmniPixels0=sizeMeshOmniChunks0.*sizeChunk;
sizeMeshOmniChunks=ceil(ceil(sizeMeshOmniPixels0/mipFactor)./sizeChunk);

subChunk=floor((coord-1)./sizeChunk)+1;
indChunk=sub2ind(sizeMeshOmniChunks,subChunk(1),subChunk(2),subChunk(3));
subInChunk=coord-(subChunk-1).*sizeChunk;


% 0618 - read raw files
try
% % % % % %     06.25 - calculate offset
    offset = subInChunk;
    offset_prime = sub2ind(sizeChunk,offset(1),offset(2),offset(3))-1;

    f=fopen([mesh_path postfix],'r');
    fileoff_prime=((sizeofUint32*(indChunk-1)*sizeChunkLinear)) + (4*offset_prime);
    fseek(f,fileoff_prime,'bof');
    
    omni_id = fread(f, 1, '*uint32');
    
    fclose(f);
    
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %     

catch
    error('stat - please check your mesh_path');
end


% % % % %  06.25 - test code
% fprintf('\nomniID_prime: %d\n', omni_id);

% % % % % 06.26 - test code
% subChunk = [1 2 1];
% indChunk=sub2ind(sizeMeshOmniChunks,subChunk(1),subChunk(2),subChunk(3));
% coord = [1 131 1];

 
% % % % % % 06.25 - original code
% try
%     subInChunk=coord-(subChunk-1).*sizeChunk;
%     f=fopen([mesh_path postfix],'r');
%     fileoff=(sizeofUint32*(indChunk-1)*sizeChunkLinear);    
%     fseek(f,fileoff,'bof');
%     chunk=reshape(fread(f,sizeChunkLinear,'*uint32'),sizeChunk);    
%     fclose(f);
% catch
%     error('stat - please check your mesh_path');
% end
% 
% omni_id=chunk(subInChunk(1),subInChunk(2),subInChunk(3));
% 
% fprintf('omniID_original: %d\n\n', omni_id);


% % % 06.18 - temporary code
if exist('opt') && strcmp(opt, 'partition') 
    if rem(omni_id, 10)
        omni_id = omni_id - 1;
    end
    omni_id = omni_id / 10;
end

rtn = find_cellID_inDB(omni_id);
cellID = rtn.cellID;

if ~exist('opt') || (~(strcmp(opt, 'silent') || strcmp(opt, 'var')))
    fprintf('omni id: %d\tcell id: %d\n',omni_id, cellID);
end

end

function [mip_level, chunkDim]  = read_yaml_file(yaml_path, scaling_factor)

filetext = fileread(yaml_path);

% % % % % 06.21 - parsing & return mip_level, chunkDim
expr = '[^\n]*dataResolution[^\n]*';
dataResolution = regexp(filetext, expr, 'match');

expr = '[^\n]*chunkDim:[^\n]*';
chunkDim = regexp(filetext, expr, 'match');

chunkDim_str = strtrim(chunkDim{1});
chunkDim = sscanf(chunkDim_str, 'chunkDim: %d');

resolution_str = strtrim(dataResolution{1});
resolution = sscanf(resolution_str, 'dataResolution: [%d, %d, %d]');

calc = resolution ./ scaling_factor';
mip_level = calc(1) / 2;

end


function rtn = find_cellID_inDB(param_omniID)

global h_sql;
try
   h_sql = mysql('open', 'kimserver106', 'omnidev','rhdxhd!Q2W');
catch
   fprintf('stat = already db open, close and reopen\n'); 
   mysql(h_sql, 'close');
   h_sql = mysql('open', 'kimserver106', 'omnidev','rhdxhd!Q2W');
end

fprintf('reading database ...\n');

rtn = mysql(h_sql, 'use omni');
if rtn <= 0
    fprintf('db connection fail\n');
    return;
end

omni_id_string = sprintf('%d,', param_omniID);
omni_id_string = sprintf('(%s)', omni_id_string(1:end-1));

% % % 06.19 - please check reconstruction file, if reconstruction have
% axon and dendrite, attach 'partition' option and execute the function.

% % % % % % 07.03 - 'cell_metadata table'
query = ['select c.id from cells c inner join cell_metadata cm on c.meta_id = cm.id where c.omni_id = ', omni_id_string];

% query = ['select c.id from cells c ' ...
%         'where c.omni_id = ', omni_id_string];

[out_cellID] = mysql(h_sql, query);

rtn = [];
rtn.cellID = out_cellID;

mysql(h_sql, 'close');
end