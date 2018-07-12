if isa(imds,'matlab.io.datastore.ImageDatastore')
	nImages = numel(imds.Files);
else % imageSet
	nImages = imds.Count;
end
ax = gobjects(nImages,1);
for ii = 1:nImages
	ax(ii) = subplot(floor(sqrt(nImages)),ceil(sqrt(nImages)),ii);
    if isa(imds,'matlab.io.datastore.ImageDatastore')
		currName = imds.Files{ii};
	else % imageSet
		currName = imds.ImageLocation{ii};
	end
	imshow(imread(currName))
	[~,currName] = fileparts(currName);%Strip out extensions
	title([num2str(ii),') ' currName],...
		'interpreter','none','fontsize',7);
end
expandAxes(ax)
