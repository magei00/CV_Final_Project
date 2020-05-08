clear all
video = VideoReader('unityVid_1920_1080.mp4');
numFrames = video.NumFrames;

images = [];
for i=1:60:numFrames
    temp = read(video, i);
    images = cat(4,images, temp);
end


[corners, boardSize, patternDetected] = detectCheckerboardPoints(images);

global numOfImages
numOfImages = size(corners,3);

figure;
for i=1:numOfImages
    hold on;
    scatter(corners(:,1,i),corners(:,2,i), 50)
end

% REQUIRED
squareSizeInMM = 25;

worldPoints = generateCheckerboardPoints(boardSize,squareSizeInMM);

%imageSize = [2176 3840];
imageSize = [1080 1920];


params = estimateCameraParameters(corners,worldPoints, ...
                                  'ImageSize',imageSize, ...
                                  'EstimateSkew', true,...
                                  'NumRadialDistortionCoefficients', 3);
   
figure;
showReprojectionErrors(params);

figure;
showExtrinsics(params);
%figure;
% 
% j=0;
% for i=1:size(images,4)
%     figure
%     if patternDetected(i) == 0
%         continue
%     end
%     j = j+1;
%     imshow(images(:,:,:,i)); 
%     hold on;
%     plot(corners(:,1,j), corners(:,2,j),'go');
%     plot(params.ReprojectedPoints(:,1,j),params.ReprojectedPoints(:,2,j),'r+');
%     legend('Detected Points','ReprojectedPoints');
%     hold off;
% end
