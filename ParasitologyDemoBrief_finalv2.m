%% Automated detection and quantification of Babesiosis infection
% Babesiosis is a malaria-like, tick-borne parasitic disease common in
% parts of the US, and present sporadically throughout the rest of the
% world. Our goal here is to EXPLORE options for developing an automated
% function to DETECT the presence of the Babesia parasite in thin blood
% smears, and to QUANTIFY the portion of RBCs in a sample that are
% infected.
%
% 
%
% Brett Shoelson,PhD; Avi Nehemiah; Louvere Walker-Hannon


%% Credits
% All images used in this demo can be found
% <http://www.cdc.gov/dpdx/babesiosis/gallery.html here>. We gratefully
% acknowledge the CDC's Division of Parasitic Diseases and Malaria (DPDM).
% Images are used by permission.


%% OUR FOCUS
%
% Exploration
% UI usage
% Segmentation
% Pre-processing

%% Clean slate
clear; close all; clc;

%% Babesiosis Images
% Convenient referencing of a collection of images?
% 
%babesiosisDir ='C:\MathWorks DEMOS\Parasitology\BloodSmearImages\babesiosis';
% TO DO: See about using pwd, instead of using a hard coded directory
babesiosisDir='C:\AEG\Demos\Novartis\ParasitologyDemo\BloodSmearImages\babesiosis';
imds = imageDatastore(babesiosisDir,...
    'LabelSource','foldernames');
methods(imds)
imds.countEachLabel
%% Create a display of all Babesiosis images
togglefig('Babesiosis Images')
nImages = numel(imds.Files);
ax = gobjects(nImages,1);
for ii = 1:nImages
    ax(ii) =...
        subplot(floor(sqrt(nImages)),ceil(sqrt(nImages)),ii);
    [~,currName] = fileparts(imds.Files{ii});
	imshow(readimage(imds,ii));
    title([num2str(ii),') ' currName],...
        'interpreter','none','fontsize',7)
end
expandAxes(ax);

%% To develop an algorithm, let's select a "Target Image"
targetImgNum = 4;
togglefig('Babesiosis Images')
[~,imName] = fileparts(imds.Files{targetImgNum});
set(ax,'xcolor','r','ycolor','r',...
    'xtick',[],'ytick',[],'linewidth',2,'visible','off')
set(ax(targetImgNum),'visible','on');

%%
targetImage = readimage(imds,targetImgNum);
%targetImage = getimage(ax(targetImgNum));
togglefig('Target Image')
clf
imshow(targetImage)
title(imName,'interpreter','none','fontsize',12);

%% Segmentation
% When we "segment" an image, we distinguish the regions of interest (ROIs)
% from the non-ROI portion, generally creating a binary mask of what we
% want to qualify, quantify, track, etc. Segmentation is a critical part of
% many image processing problems, and is worth considering in some depth.
% Here, we want to first segement "cell" from "non-cell."
%
% imageSegmenter(targetImage) %-> auto-generates code!
% (Capture as 'segmentImageFcn')
% edit segmentImageFcn
%
togglefig('Cell Mask',true)
cellMask = segmentImageFcn(targetImage);
imshow(cellMask)

 %% Try detecting edges
% doc edge
edges = edge(rgb2gray(targetImage));
togglefig('Edge Mask')
subplot(1,2,1)
imshow(targetImage)
subplot(1,2,2)
imshow(edges);

%% 
% segmentImage(rgb2gray(targetImage)) %Using Brett's app
edges = edge(rgb2gray(targetImage),'LOG',0.001);
togglefig('Edge Mask',1)
imshow(edges);

%% Improving the result
% docsearch('Remove objects from binary image')
edges = bwareaopen(edges,60,8);
togglefig('Edge Mask')
imshow(edges);

%% Combine the edges (logically) with the segmented regions
togglefig('Cell Mask')
tmp = cellMask & ~edges;
tmp = bwareaopen(tmp,100);
imshow(tmp);

%% Improve the edge mask?
% Unfortunately, we haven't yet separated the contiguous cells!
imageMorphology(edges)

%%
morphed1 = imclose(edges, strel('Disk',3,4));
morphed1 = bwmorph(morphed1, 'skel', Inf);
morphed1 = bwmorph(morphed1, 'spur', Inf);
morphed1 = bwareaopen(morphed1,110,8);
togglefig('Edge Mask',true)
imshow(morphed1);

%% Reality check...
togglefig('Babesiosis Images',true)
refreshImages
for ii = 1:nImages
	mask = refinedMask(getimage(ax(ii)));
	showMaskAsOverlay(0.5,mask,'b',[],ax(ii))
	drawnow
end
expandAxes(ax);

%% Let's try to use the "shapes" of the objects of interest...
% Consider treating the RBCs as circles
docsearch('find circles in image')

