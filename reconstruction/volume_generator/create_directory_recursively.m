function create_directory_recursively(path)
    path_ = strsplit(path, '/');
    path_ = path_ .';
    
    len = length(path_);
    find_path = '';
    
    for row=1:len
        if isempty(path_{row,1})
            continue
        end
        
        find_path = [find_path '/' path_{row,1}];
        if exist(find_path, 'dir') == 7
            continue
        end
        cmd = ['mkdir ' find_path];
        disp(cmd);
        system(cmd);
        cmd = ['chmod 770 ' find_path];
        disp(cmd);
        system(cmd);
    end
