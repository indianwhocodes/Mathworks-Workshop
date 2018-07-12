function editorwindow(mfile,varargin)
% Activate (or open) the Editor Window
%
% Syntax:
% editorwindow
%    Returns focus to the currently-active editor document
%
% editorwindow(myFile)
%    Returns focus to the Editor Window and activates file myFile. (myFile
%    should be a string, in single quotes.)
%
% Brett Shoelson, PhD
% 9/8/2014
%
% See also: commandwindow, commandhistory

% Copyright 2014 The MathWorks, Inc.

pause(0.25); % Flush event queue first
if nargin < 1 || ~ischar(mfile)
	mfile = matlab.desktop.editor.getActiveFilename;
else
	origmfile = mfile;
	mfile = which(mfile);
end
if isempty(mfile)
	matlab.desktop.editor.newDocument;
else
	matlab.desktop.editor.openDocument(mfile);
end