%% Let's try it programmatically!
grayscale = rgb2gray(targetImage);
circleFinder(grayscale)

%%
detectCircles = @(x) imfindcircles(x,[20 35], ...
    'Sensitivity',0.89, ...
    'EdgeThreshold',0.04, ...
    'Method','TwoStage', ...
    'ObjectPolarity','Dark');
[centers, radii, metric] = detectCircles(grayscale);

togglefig('Target Image',true)
imshow(targetImage)
viscircles(centers,radii,'edgecolor','b')
title(sprintf('%i Cells Detected',numel(radii)),'fontsize',14);

%% Again, we check to see how robust the approach is:
togglefig('Babesiosis Images')
for ii = 1:nImages
    [centers,radii] = detectCircles(rgb2gray(readimage(imds,ii)));
    delete(findall(ax(ii),'type','line'))
    viscircles(ax(ii),centers,radii,'edgecolor','r')
    drawnow
end
expandAxes(ax);

%% Image Variability
% So the cells are reasonably segmented, but the variability in the images
% is thwarting our efforts to find the infections:

imtool([grayscale,rgb2gray(readimage(imds,16))])

%% One last step: Histogram-matching
% doc imhistmatch
tempImage = readimage(imds,16);
matchedImage = imhistmatch(tempImage,targetImage);
togglefig('Exploration',true)
subplot(2,1,1)
imshow(targetImage);title('target')
subplot(2,1,2)
imshowpair(tempImage,matchedImage,'montage');
title('Image 16;                     Image 16, HistMatched');


%% So now...
imtool([grayscale,rgb2gray(matchedImage)])

%%
infectionThreshold = 135;

%% So which cells, and what fraction of cells, are infected?
[centers,radii] = detectCircles(grayscale);
isInfected = false(numel(radii),1);
nCells = numel(isInfected);
%
% % Creating a "mesh" can be useful:
x = 1:size(grayscale,2);
y = 1:size(grayscale,1);
[xx,yy] = meshgrid(x,y);
% xx(1:3,1:3) %#ok<*NOPTS>
% yy(1:3,1:3)
%%
togglefig('Grayscale',true);
imshow(grayscale)
infectionMask = false(size(grayscale));
for ii = 1:numel(radii)
    mask = hypot(xx - centers(ii,1), yy - centers(ii,2)) <= radii(ii);
%     if ii==1
%         togglefig('Exploration',true)
%         imshow(mask)
%         pause
%         togglefig('Grayscale')
%     end
    currentCellImage = grayscale;
    currentCellImage(~mask) = 0;
    infection = ...
        currentCellImage > 0 & currentCellImage < infectionThreshold;
    infectionMask = infectionMask | infection;
    isInfected(ii) = any(infection(:));
    if isInfected(ii)
        showMaskAsOverlay(0.3,mask,'g',[],false);
    end
end
showMaskAsOverlay(0.5,infectionMask,'r',[],false)
title(sprintf('%i of %i (%0.1f%%) Infected',...
    sum(isInfected),numel(isInfected),...
    100*sum(isInfected)/numel(isInfected)),...
    'fontsize',14,'color','r');

%% Is this more generalizable?

% edit testForInfection
togglefig('Babesiosis Images',true)
refreshImages;
drawnow
%
for ii = 1:nImages
    [pctInfection,centers,radii,isInfected,infectionMask] = ...
        testForInfection(getimage(ax(ii)),targetImage,...
        infectionThreshold,detectCircles);
    title(ax(ii),...
        ['Pct Infection: ', num2str(pctInfection,2),...
        ' (' num2str(sum(isInfected)),...
        ' of ' num2str(numel(isInfected)) ')']);
    viscircles(ax(ii),centers,radii,'edgecolor','b')
    % createCirclesMask
    infectedCellsMask = createCirclesMask(targetImage,...
        centers(isInfected,:),...
        radii(isInfected));
    showMaskAsOverlay(0.3,infectedCellsMask,'g',ax(ii),false);
    showMaskAsOverlay(0.5,infectionMask,'r',ax(ii),false);
    drawnow
end
expandAxes(ax);

%% Now we turn our attention to classifying the types of infection
% This is the realm of MACHINE LEARNING/CLASSIFICATION

clear;close all;clc;

%% Can we differentiate types of infections from blood-smear images?
% This time we'll create an imageSet using the |imageSet| function.
imds = imageDatastore(fullfile(pwd,'.\BloodSmearImages'),...
	'IncludeSubfolders',true,'LabelSource','foldernames')  
imds.countEachLabel
%%
%imageSetViewer(imds)
%imageSetViewer2(imds)
%% First we PARTITION the imageSet into training and test sets
rng(1)
[trainingSets, testSets] = splitEachLabel(imds,0.7,'randomized');

