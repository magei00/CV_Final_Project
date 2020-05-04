clear all
video = VideoReader('160836_040520_Trim.mp4');
numFrames = video.NumFrames;

images = [];
for i=1:60:numFrames
    temp = read(video, i);
    images = cat(4,images, temp);
end


[corners, boardSize, patternDetected] = detectCheckerboardPoints(images);

% REQUIRED
squareSizeInMM = 224;

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
figure;

j=0;
for i=1:size(images,4)
    if patternDetected(i) == 0
        continue
    end
    j = j+1;
    imshow(images(:,:,:,i)); 
    hold on;
    plot(corners(:,1,j), corners(:,2,j),'go');
    plot(params.ReprojectedPoints(:,1,j),params.ReprojectedPoints(:,2,j),'r+');
    legend('Detected Points','ReprojectedPoints');
    hold off;
end
