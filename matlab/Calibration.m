clear all
video = VideoReader('calibration_video_1920_1080.mp4');
numFrames = video.NumFrames;

images = [];
for i=1:60:numFrames
    temp = read(video, i);
    images = cat(4,images, temp(5:1084,:,:));
end


[corners, boardSize] = detectCheckerboardPoints(images);

% REQUIRED
squareSizeInMM = 29;

worldPoints = generateCheckerboardPoints(boardSize,squareSizeInMM);

%imageSize = [2176 3840];
imageSize = [1080 1920];


params = estimateCameraParameters(corners,worldPoints, ...
                                  'ImageSize',imageSize);
   
figure;
showReprojectionErrors(params);

figure;
showExtrinsics(params);

figure; 
imshow(images(:,:,:,37)); 
hold on;
plot(corners(:,1,37), corners(:,2,37),'go');
plot(params.ReprojectedPoints(:,1,37),params.ReprojectedPoints(:,2,37),'r+');
legend('Detected Points','ReprojectedPoints');
hold off;
