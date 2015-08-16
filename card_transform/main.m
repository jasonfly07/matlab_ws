im = imread('leap_small.jpg');
im = rgb2gray(im);

[corners] = FindCorners(im);

imshow(im);
hold on;
scatter(corners(:, 1), corners(:, 2), 250, 'g');


