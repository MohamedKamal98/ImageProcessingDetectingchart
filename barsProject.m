function [ ] = barsProject( I )

x = rgb2gray(I);
figure, imshow(I);

labelType = 2;
%--------------------------get maximuim number and it's postion----------------------------- 
results = ocr(x,'TextLayout','Block');
numbers = str2double(regexp(results.Text,'\d+','match'));
maxNumber = max(numbers);
n = size(results.Words);
numberOfWords = n(1);
for i=1:numberOfWords
    b = strcmp(results.Words(i),num2str(maxNumber));
    if b== 1
        maxright = results.WordBoundingBoxes(i,1);
        maxline = results.WordBoundingBoxes(i,2);
        break;
    end
end
%--------------------------get maximuim number and it's postion----------------------------- 

x = imgaussfilt(x,1.5);
%apply edge detection
BW = edge(x,'canny');
%figure, imshow(BW);
%apply dilation to increase the thickness of edge 
se = strel('rectangle',[5,5]);
BW = imdilate(BW,se);
%figure,imshow(BW);
%convert image to negative 
BW = ~BW;
%figure,imshow(BW); 
%group pixels together apply connected component 
[L, num] = bwlabel(BW);

%matrix for bars and thier information
bars = cell(num,2);

numberOfBars=1;
[h, w, ~] = size(I);
smallRatio = h*w*0.005;
for i=1:num
    temp = uint8(L==i);
    f = sum(sum(temp==1));
    if(f < smallRatio)
        continue;
    end
    
    d = zeros(size(I));
    d(:,:,1) = uint8(temp).*I(:,:,1);
    d(:,:,2) = uint8(temp).*I(:,:,2);
    d(:,:,3) = uint8(temp).*I(:,:,3);
    
    
    counter = 0;
    
    redChannel = d(:, :, 1);
    greenChannel = d(:, :, 2);
    blueChannel = d(:, :, 3);
    
    [h,w] = size(redChannel);
    bool = 0;
    out = maxline;
    outright = maxright;
    white = 0;
    for x=1:h
        for j = 1:w
            if bool == 0 && (redChannel(x,j)~= 0 || greenChannel(x,j)~= 0 || blueChannel(x,j)~= 0)
                bool = 1;
                out = x;
                outright =j;
            end
            if ((redChannel(x,j)<= 255 && redChannel(x,j)>= 220) && (greenChannel(x,j)<= 255 && greenChannel(x,j)>= 220) && (blueChannel(x,j)<= 255 && blueChannel(x,j)>= 220)) || (redChannel(x,j)== 0 && greenChannel(x,j)== 0 && blueChannel(x,j)== 0)
                counter = counter + 1;                
            end
            if ((redChannel(x,j)<= 255 && redChannel(x,j)>= 220) && (greenChannel(x,j)<= 255 && greenChannel(x,j)>= 220) && (blueChannel(x,j)<= 255 && blueChannel(x,j)>= 220))
                white = white + 1;            
            end
        end
    end
    %--------------------------get the label box-----------------------------
    if (white/(h*w))<0.07 && (white/(h*w))>0.01
        
        labelType = 1;
        d = im2bw(d);
        [x,y]=find(d==1); 
        %figure, imshow((d)),title(i);
        %disp(max(x));
        %disp(min(x));
        %disp(max(y));
        %disp(min(y));
        temp = I(min(x):max(x),min(y):max(y));
        %labelBox = imcrop(I,[min(y) min(x) max(y) max(x)]);
        labelBox = temp;
        %figure, imshow(uint8(temp)),title(i);
        %figure, imshow((labelBox)),title(i);
        continue;
    end
    %--------------------------get the label box-----------------------------
    
    % check if not a background and if bar in range
    if counter ==(h*w) || out<maxline || outright < maxright
        continue;
    end
    
    %figure, imshow(uint8(d)),title(i);
    bars{numberOfBars,1} = (d);
    
    %-----------compute the hieght of bar -----------------
    d = im2bw(d);
    [x,y]=find(d==1);      
    %disp(max(x));
    %disp(min(x));
    %disp(max(y));
    %disp(min(y));
    bars{numberOfBars,2}=(max(x))-(min(x));
    %-----------compute the hieght of bar -----------------
    
    numberOfBars= numberOfBars +1;
    minline = max(x);
end

numberOfLabels=1;
if(labelType == 1)
    temp=labelBox;
    %temp=rgb2gray(temp);
    threshold = graythresh(temp);
    temp =~imbinarize(temp,threshold);
    se = strel('disk',4);
    %temp = imclose(temp,se);
    temp = imdilate(temp,se);
    %connected components
    [L,N]=bwlabel(temp);
    %Objects extraction
    labels = cell(N,2);
    
    for n=1:N
       [r,c] = find(L==n);
       n1=labelBox(min(r):max(r),min(c):max(c));
       %figure,imshow(n1);
       n2 = imbinarize(n1);
       se = strel('disk',4);
       n2 = imerode(n2,se);
       black = sum(n2(:) == 0);
       [x,y]=size(n2);
       if(black/(x*y)>=0.9)
           continue
       end
       %figure,imshow(n1);
       labels{numberOfLabels,1} = (n1);
       labels{numberOfLabels,2} = min(r);
       numberOfLabels = numberOfLabels+1;
    end
    [h,w]=size(labelBox);
    if h > w
        [~, idx] = sort([labels{:,2}]); 
        labelsSorted = labels(idx,:);
        labels = labelsSorted;
    end
    
else
    [h, w, ~] = size(I);
    labelBox = imcrop(I,[(maxright+20) (minline+5) w 30]);
    %figure, imshow((labelBox)),title(i);
%----------------------------------------------------
    temp=labelBox;
    temp=rgb2gray(temp);
    threshold = graythresh(temp);
    temp =~imbinarize(temp,threshold);
    se = strel('disk',4);
    temp = imclose(temp,se);
    %connected components
    [L,N]=bwlabel(temp);
    labels = cell(N,1);
    %Objects extraction
    
    for n=1:N
       [r,c] = find(L==n);
       n1=labelBox(min(r):max(r),min(c):max(c));
       labels{numberOfLabels,1} = (n1);
       numberOfLabels=numberOfLabels+1;
       %figure,imshow(n1);
    end
end

%--------------------------compute and display result-----------------------------

disp(numberOfBars-1);
for i = 1:numberOfBars-1
        subplot(numberOfBars,1,i);
        imshow(labels{i,1});
        t = round(((bars{i,2}*maxNumber/(minline-maxline))+0.4));
        title(t, 'FontSize',15,'Color','r');

    %disp(round(((bars{i,2}*maxNumber/(minline-maxline))+0.2),1))
%     figure,imshow(labels{i,1});
%      figure,imshow(round(((bars{i,2}*maxNumber/(minline-maxline))+0.4)));
%     disp(round(((bars{i,2}*maxNumber/(minline-maxline))+0.4)));
end
%--------------------------compute and display result-----------------------------

end

