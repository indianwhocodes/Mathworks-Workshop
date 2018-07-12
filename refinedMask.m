function cellMask = refinedMask(testImage)
% cellMask = refinedMask(testImage)
% 1/16/2015
cellMask = segmentImageFcn(testImage);
cellMask = bwareaopen(cellMask,60);
edges = edge(rgb2gray(testImage),'LOG',0.001);
edges = bwareaopen(edges,60,8);
edges = imclose(edges, strel('Disk',3,4));
edges = bwmorph(edges, 'skeleton', Inf);
edges = bwmorph(edges, 'spur', Inf);
edges = bwpropfilt(edges,'Perimeter',[80 Inf]);
edges = bwareaopen(edges,100,8);
edges = imdilate(edges,strel('Disk',1));
cellMask = cellMask & ~edges;