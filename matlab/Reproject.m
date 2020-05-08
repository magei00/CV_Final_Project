global intrinsics
global rotationMatrices
global translationVectors
global worldP
global cornerPoints
global numOfImages
cornerPoints = corners;

temp = zeros(size(worldPoints,1),1);

worldP = [worldPoints temp];
intrinsics = params.Intrinsics;
rotationMatrices = params.RotationMatrices;
translationVectors = params.TranslationVectors;

newRotations = zeros(3,numOfImages);
newTranslations = zeros(numOfImages,3);

for i=1:numOfImages
    newRotations(:,i) = rotm2eul(rotationMatrices(:,:,i));
end

plotFcns = {'optimplotfunccount', 'optimplotfval', 'optimplotstepsize'};
options = optimoptions('fminunc', 'Algorithm', 'quasi-newton',...
    'PlotFcns', plotFcns, 'MaxIterations', 2000, 'MaxFunctionEvaluations', 1e10,...
    'UseParallel', false);
[x, fval, exitflg, output] = fminunc(@fun, [intrinsics.FocalLength ,...
    intrinsics.PrincipalPoint,...
    intrinsics.Skew,...
    newRotations(:)',...
    reshape(translationVectors',1,[])], options);

f1 = x(1);
f2 = x(2);
ppx = x(3);
ppy = x(4);
skew = x(5);
outputRotations = x(6:6+3*numOfImages-1);
outputTranslations = x(6+3*numOfImages:end);


% Run this part to plot
% the optimized errors
% -----------------------
newIntrinsics = cameraIntrinsics([f1, f2], [ppx, ppy], [1080 1920], ...
    'RadialDistortion', intrinsics.RadialDistortion, ...
    'Skew', skew);

errorPerImage = [];
for i=1:numOfImages
    currentRotation = outputRotations((i-1)*3+1:i*3);
    currentTranslation = reshape(outputTranslations((i-1)*3+1:(i-1)*3+3),1,3);
    imagePoints = worldToImage(newIntrinsics, eul2rotm(currentRotation), ...
        currentTranslation, worldP, ...
        'ApplyDistortion', true);
    
    errorx = (imagePoints(:, 1) - cornerPoints(:, 1, i));
    errory = (imagePoints(:, 2) - cornerPoints(:, 2, i));
    
    errorSum = 0;
    for j=1:size(imagePoints,1)
        error = norm((imagePoints(j, :)- cornerPoints(j,:,i)));
        errorSum = errorSum + error;
    end
    
    errorPerImage = [errorPerImage; errorSum/size(imagePoints,1)];
end

figure
bar(errorPerImage)
% -----------------------
% Up to here

function errorOutput = fun(x)
    global intrinsics
    global worldP
    global cornerPoints
    global numOfImages

    %     [f1, f2, skew, ppx, ppy, r11, r12, r13, r21, r22, r23, r31, r32, r33, t1, t2, t3] = ...
    %         feval(@(y) y{:}, num2cell(x));

    f1 = x(1);
    f2 = x(2);
    ppx = x(3);
    ppy = x(4);
    skew = x(5);
    rotationMatrices = x(6:6+3*numOfImages-1);
    translationVectors = x(6+3*numOfImages:end);

    intr = cameraIntrinsics([f1, f2], [ppx, ppy], [1080 1920], ...
        'RadialDistortion', intrinsics.RadialDistortion, ...
        'Skew', skew);

    %errorPerImage = [];

    mseSum = 0;
    for i=1:numOfImages
        currentRotation = rotationMatrices((i-1)*3+1:i*3);
        currentTranslation = reshape(translationVectors((i-1)*3+1:(i-1)*3+3),1,3);

        imagePoints = worldToImage(intr, eul2rotm(currentRotation), ...
            currentTranslation, worldP, ...
            'ApplyDistortion', true);

        errorSum = 0;
        for j=1:size(imagePoints,1)
            error = norm((imagePoints(j, :)- cornerPoints(j,:,i)));
            errorSum = errorSum + error;
        end

        %errorPerImage = [errorPerImage; errorSum/size(imagePoints,1)];
        mseSum = mseSum + errorSum;
    end

    errorOutput = mseSum;
end