%% The we create a visual BAG OF FEATURES to describe the training set:
% DEFAULT INPUTS: (See doc for bagOfFeatures)
rng(1)
if 0
	bag = bagOfFeatures(trainingSets);
	infectiondata = double(encode(bag, trainingSets));
	save('bagAndInfectionData','bag','infectiondata');
else
	load('bagAndInfectionData')
end

%% Visualize Feature Vectors 
togglefig('Encoding',true)
subset = splitEachLabel(trainingSets,1,'randomize');
nClasses = numel(unique(subset.Labels))
for ii = 1:nClasses
	img = readimage(subset,ii);
	featureVector = encode(bag, img);
	subplot(nClasses,2,ii*2-1);
	imshow(img);
	title(char(subset.Labels(ii)))
	subplot(nClasses,2,ii*2);
	bar(featureVector);
	set(gca,'xlim',[0 bag.VocabularySize])
	title('Visual Word Occurrences');
	if ii == nClasses
		xlabel('Visual Word Index');
	end
	if ii == floor(nClasses/2)
		ylabel('Frequency of occurrence');
	end
end
                                                                                                      
%% TRAIN category classifier on the training set
if 0
	classifier = trainImageCategoryClassifier(trainingSets,bag);
	save('classifier','classifier');
else
	load('classifier')
end

%% EVALUATE the classifier on the test-set images:
[confMat,knownLabelIdx,predictedLabelIdx,predictionScore] = ...
	evaluate(classifier,testSets);
avgAccuracy = mean(diag(confMat));
togglefig('Prediction')
imagesc(confMat)
set(gca,'xtick',1:classifier.NumCategories,...
	'ytick',1:classifier.NumCategories)
xlabel('Prediction')
ylabel('True Class')
title(['Confusion Matrix: Average Accuracy: ',num2str(avgAccuracy,2)])
colorbar;drawnow

%% PREDICT:
% Now we can use the classifier to PREDICT class membership for test images!
togglefig('Prediction')
nTestImages = numel(testSets.Files);
ii = randi(nTestImages);
img = readimage(testSets,ii);
[labelIdx, predictionScore] = predict(classifier,img);
bestGuess = classifier.Labels(labelIdx);
actual = char(testSets.Labels(ii));
imshow(img)
t = title(['Best Guess: ',bestGuess{1},'; Actual: ',actual]);
if strcmp(bestGuess{1},actual)
	set(t,'color',[0 0.7 0])
else
	set(t,'color','r')
end
editorwindow

%% We can easily try other classifiers using the Classification Learner app
% Here we recreate the bagOfFeatures from training images, and cast it to a
% table to facilitate working with the classificationLearner app
infectionData = array2table(infectiondata);
infectionData.infectionType = trainingSets.Labels;

%% Train/Test
% Use the new features to train a model and assess its performance against
% the test data

classificationLearner
% after using the data to create a model, this model can be exported
% %-> export trainedClassifier

%%
testInfectionData = double(encode(bag, testSets));
testInfectionData = array2table(testInfectionData,...
	'VariableNames',trainedModel.RequiredVariables);
actualInfectionType = testSets.Labels;

predictedOutcome = trainedModel.predictFcn(testInfectionData);

correctPredictions = (predictedOutcome == actualInfectionType);
validationAccuracy = sum(correctPredictions)/length(predictedOutcome) %#ok

%%
index = (numel(testSets.Files));
for index=1:index
randomTestImage = readimage(testSets,index);
togglefig('Prediction');
imshow(randomTestImage)
thisImageData = double(encode(bag,randomTestImage));
thisImageData = array2table(thisImageData,...
	'VariableNames',trainedModel.RequiredVariables);
bestGuess = trainedModel.predictFcn(thisImageData);
t=title(['Best Guess: ', char(bestGuess), '; (Actual: ', char(testSets.Labels(index)),')']);
if bestGuess==testSets.Labels(index)
	set(t,'color',[0 0.7 0])
else
	set(t,'color','r')
end
pause(1)
end
editorwindow

    %% Not as good as you'd like?
% How can we improve the predictive value?
% 
% * Better images
% * More images!
% * Preprocessing
% * Non-gridded point selection
% * Custom extractor (see: bagOfFeatures)
% * Rethink the classification problem: Reduce the number of classes?
%   (e.g., plasmodium vs non-plasmodium?)

%% Links to auxiliary tools referenced herein
%
% <http://www.mathworks.com/matlabcentral/fileexchange/47956 editorwindow>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/18220 togglefig>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/18291 expandAxes>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/19706 ExploreRGB>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/22108 showMaskAsOverlay>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/48859 Image Segmenter app>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/23697 Image Morphology app>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/34365 Circle Finder app>
%
% <http://www.mathworks.com/matlabcentral/fileexchange/47905 createCirclesMask>
