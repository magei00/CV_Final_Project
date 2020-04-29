clear all
cam = videoinput('winvideo',1,'YUY2_1920x1080');
triggerconfig(cam, 'manual');

set(cam, 'FramesPerTrigger', inf);
set(cam, 'ReturnedColorspace', 'gray');

cam.FrameGrabInterval = 1;  % distance between captured frames 

timenow = datestr(now,'hhMMss_ddmmyy');
vid = VideoWriter([timenow,'.avi'], 'Grayscale AVI');
vid.FrameRate = 30;

% f = figure('Name', 'Video Recording Preview');
% uicontrol('String', 'Rec Stop', 'Callback', 'close(gcf)');
% 
% vidRes = cam.VideoResolution;
% nBands = cam.NumberOfBands;
% hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
% preview(cam, hImage);

start(cam);

% Continue recording until figure gets closed
% uiwait(f);

open(vid);

tic

frames = cell(100,1);
for frame=1:100
    
    i = getsnapshot(cam);
    
    %bw = rgb2gray(i);
    
    %f = im2frame(i);
    
    frames(frame, 1) = {i};
    %writeVideo(vid, i);
    
end
toc

for i=1:100
    writeVideo(vid, frames{i,1});
end


closepreview(cam);
close(vid);
stop(cam);
flushdata(cam);