function tabLabels = createTabLabels(cellstrIn,nPerRow)
% Helper function for imageSetViewer
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
% Copyright The MathWorks, Inc. 2015
if isa(cellstrIn,'imageSet')
	cellstrIn = {cellstrIn.Description};
end
nLabels = numel(cellstrIn);
nFullRows = floor(nLabels/nPerRow);
nRows = ceil(nLabels/nPerRow);
tabLabels = cell(1,nRows);
inds = reshape(1:nPerRow*nFullRows,nPerRow,[])';
leftovers = numel(cellstrIn(numel(inds)+1:end));
for ii = 1:nFullRows
	tabLabels{ii} = cellstrIn(inds(ii,:));
end
if leftovers ~= 0
	tabLabels{end} = cellstrIn(numel(inds)+1:end);
end
if numel(tabLabels)==1
	tabLabels = tabLabels{1};
end