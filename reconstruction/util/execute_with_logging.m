function output = execute_with_logging(log_path, pname, cmd)
    [year,month,day] = ymd(datetime());
    fname = sprintf('%scellupdates_log_%04d_%02d_%02d', log_path, year, month, day);
    fid = fopen(fname, 'a');    
    fprintf(fid, '[%s] %s\n', upper(pname), datetime());
    [~,output] = system(cmd);
    fprintf(fid, '%s\n', output);       
    fclose(fid);
end