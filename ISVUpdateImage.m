function ISVUpdateImage(obj,varargin)
% Helper function for imageSetViewer
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
% Copyright The MathWorks, Inc. 2015
allStrings = get(obj,'String');
imgAx = varargin{2};
currImgName = allStrings{get(obj,'Value')};
[currImg,currMap] = imread(currImgName);
if ~isempty(currMap)
	currImg = ind2rgb(currImg,currMap);
end
imshow(currImg,[],'parent',imgAx);
%
currImgInfo = imfinfo(currImgName);
titleString = [currImgName ' (' num2str(currImgInfo(1).Width) 'x' num2str(currImgInfo(1).Height)  ' [' num2str(size(currImgInfo,1)) '-frame, ' num2str(currImgInfo(1).BitDepth) '-bit] image)'];
title(titleString,'fontsize',7,'interpreter','none')
%
expandAxes(imgAx)