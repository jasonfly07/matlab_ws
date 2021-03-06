% Get the image & convert it to grayscale
im = imread('sf.jpg');
imGray = rgb2gray(im);
imGray = im2double(imGray);
[imH, imW] = size(imGray);

% Blur the image for denoising
H = fspecial('gaussian', [5, 5], 5);
imGray = imfilter(imGray, H, 'replicate');

% Create a gradient magnitude mask
gradThreshold = 0.3;
[gradMag, ~] = imgradient(imGray);
gradMask = (gradMag > gradThreshold);

% Find all the connected compoments & remove small ones
cc = bwconncomp(gradMask);
ccSizeThreshold = 1000;
for i = 1 : cc.NumObjects
  currCC = cc.PixelIdxList{i};
  if size(currCC, 1) < ccSizeThreshold
    gradMask(currCC) = 0;
  end
end

% Find the mask for foreground with convex hull
foregroundMask = bwconvhull(gradMask);
edgeMask = edge(foregroundMask, 'Sobel');

% Use Hough transform to find the borders of the card
[H, theta, rho] = hough(edgeMask, 'RhoResolution', 5, 'Theta', [-90:0.5:89.5]);
P = houghpeaks(H, 100); % 100 is just an arbitrarily large number
lines = houghlines(edgeMask, theta, rho,P, 'FillGap', 30, 'MinLength', 3);

% Find the intersections of all the lines
% Ignore the ones out-of-bound
corners = [];
for i = 1:length(lines)
  for j = 1:length(lines)
    if i>=j, continue; end;
    p1 = lines(i).rho;
    p2 = lines(j).rho;
    t1 = lines(i).theta;
    t2 = lines(j).theta;

    x = (p1*sind(t2)-p2*sind(t1))/(cosd(t1)*sind(t2)-sind(t1)*cosd(t2));
    y = (p1*cosd(t2)-p2*cosd(t1))/(sind(t1)*cosd(t2)-cosd(t1)*sind(t2));
    if x <= 0 || x > imW || y <= 0 || y > imH, continue; end;
    corners = [corners; x, y];
  end
end

% Re-order corners this way: tl, tr, br, bl
% Assume that the tl corner is closest to 1,1, etc.
imageCorners = [          1,           1;
                size(im, 2),           1;
                size(im, 2), size(im, 1);
                          1, size(im, 1)];
cornersTmp = [];
for i = 1 : 4
  cornersVector = corners - repmat(imageCorners(i, :), size(corners, 1), 1);
  dist = (cornersVector(:, 1).^2 + cornersVector(:, 2).^2) .^ 0.5;
  [~, ind] = min(dist);
  cornersTmp(i, :) = corners(ind, :);
end
corners = cornersTmp;

% Measure the skewed widths & heights
heightL = norm(corners(1,:) - corners(4,:));
heightR = norm(corners(2,:) - corners(3,:));
widthT = norm(corners(1,:) - corners(2,:));
widthB = norm(corners(3,:) - corners(4,:));

% Set up the target image dimensions
% Use the maximum of skewed width and height 
% to approxmate the target dimensions
imNewHeight = max([heightL, heightR]);
imNewWidth  = max([widthT, widthB]);
cornersNew = [         1,           1; 
              imNewWidth,           1;
              imNewWidth, imNewHeight;
                       1, imNewHeight];

% Compute the homography matrix
corners = corners';
cornersNew = cornersNew';
h = ComputeHNorm(cornersNew, corners);

% Apply it to the original image
tform = projective2d(h');
imNew = imwarp(im, tform);

% Plot the results
subplot(2, 2, 1);
imshow(im); title('Original');
subplot(2, 2, 2);
imshow(foregroundMask); title('Foreground Mask');
subplot(2, 2, 3);
imshow(imGray); title('Lines & Corners');
hold on;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
   plot(xy(1,1), xy(1,2), 'x', 'LineWidth', 2, 'Color', 'yellow');
   plot(xy(2,1), xy(2,2), 'x', 'LineWidth', 2, 'Color', 'red');
end
scatter(corners(1, :), corners(2, :), 250, 'w');
subplot(2, 2, 4);
imshow(imNew); title('Result');