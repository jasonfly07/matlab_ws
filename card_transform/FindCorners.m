% Given an image of a card, find the 4 corners.
% im is a grayscale image.
% coerners are in (x,y)
function [corners] = FindCorners(im)

% Blur the image
h = fspecial('gaussian', [7 7], 2);
im = imfilter(im, h);

% Create the gradient magnitude image
[mag, ~] = imgradient(im);

% HACK: ignore the borders
mag([1:5, end-5:end], :) = 0;
mag(:, [1:5, end-5:end]) = 0;

% Collect all edge points with high gradient magnitude
magThreshold = 200;
magMask = mag > magThreshold;
[edgePtsR, edgePtsC] = find(magMask == 1);
edgePts = [edgePtsR, edgePtsC];

% Set the number of iterations for RANSAC
% TODO: this should be designed so numIter is based on 
% number of edgePts
numIter = 500;
assert(size(edgePts, 1) > numIter * 2);

% Randomly picked numIter pairs of points
pickedInds = randperm(size(edgePts, 1), numIter * 2);
pickedInds = reshape(pickedInds, numIter, 2);
pt1s = edgePts(pickedInds(:, 1), :);
pt2s = edgePts(pickedInds(:, 2), :);

% Calculate all the candidate lines
thetas = atan((pt1s(:, 1) - pt2s(:, 1)) ./ (pt2s(:, 2) - pt1s(:, 2)));
radii = pt1s(:, 1) .* cos(thetas) + pt1s(:, 2) .* sin(thetas);

% For every edgePt, see how many line it resides on
distEpsilon = 1;
lines = [radii, thetas, zeros(numIter, 1)];
for i = 1 : size(edgePts, 1)
  currPt = edgePts(i, :);
  allY = radii ./ sin(thetas) - currPt(1) * cot(thetas);
  allY = abs(allY - currPt(2));
  isInlier = allY < distEpsilon;
  lines(:, 3) = lines(:, 3) + isInlier;
end

% Sort the lines w.r.t. number of inliers
lines = sortrows(lines, -3);

% Look for the top 4 lines
topLines = [lines(1, 1), lines(1, 2)];
pEpsilon = 30;
thetaEpsilon = 0.3;
for i = 2 : size(lines, 1)
  % See if it's close to any stored lines
  % If yes, skip it
  isDuplicated = false;
  for j = 1 : size(topLines, 1)
    pDiff = abs(lines(i, 1) - topLines(j, 1));
    thetaDiff = abs(lines(i, 2) - topLines(j, 2));
    if pDiff < pEpsilon && thetaDiff < thetaEpsilon
      isDuplicated = true;
      break;
    end
  end
  
  if isDuplicated
    continue;
  else
    topLines = [topLines; lines(i, 1), lines(i, 2)];
    if size(topLines, 1) == 4
      break;
    end
  end
end

% Find all the intersections
intersects = [];
for i = 1 : 4
  for j = (i + 1) : 4
    p1 = topLines(i, 1);
    p2 = topLines(j, 1);
    theta1 = topLines(i, 2);
    theta2 = topLines(j, 2);
    A = [cos(theta1), sin(theta1); cos(theta2), sin(theta2)];
    b = [p1; p2];
    intersects = [intersects; (A\b)'];
  end
end

% Remove the ones that are out-of-borders
corners = [];
for i = 1 : size(intersects, 1)
  x = intersects(i, 1);
  y = intersects(i, 2);
  if x > 0 && x < size(im, 1) && y > 0 && y < size(im, 2)
    corners = [corners; x, y];
  end
end

% Reverse x,y because edgePts are in r,c
% TODO: this could be fixed by changing edgePts to x,y
% in the beginning
corners = [corners(:, 2), corners(:, 1)];

end