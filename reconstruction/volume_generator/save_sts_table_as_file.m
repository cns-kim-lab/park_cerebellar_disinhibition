function save_sts_table_as_file(filename, table)
    fid = fopen(filename, 'w'); %overwirte
    [row, ~] = size(table);
    format = 'node %s GPU %2d jobid %5d %5d %5d jidx %3d sts %s startTime %s\n';
    for iter=1:row
        fprintf(fid, format, table{iter,:});
    end
    fclose(fid);