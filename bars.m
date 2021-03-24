function [ ] = bars( I )
%EDGEBASED Summary of this function goes here
%   Detailed explanation goes here
% figure,imshow(I);
x = rgb2gray(I);
%get max postion (max line)
results = ocr(x,'TextLayout','Block');
numbers = str2double(regexp(results.Text,'\d+','match'));
maxNumber = max(numbers);
n = size(results.Words);
numberOfWords = n(1);
for i=1:numberOfWords
    b = strcmp(results.Words(i),num2str(maxNumber));
    if b== 1
        maxline = results.WordBoundingBoxes(i,2);
        break;
    end
end
%apply edge detection
BW = edge(x,'canny');
%figure, imshow(BW);
%apply dilation to increase the thickness of edge 
se = strel('rectangle',[10,5]);
BW = imdilate(BW,se);
%figure,imshow(BW);
%convert image to negative 
BW = ~BW;
%figure,imshow(BW); 
%colorize each group of pixels surrounded by white boundary
[L, num] = bwlabel(BW);%group pixels together
RGB = label2rgb(L); %colorize each group
%figure,imshow(RGB);
bars = cell(num,6);
c=1;
[h, w, ~] = size(I);
smallRatio = h*w*0.005;
for i=1:num
    x = uint8(L==i);
    f = sum(sum(x==1));
    if(f < smallRatio)
        continue;
    end
    
    d = zeros(size(I));
    d(:,:,1) = uint8(x).*I(:,:,1);
    d(:,:,2) = uint8(x).*I(:,:,2);
    d(:,:,3) = uint8(x).*I(:,:,3);
    
    counter = 0;
    %figure, imshow(uint8(d)),title(i);
    d = uint8(d);
    redChannel = d(:, :, 1);
    greenChannel = d(:, :, 2);
    blueChannel = d(:, :, 3);
    [h,w] = size(redChannel);
    bool = 0;
    out = maxline;
    for x=1:h
        for j = 1:w
            if d(x,j) ~= 0 && d(x,j)~= 255 && bool ==0
                bool = 1;
                out = x;
            end
            if (redChannel(x,j)== 255 && greenChannel(x,j)== 255 && blueChannel(x,j)== 255) || (redChannel(x,j)== 0 && greenChannel(x,j)== 0 && blueChannel(x,j)== 0)
                counter = counter + 1;                
            end
        end
    end
    
    if counter ==(h*w) || out<maxline
        continue;
    end
    
    down =0;
    up =0;
    right=0;
    left = 0;
    
%     if c ~= 1
%         right=bars{c-1,4};
%         left = bars{c-1,4};
%     end
    %figure, imshow(uint8(d)),title(i);
    bars{c,1} = (d);
    
    %x = rgb2gray(d);
    %d=edge(x,'Sobel',[],'horizontal');
%     figure, imshow((d)),title(i);
    
    [h,w] = size(d);
    for x=1:h
        for j = 1:w
            if d(x,j)~= 0
                up=x;
                break;
            end
        end
        if up ~=0
            break;
        end
    end
    for x=1:h
        for j = 1:w
            if d(h-x,j)~= 0
                down=h-x;
                break;
            end
        end
        if down ~=0
            break;
        end
    end
    %right
    for y=1:h
        for x = 1:w-1
            if d(y,w-x)~= 0
                right=w-x;
                break;
            end
        end
        if right ~=0
            break;
        end
    end
    
    %left
    for y=1:h
        for x = 1:w
            if d(y,x)~= 0
                left=x;
                break;
            end
        end
        if left ~=0
            break;
        end
    end
    
    [h,w,~] = size(d);
    left = mod(left,w);
    right = mod(right,w);
    bars{c,2}=down - up ;
    bars{c,3}=left;
    bars{c,4}=right - bars{c,3};
    
    % ---- get color of bar ----
    
%     figure, imshow((bars{c,1})),title(i);

    barRect = bars{c,1};
    barWidth = bars{c,4};
    y = floor(down-bars{c,2}/2);
    x =floor(bars{c,3}+ barWidth/2);
    barR = barRect(y,x,1);
    barG = barRect(y,x,2);
    barB = barRect(y,x,3);
    
    bars{c,5} = [barR, barG, barB];%<-
    
    c= c +1;
    
end
minline = down;
disp(c-1);

%=============== get lables

%--- remove bars from rgbImg ---
[h,w,~] = size(d);
cropedImg = I;
for i=1:c-1   
    
grayImg = rgb2gray(bars{i,1});
BW = imbinarize(grayImg,graythresh(grayImg));
%apply dilation to increase the thickness of edge 
se = strel('rectangle',[20,15]);
BW = imdilate(BW,se);
BW = uint8(BW) .* I;

cropedImg = cropedImg - BW;
end

%---- searching for legend -----
found = 0;
for i=1:c-1
    barR = bars{i,5}(1);
    barG = bars{i,5}(2);
    barB = bars{i,5}(3);
    
for y=1:h
    for x=1:w
            if((cropedImg(y,x,1) <= barR+20 && cropedImg(y,x,1) >= barR-20) ...
                && (cropedImg(y,x,2) <= barG+20 && cropedImg(y,x,2) >= barG-20) ...
                && (cropedImg(y,x,3) <= barB+20 && cropedImg(y,x,3) >= barB-20))
                    found = 1;
                    %up
                    disp([x,y]);
                    
                    xx=x+150
                    
                    if xx > w
                        xx = w
                    end
                    lblImg = cropedImg(y-10:y+30,x:xx);
%                     figure, imshow((lblImg)),title(i);
                    bars{i,6} = lblImg;
%                     cropedImg(y-10:y+20,x:xx) = 255;
                    break;
                
            end    
    end
    if found ~= 0
        found = 0;
        break;
    end
end
end
% figure, imshow((cropedImg)),title(i);

%display ratios

for i = 1:c-1
    
    if(c > 5)
        figure, imshow(bars{i,6});
        t = (bars{i,2}*maxNumber/(minline-maxline))+0.3;
        title(t, 'FontSize',10,'Color','r');
    else
        subplot(c,1,i);
        imshow(bars{i,6});
        t = (bars{i,2}*maxNumber/(minline-maxline))+0.3;
        title(t, 'FontSize',10,'Color','r');
    end
end


