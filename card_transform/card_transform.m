im = imread('leap_small.jpg');
% im = im(5:end-5, 5:end-5, :);
h = fspecial('gaussian', [7 7], 2);
im = imfilter(im, h);
imGray = rgb2gray(im);
[mag, ~] = imgradient(imGray);

% TODO: remove this cropping
mag = mag(5:end-5, 5:end-5);

magMask = mag > 200;
[r, c] = find(magMask == 1);
edgePts = [r, c];

numIter = 500;

% TODO: this should be designed so numIter is based on 
% number of edgePts
assert(size(edgePts, 1) > numIter * 2);

lines = zeros(numIter, 3); % [p, theta, countInlier]

for i = 1 : numIter
  i
  % Randomly pick 2 points
  % They can't be too close to each other
  % (at least 1/10 of the height?)
  while true
    pickedInd = randperm(size(edgePts,1), 2);
    pt1 = edgePts(pickedInd(1), :);
    pt2 = edgePts(pickedInd(2), :);
    if norm(pt1 - pt2) > (size(magMask, 1) / 10)
      break;
    end
  end
  
  
  theta = atan((pt1(1)-pt2(1)) / (pt2(2)-pt1(2)));
  p = pt1(1) * cos(theta) + pt1(2) * sin(theta);
  
  countInlier = 0;
  for j = 1 : size(edgePts, 1)
    currPt = edgePts(j, :);
    distEpsilon = 1;
    y = p / sin(theta) - currPt(1) * cot(theta);
    if abs(y - currPt(2)) < distEpsilon
%       scatter(currPt(1), currPt(2), 200, 'g');
      countInlier = countInlier + 1;
    end
    lines(i, :) = [p, theta, countInlier];
  end 
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
    thetaDiff = (lines(i, 2) - topLines(j, 2));
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
  for j = 2 : 4
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
  if x > 0 && x < size(magMask, 1) && y > 0 && y < size(magMask, 2)
    corners = [corners; x, y];
  end
end

scatter(r, c);
hold on;
scatter(corners(:, 1), corners(:, 2), 200, 'r');
