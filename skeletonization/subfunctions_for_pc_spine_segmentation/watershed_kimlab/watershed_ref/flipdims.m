function fx = flipdims(x, dims)

if ~exist('dims','var') | isempty(dims),
  dims = 1:ndims(x);
end

fx = x;
for dim = dims,
  fx = flipdim(fx,dim);
end
