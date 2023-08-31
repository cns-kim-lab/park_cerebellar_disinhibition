%standardize (any dimension)
%equation = (x-mean)/stddev
function ret = standardize_data(data)
    mean_val = mean(single(data(:)));
    stddev_val = std(single(data(:)));
    
    ret = (single(data) - mean_val) / stddev_val;