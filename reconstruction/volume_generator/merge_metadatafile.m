function merge_metadatafile(chan_metafile, seg_metafile, new_metafile)
    seg_fid = fopen(seg_metafile, 'r');
    chan_fid = fopen(chan_metafile, 'r');
    new_fid = fopen(new_metafile, 'w');
    str_channel_start = '  Channels:';
    str_segmentation_start = '  Segmentations:';

    chan_file_write = 0;
    while ~feof(seg_fid)
        seg_line = fgetl(seg_fid);
        if strcmpi(seg_line, str_channel_start) %find channels info 
            while ~feof(chan_fid)
                chan_line = fgetl(chan_fid);
                if strcmpi(chan_line, str_segmentation_start)
                    break
                end
                if strcmpi(chan_line, str_channel_start) 
                    chan_file_write = 1;                
                end            
                if chan_file_write == 1
                    fprintf(new_fid, '%s\n', chan_line);
                end            
            end        
        elseif strcmpi(seg_line, str_segmentation_start)    %find segmentation info
            chan_file_write = 0;
        end
        if chan_file_write == 1
            continue
        end
        fprintf(new_fid, '%s\n', seg_line);
    end

    fclose(seg_fid);
    fclose(chan_fid);
    fclose(new_fid);
        