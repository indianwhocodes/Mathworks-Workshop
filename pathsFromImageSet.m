function paths = pathsFromImageSet(imgSet)
% Helper 'method' for imageSet objects
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
%
% See also: imageSet, appendImageToImageSet, appendPathToImageSet,
% imageSetFromPaths, imageSetViewer, removeImageFromImageSet,
% removePathFromImageSet, subplotMontageFromImageSet

% Copyright 2015 The MathWorks, Inc.
allIms = [imgSet.ImageLocation]';
if isempty(allIms)
	paths = [];
else
	fcn = @(x) fileparts(x);
	paths = cellfun(fcn,allIms,'UniformOutput',false);
	paths = unique(paths,'stable');
end