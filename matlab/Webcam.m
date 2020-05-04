pause on

%calculate frames
video   = VideoReader('empty_2.mp4');
video_length = video.Duration
video_framerate = video.FrameRate
video_total_frames = video_length*video_framerate

picture_interval = 2; %in seconds
picture_name = "img";
n_pictures = uint8(floor(video_length/picture_interval));

pause_time = 0.5;

camList = webcamlist;
cam = webcam(1);


resolutions = cam.AvailableResolutions;
disp(resolutions);

in = str2double(input("choose resolution", 's'));

cam.Resolution = resolutions{in};




preview(cam);

%videoFReader   = vision.VideoFileReader('empty_2.mp4');
depVideoPlayer = vision.DeployableVideoPlayer;

depVideoPlayer.Size(true)

depVideoPlayer.Location = [0, -1400];

vidFrame = readFrame(video);

hFig = figure('Name','APP',...
    'Numbertitle','off',...
    'Position', [0 0 1 1],...
    'WindowStyle','modal',...
    'Color',[0.5 0.5 0.5],...
    'Toolbar','none');
img = vidFrame;  
fpos = get(hFig,'Position')
axOffset = (fpos(3:4)-[size(img,2) size(img,1)])/2;
ha = axes('Parent',hFig,'Units','pixels',...
            'Position',[axOffset size(img,2) size(img,1)]);


hFig = imshow(img, 'Parent', ha);

% get the figure and axes handles
 hFig = gcf;
 hAx  = gca;
 % set the figure to full screen
 set(hFig,'units','normalized','outerposition',[0 0 1 1]);
 % set the axes to full screen
 set(hAx,'Unit','normalized','Position',[0 0 1 1]);
 % hide the toolbar
 set(hFig,'menubar','none')
 % to hide the title
 set(hFig,'NumberTitle','off');

%{
myVideo = implay('empty_2.mp4');
myVideo.Parent.Toolbar = 'none';
myControls = myVideo.DataSource.Controls;
%}


disp("Ready to go? y/n")
in = input('', 's');

if (in == "y")
    disp("starting");
else 
    clear cam;
    return;
end

%{
cont = ~isDone(videoFReader);
  while cont
    videoFrame = videoFReader();
    depVideoPlayer(videoFrame);
    cont = ~isDone(videoFReader) && isOpen(depVideoPlayer);
  end
%}


for i = 1:n_pictures
    video.CurrentTime = double(i*picture_interval)
    vidFrame = readFrame(video);
    cla;
    imshow(vidFrame);
    %set(hFig, 'units','normalized','outerposition',[0 0 1 1]);
    %set(hFig,'CData',vidFrame);
    %myControls.CurrentFrame = i*picture_interval*video_framerate;
    img = snapshot(cam);
    imwrite(img,"images/"+picture_name+i+".png");
    %pause(pause_time)
end
clear cam


