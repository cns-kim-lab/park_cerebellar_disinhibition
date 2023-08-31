function login(username, no_newcell)
    if nargin < 1 || isempty(username)
        fprintf('Login failed, user name required.\n');
        return
    end
    
    %check 
    old_user = account();
    if ~isempty(old_user)
        fprintf('Already logged in with username %s.\n', old_user);
        return
    end
    
    %parsing to lower case
    username = lower(username);    
    if check_user_registered(username) < 1
        fprintf('Login failed, unknown user.\n');
        return
    end
    
    addpaths();
    
    %login
    account(username);
    
    %clean up previeous omni volumes
    cleanup_old_volumes(username);    
    
    % no_newcell : optional parameter (consider only exist cells of the user)
    if nargin == 2
        new_cells = [];
        if no_newcell
            write_log('Don''t create new cells.', 1);
        end
    else
        %make cells and review volume
        new_cells = initiate_cells(username);
    end
    
    %if all cells are old, call pf_reconstruction
    if isempty( new_cells ) 
        pf_reconstruction();
    end
end

%% 
function uidx = check_user_registered(username)   
    valid_users = ["daniel"; "hnseo"; "jwshin"; "jwyun"; "jykim"];
    uidx = find(strcmp(valid_users, username),1);
    if isempty(uidx)
        uidx = 0;
    end
end

%%
function cleanup_old_volumes(username)
    write_log('Clean up previous projects.', 1);
    
    review_root = '/data/lrrtm3_wt_pf_review';    
    
    syscmd = sprintf('rm -rf %s/*%s*.omni*', review_root, username);
    write_log(sprintf('%s', syscmd));
    system(syscmd);
    
    syscmd = sprintf('rm -rf %s/*%s*.h5', review_root, username);
    write_log(sprintf('%s', syscmd));
    system(syscmd);
    
    syscmd = sprintf('rm -rf %s/*%s*.cmd', review_root, username);
    write_log(sprintf('%s', syscmd));
    system(syscmd);
end
