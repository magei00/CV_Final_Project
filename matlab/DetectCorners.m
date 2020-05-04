image = '1.png';

I = imread(image);
bw = rgb2gray(I);
% imshow(bw)

edges = edge(bw,'sobel');
% imshow(edges);
% 
figure
%imshow(bw)
axis on
hold on
corners2 = detectHarrisFeatures(bw, 'MinQuality', 0.1);
%scatter(corners2.Location(:,1), corners2.Location(:,2), 80, 'r');
title('Harris')
axis ij
axis ([1, size(bw,2), 1, size(bw,1)])
pbaspect([size(bw,2), size(bw,1), 1])
% 
% figure
% imshow(bw)
axis on
hold on
cornersCleared = clearDuplicates(corners2);

for i=1:size(cornersCleared,1)
    plot(cornersCleared(i,1), cornersCleared(i,2), 'go');
end

%scatter(cornersCleared(:,1), cornersCleared(:,2), 80, 'g');
title('Cleared')
axis ij
axis ([1, size(bw,2), 1, size(bw,1)])
pbaspect([size(bw,2), size(bw,1), 1])



function points = clearDuplicates(corners)
    locs = corners.Location;
    [dim1,~] = size(locs);   
   
    s = 1:dim1;
    locs = [locs s'];
    
    indicesToRemove = [];
    
    minX = min(locs(:,1));
    maxX = max(locs(:,1));
    minY = min(locs(:,2));
    maxY = max(locs(:,2));
    
    xDist = (maxX - minX)/6;
    yDist = (maxY - minY)/6;
    
    for corner = 1:dim1
        if ismember(corner, indicesToRemove) == 1
            continue
        end
        
        searchLocs = locs(...
            locs(:,1)<(locs(corner,1)+xDist) ...
            & locs(:,1)>(locs(corner,1)-xDist) ...
            & locs(:,2)<(locs(corner,2)+yDist) ...
            & locs(:,2)>(locs(corner,2)-yDist), :);
        
        [idx, distances] = knnsearch(searchLocs(:,1:2), ...
            locs(corner,1:2), 'K', 3, 'SortIndices', true);
        distanceRatio = distances(2)/distances(end);
        if distanceRatio < 0.3
            locs(corner,:) = [(locs(corner,1:2)+searchLocs(idx(2),1:2))/2, searchLocs(idx(2),3)];
            indicesToRemove = [indicesToRemove searchLocs(idx(2),3)];
        end
        %plot(locs(corner,1),locs(corner,2),'r*');
    end
    
    
    locs(indicesToRemove,:) = [];
    points = locs;
end