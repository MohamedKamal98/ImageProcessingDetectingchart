function [ ] = pielabelbox( I )

figure,imshow(I);
x = rgb2gray(I);

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
%group pixels together
[L, num] = bwlabel(BW);
disp(num)
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
    redChannel = d(:, :, 1);
    greenChannel = d(:, :, 2);
    blueChannel = d(:, :, 3);
    
    [h,w] = size(redChannel);
    white = 0;
    for x=1:h
        for j = 1:w
            if ((redChannel(x,j)<= 255 && redChannel(x,j)>= 220) && (greenChannel(x,j)<= 255 && greenChannel(x,j)>= 220) && (blueChannel(x,j)<= 255 && blueChannel(x,j)>= 220))
                white = white + 1;            
            end
        end
    end

    %--------------------------get the label box-----------------------------
    if (white/(h*w))<0.08 && (white/(h*w))>0.01   
        figure, imshow(uint8(d));
        d = im2bw(d);
        [x,y]=find(d==1); 
        %figure, imshow((d)),title(i);
        %disp(max(x));
        %disp(min(x));
        %disp(max(y));
        %disp(min(y));
        temp = I(min(x):max(x),min(y):max(y));
        labelBox = imcrop(I,[min(y) min(x) max(y) max(x)]);
        %labelBox = temp;
        figure, imshow(uint8(temp));
        figure, imshow((labelBox)),title(i);
    end
end

end

