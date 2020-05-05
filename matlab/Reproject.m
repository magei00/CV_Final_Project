global intrinsics 
global rotationMatrices 
global translationVectors
global worldP
global cornerPoints
cornerPoints = corners;

temp = zeros(size(worldPoints,1),1);

worldP = [worldPoints temp];
intrinsics = params.Intrinsics;
rotationMatrices = params.RotationMatrices;
translationVectors = params.TranslationVectors;

% keys = 1:size(corners,1);
% values = [];
% j = 0;
% for i = 1:size(patternDetected,1)
%     if patternDetected(i) == 0
%         continue
%     end
%     j = j+1;
%     values = [values j];
% end
% 
% imagesMap = containers.Map(keys, values);



[f1, f2, ppx, ppy, skew] = fminsearch(@fun, [intrinsics.FocalLength intrinsics.PrincipalPoint intrinsics.Skew]);

function errorSum = fun(x)
global intrinsics 
global rotationMatrices 
global translationVectors 
global worldP
global cornerPoints

%     [f1, f2, skew, ppx, ppy, r11, r12, r13, r21, r22, r23, r31, r32, r33, t1, t2, t3] = ...
%         feval(@(y) y{:}, num2cell(x));
    
     [f1, f2, ppx, ppy, skew] = feval(@(y) y{:}, num2cell(x));
    
    intr = cameraIntrinsics([f1, f2], [ppx, ppy], [1080 1920], ...
        'RadialDistortion', intrinsics.RadialDistortion, ...
        'Skew', skew);
    
    errorPerImage = [];
    
    mseSum = 0;
    
    for i=1:size(translationVectors,1)
        imagePoints = worldToImage(intr, rotationMatrices(:, :, i), ...
            translationVectors(i, :, :), worldP, ...
            'ApplyDistortion', true);
        
        errorx = (imagePoints(:, 1) - cornerPoints(:, 1, i));
        errory = (imagePoints(:, 2) - cornerPoints(:, 2, i));
        
        error = norm(imagePoints(:, :), cornerPoints(:,:,i));
        
        errorPerImage = [errorPerImage; error];
        mseSum = mseSum + error;
    end
    
    errorSum = mseSum;
end
