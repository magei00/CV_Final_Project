% closepreview(cam);
% stop(cam);
% flushdata(cam);
clear all;

cam = videoinput('winvideo',2,'YUY2_1920x1080');
triggerconfig(cam, 'manual');

set(cam, 'FramesPerTrigger', 1);
set(cam, 'ReturnedColorspace', 'gray');

cam.FrameGrabInterval = 1;  % distance between captured frames 

timenow = datestr(now,'hhMMss_ddmmyy');
vid = VideoWriter([timenow,], 'MPEG-4');
vid.FrameRate = 30;
vid.Quality = 40;

% f = figure('Name', 'Video Recording Preview');
% uicontrol('String', 'Rec Stop', 'Callback', 'close(gcf)');
% 
% vidRes = cam.VideoResolution;
% nBands = cam.NumberOfBands;
% hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
% preview(cam, hImage);

start(cam);
preview(cam);
% Continue recording until figure gets closed
% uiwait(f);

open(vid);

frames = cell(100,1);

counter = 1;
tic;
%for frame=1:100
while (toc < 130)    
    i = getsnapshot(cam);
    
    %bw = rgb2gray(i);
    
    %f = im2frame(i);
    
    frames(counter, 1) = {i};
    counter = counter + 1;
    %writeVideo(vid, i);
    
end


closepreview(cam);
stop(cam);
flushdata(cam);

for i=1:size(frames,1)
    writeVideo(vid, frames{i,1});
end


close(vid);
