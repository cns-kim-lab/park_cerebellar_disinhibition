%parsing job config file and return parsing info as structure
function ret = parsing_jobconfig(cfgfile)
    %line and then colon
   [~, cmdout] = system(['cat ' cfgfile]);
   by_line = strsplit(cmdout, '\n');
   [row,~] = size(by_line.');
   ret = cell(row-1, 2);
   for iter=1:row-1
       line = strsplit(cell2mat(by_line(iter)), ':');
       ret(iter,1) = line(1);
       ret(iter,2) = line(2);
   end
