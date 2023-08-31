function save_joblist_as_file(filename, format, cellarray)
    fid = fopen(filename, 'w'); %overwirte
    [row, ~] = size(cellarray);
    for iter=1:row
        fprintf(fid, format, cellarray{iter,:});
    end
    fclose(fid);
