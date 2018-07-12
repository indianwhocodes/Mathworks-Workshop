function ISVChangePanel(mainPanel,allListboxes,nPerRow,imgAx)
% Helper function for imageSetViewer
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
% Copyright The MathWorks, Inc. 2015
[currentTier,currentTabRank,tabName] = tabPanel(mainPanel);
currListbox = (currentTier-1)*nPerRow+currentTabRank;
ISVUpdateImage(allListboxes(currListbox),[],imgAx);
