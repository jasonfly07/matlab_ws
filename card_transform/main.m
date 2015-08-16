im = imread('leap_small.jpg');
im = rgb2gray(im);

[corners] = FindCorners(im);

% Re-order corners this way: tl, tr, br, bl
% Assume that the tl corner is closest to 1,1, etc.
imageCorners = [          1,           1;
                size(im, 2),           1;
                size(im, 2), size(im, 1);
                          1, size(im, 1)];
cornersTmp = [];
for i = 1 : 4
  cornersVector = corners - repmat(imageCorners(i, :), 4, 1);
  dist = (cornersVector(:, 1).^2 + cornersVector(:, 2).^2) .^ 0.5;
  [~, ind] = min(dist);
  cornersTmp(i, :) = corners(ind, :);
end
corners = cornersTmp;

imNewHeight = size(im,1);
imNewWidth  = round(size(im,1)*(7/4));
cornersFinal = [         1,           1; 
                imNewWidth,           1;
                imNewWidth, imNewHeight;
                         1, imNewHeight];

corners = corners';
cornersFinal = cornersFinal';
h = ComputeHNorm(corners, cornersFinal);

imNew = uint8(zeros(imNewHeight, imNewWidth));
for x = 1 : size(imNew, 2)
  for y = 1 : size(imNew, 1)
    lookupPt = h * [x; y; 1];
    lookupPt = [lookupPt(1)/lookupPt(3); lookupPt(2)/lookupPt(3)];
    lookupPt = round(lookupPt);
    if lookupPt(1) > 0 && lookupPt(1) < size(im, 2) && ...
       lookupPt(2) > 0 && lookupPt(2) < size(im, 1)
      imNew(y, x) = im(lookupPt(2), lookupPt(1));
    else
      imNew(y, x) = 0;
    end
  end
end

subplot(2, 1, 1);
imshow(im);
hold on;
scatter(corners(1, :), corners(2, :), 250, 'g');
subplot(2, 1, 2);
imshow(imNew);