function save_watershed(filepath, segu, dend, dendv)
    if exist(filepath, 'file' )
        command = ['rm -rf ' filepath];
        system(command);
    end
    hdf5write(filepath,'/main',uint32(segu),'/dend',uint32(dend),'/dendValues',single(dendv));
    
end