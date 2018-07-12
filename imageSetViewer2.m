function [imgSet,imageViewer] = imageSetViewer2(imgSet,varargin)
% Explore imageSet images in UI; optionally, create the imageSet.
%
% SYNTAX:
% [imgSet,imageViewer] = imageSetViewer(imgSet)
% [...] = imageSetViewer(pathToImages,recurse)
% [...] = imageSetViewer(pathToImages,recurse,deletionControls)
%
% INPUTS
% imgSet:  An imageSet object.
% pathToImages: Alternatively, provide a top-level path to a directory of
%           images. If a directory is provided, an imageSet object will be
%           created and returned.
% recurse: If a directory is provided for imgSet, this T/F flag indicates
%          whether the auto-generated imageSet object should be recursive.
%          If an imgSet object is provided, this flag is ignored.
%          (Default = true).
%
% OUTPUTS
% imgSet:   An imageSet object. (See doc for imageSet)
% imageViewer: Handle to the imageViewer figure.
%
% EXAMPLES:
%
% % Example 1: (Input is an imageSet object)
% imgFolder = fullfile(matlabroot, 'toolbox','vision','visiondata','imageSets');
% imgSets = imageSet(imgFolder,'recursive');
% imageSetViewer(imgSets)
%
% % Example 2: (Input is a directory; search is recursive)
% imgFolder = fullfile(matlabroot, 'toolbox','vision','visiondata','imageSets');
% imgSet = imageSetViewer(imgFolder)
%
% % Example 3: (Input is a directory; search is recursive)
% imgFolder = fullfile(toolboxdir('images'));
% imgSet = imageSetViewer(imgFolder,true)

% Comments, suggestions welcome!
%
% See also: imageSet, appendImageToImageSet, appendPathToImageSet,
% imageSetFromPaths, imageSetViewer, pathsFromImageSet,
% removeImageFromImageSet, removePathFromImageSet,
% subplotMontageFromImageSet, tabPanel

% Copyright 2015 The MathWorks, Inc.


% Written by Brett Shoelson, PhD
% brett.shoelson@mathworks.com
% 2/14/2015
%
% Copyright The MathWorks, Inc. 2015
% 
% Modifications:
% 3/6/15: Provides for ability to right-click name of selected image to
%    copy to clipboard. Indicates same in title of figure.
% 3/25/15: Incorporated expandAxes, primarily to facilitate export of
%    images to base workspace.
% 5/7/2015: New example to show IPT images.
% 6/29/2015: Modified titlestring to show image size and bit-depth; also
%    fixed display of single images (using [] in imshow). 

if isa(imgSet,'char')
	if nargin > 1
		recurse = varargin{1};
	else
		recurse = true;
	end
	if recurse
		imgSet = imageSet(imgSet,'recursive');
	else
		imgSet = imageSet(imgSet);
	end
end
if sum([imgSet.countEachLabel.Count])==0
	disp('There are no images to view in this image set.');
	return
end
if nargin > 2
	deletionControls = varargin{2};
else
	deletionControls = false;
end
nPerRow = 5;
nPerRow = min(numel(imgSet),nPerRow);
%
imageViewer = figure('windowstyle','normal',...
	'name','imageSet Viewer  (RIGHT-CLICK name in image list to copy name of selected image to clipboard; Click on IMAGE to expand/export it.)',...
	'units','normalized',...
	'position',[0.005 0.1 0.99 0.775]);
tabExtent = 0.5;gap = 0.05;
imgSetPanel = uipanel(imageViewer,...
	'units','normalized',...
	'position',[0 0 tabExtent 1]);
imgAx = axes('parent',imageViewer,...
	'units','normalized',...
	'position',[tabExtent+gap gap (1-tabExtent-2*gap) (1-2*gap)]);
updateViewer
set(imageViewer, 'Handlevisibility', 'callback');
if nargout < 2
	clear imageViewer
end
if nargout < 1
	clear imgSet
end

	function copyStringToClipboard(obj,varargin)
		strings = get(obj,'string');
		val = get(obj,'value');
		currString = strings{val};
		clipboard('copy', currString)
	end %copyStringToClipboard

	function deletePathFromImageSetViewer(obj,varargin)
		pathToDelete = get(obj,'userdata');
		imgSet = removePathFromImageSet(imgSet,pathToDelete,false);
		updateViewer
	end %deletePathFromImageSetViewer

	function updateViewer
		scrnsz = get(groot,'screensize');
		scrnsz = scrnsz(3);
		% @scrnsz==640,fontsz = 9; @scrnsz = 1680, fontsz = 7
		fontsz = round(-2/(1680-640)*scrnsz+9);
		tabPanelOpts.fontsize = fontsz;
		delete(allchild(imgSetPanel))
		tabLabels = createTabLabels(imgSet,nPerRow);
		tabPaths = pathsFromImageSet(imgSet);
		[mainTabHandle,tabCardHandles,tabHandles] = ...
			tabPanel(imgSetPanel,tabLabels,...
			'TabHeight',30,...
			'Colors',parula(numel(imgSet)),...
			'highlightColor',[1 0 1],...
			'TabCardPVs',{'bordertype','etchedin','title',''},...
			'TabLabelPVs',tabPanelOpts);
		allTabHandles = cell2mat(tabHandles(:));
		allListboxes = gobjects(numel(imgSet),1);
		count = 1;
		for ii = 1:numel(tabCardHandles)
			currHandles = tabCardHandles{ii};
			for jj = 1:numel(currHandles)
				allListboxes(count) = uicontrol(currHandles(jj),...
					'style','listbox',...
					'units','normalized',...
					'position',[0 0 1 1],...
					'string',[imgSet(count).ImageLocation],...
					'callback',{@ISVUpdateImage,imgAx},...
					'buttondownfcn',@copyStringToClipboard);
				count = count+1;
			end
		end
		ISVChangePanelFcnhandle = @(varargin) ISVChangePanel(mainTabHandle,allListboxes,nPerRow,imgAx);
		for ii = 1:numel(allTabHandles)
			iptaddcallback(allTabHandles(ii),'callback',ISVChangePanelFcnhandle);
		end
		currImgName = imgSet(1).ImageLocation{1};
		[currImg,currMap] = imread(currImgName);
		if ~isempty(currMap)
			currImg = ind2rgb(currImg,currMap);
		end
		currImgInfo = imfinfo(currImgName);
		imshow(currImg,[],'parent',imgAx);
		titleString = [currImgName ' (' num2str(currImgInfo(1).Width) 'x' num2str(currImgInfo(1).Height)  ' [' num2str(size(currImgInfo,1)) '-frame, ' num2str(currImgInfo(1).BitDepth) '-bit] image)'];
		title(titleString,'fontsize',7,'interpreter','none')
		expandAxes(imgAx)
		if deletionControls
		delButtons = gobjects(numel(tabHandles),1);
		for ii = 1:numel(allTabHandles)
			cp = get(allTabHandles(ii),'position');
			parent = get(allTabHandles(ii),'parent');
			set(allTabHandles(ii),'position',cp+[0.02 0 -0.02 0]);
			delButtons(ii) = uicontrol(parent,...
				'units','normalized',...
				'style','pushbutton',...
				'string','X',...
				'BackgroundColor','r',...
				'position',[cp(1) cp(2) 0.02 cp(4)],...
				'userdata',tabPaths{ii},...
				'callback',@deletePathFromImageSetViewer);
		end
		end
	end %updateViewer
end