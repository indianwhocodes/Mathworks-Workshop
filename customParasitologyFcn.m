function [features, featureMetrics] = customParasitologyFcn(I)
persistent targetImage

matchHistograms = true; %Low-cost way to improve performance
% Histogram matching may help!
if isempty(targetImage) && matchHistograms
	targetImage = rgb2gray(imread('BabesiosisRGB.png'));
end
extractorMethod = 'SURF'; %#ok Auto;BRISK;FREAK;SURF;BLOCK
%
% Convert I to grayscale if required.
[height,width,numChannels] = size(I);
if numChannels > 1
    grayImage = rgb2gray(I);
else
    grayImage = I;
end

if matchHistograms
	grayImage = imhistmatch(grayImage,targetImage);
end
gridStep = 8;
gridX = 1:gridStep:width;
gridY = 1:gridStep:height;
[x,y] = meshgrid(gridX, gridY);
gridLocations = [x(:) y(:)];

[features, scenePoints] = extractFeatures(grayImage,gridLocations,...
	'Method',extractorMethod,...
	'SURFSize',64,...
	'Upright',true);
%
try
	features = double(features);
catch
	features = double(features.Features);
end
featureMetrics = var(features,[],2);

