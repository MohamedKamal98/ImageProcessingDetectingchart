function result = ReadChart(rgbImg)


figure, imshow(rgbImg);
bw = rgb2gray(rgbImg);

%-------- 1- Extract the circle from ----------------
    % imfindcircles finds circles with radii in the range specified by radiusRange.
    [centers, radii] = imfindcircles(bw,[50 200], 'ObjectPolarity', ...
        'dark', 'Sensitivity',0.95);
    
    % draws the circle border
    % h = viscircles(centers,radii,'EdgeColor','b');
%----------------------------------------------------

%--------- Detect type of chart -----------------
    if(isempty(centers) == 0)
    pie(rgbImg, [centers, radii]);
    else
        barsProject(rgbImg);
    end
%------------------------------------------------
end
