function imgSet = removePathFromImageSet(imgSet,pathToRemove,recurse)
% Helper 'method' for imageSet objects
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
%
% See also: imageSet, appendImageToImageSet, appendPathToImageSet,
% imageSetFromPaths, imageSetViewer, pathsFromImageSet,
% removeImageFromImageSet, subplotMontageFromImageSet

% Copyright 2015 The MathWorks, Inc.
if nargin < 3
	recurse = false;
end
if recurse
	pathToRemove = genpath(pathToRemove);
	pathToRemove = strsplit(pathToRemove,';')';
end
currPaths = pathsFromImageSet(imgSet);
newPaths = setdiff(currPaths,pathToRemove);
%imgSet = imageSetFromPaths(newPaths);