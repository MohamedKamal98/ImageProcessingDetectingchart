function result = pie(rgbImg, circle)

centers = [circle(1), circle(2)];
radii = circle(3);

[rows, columns, numberOfColorChannels] = size(rgbImg);


%------- 2- Extract each color region from the img -------------
center_x = centers(1,1);
center_y = centers(1,2);
r = radii(1);


%returns a row vector of 100 evenly spaced points between x1 and x2.
angles = linspace(0, 2*pi);
x = cos(angles) * r + center_x;
y = sin(angles) * r + center_y;

%======== Extract the RGB circle ============
    % Get a mask of the circle
    mask = poly2mask(x, y, rows, columns);
    % imshow(mask);
    
    %crop the circle from the original image in each layer
    chartCircleRed = immultiply(rgbImg(:,:,1), mask);
    chartCircleGreen = immultiply(rgbImg(:,:,2), mask);
    chartCircleBlue = immultiply(rgbImg(:,:,3), mask);
    
    % concat 3 layers together
    chartCircleRGB = cat(3,chartCircleRed, chartCircleGreen, chartCircleBlue);
    
    % imshow(chartCircleRGB);


%========== segment each category in the circle =========
    %apply edge detection
    bw = rgb2gray(chartCircleRGB);
    BW = edge(bw,'canny');
    % figure, imshow(BW);
    
    %apply dilation to increase the thickness of edge 
    se = strel('disk', 2);
    BW = imdilate(BW,se);
    
    %convert image to negative 
    BW = ~BW;
    
    %colorize each group of pixels surrounded by white boundary
    [L, num] = bwlabel(BW);%group pixels together
    probs = regionprops(L,'all');
    
    %get the losed pixels back
    se = strel('disk', 3);
    L = imdilate(L,se);
    % figure,imshow(L);


%========= store each category in matrix colors ===========
    totalNumOfPixels = 0;
    colors = cell(num,5);
    smallRatio = rows*columns*0.005;
    c = 1; %the number of categories
    
    for i=1:num %loop on all connected objects
        centroid = probs(i).Centroid; %get the center pixel of the object
        x = uint8(L==i);
        f = sum(sum(x==1));
        if(f < smallRatio)
            %ignore the small objects(noise)
            continue;
        end
        
        %colorize the category with its original color
        d = zeros(size(chartCircleRGB));
        d(:,:,1) = uint8(x).*chartCircleRGB(:,:,1);
        d(:,:,2) = uint8(x).*chartCircleRGB(:,:,2);
        d(:,:,3) = uint8(x).*chartCircleRGB(:,:,3);
        
        % Ignore the black BG
        x = d ~= zeros(size(chartCircleRGB));
        ff = sum(sum(x==1));
        if(ff < smallRatio)
            continue;
        end
        
        % Store the category properties in the matrix 'colors'
        
    %     figure,imshow(uint8(d));
        colors{c,1} = d;
        colors{c,2} = f;    
        totalNumOfPixels = totalNumOfPixels + f;
    
        found = 0;
        red = d(uint32(centroid(2)),uint32(centroid(1)),1);
        green = d(uint32(centroid(2)),uint32(centroid(1)),2);
        blue = d(uint32(centroid(2)),uint32(centroid(1)),3);
        colors{c,3} = [red, green, blue];
        c = c + 1;
    end
    c = c-1;
%-----------------------------------------------------------------------

%-- 3- calculate ratio of each color ---
for i=1:c
   colors{i,4} = (colors{i,2} / totalNumOfPixels)*100;
end
%---------------------------------------

%-- 4- get the lable of each color ----
% figure,imshow(rgbImg), title("rgbImg");
s = 1;
tmp_i = (uint32(center_x)+r);
vertical = 0;
% ======= search right the circle for the legend ===========
    for i = (uint32(center_x)+r): columns %loop on columns right the circle
    if(s > c)
        break;
    end
    if(isempty(colors{1,5}) == 0)
        %loop on the column of the first found lable
        i = colors{1,5};
        i = i(2)+2;
    end
    
    for j = 1: rows% loop on all pixels in the current column
        if(s > c)
            break;
        end
        color = colors{s,3};
        
        if(rgbImg(j,i,1) == color(1) ...
            && rgbImg(j,i,2) == color(2) ...
            && rgbImg(j,i,3) == color(3))
            % if the current color is exactly the color of the category
            colors{s, 5} = [j, i];
            s = s+1;
            tmp_i = i;
        end
    end
end

    if(s < c) %if not all lables are detected
    for i = (uint32(center_x)+r): columns %loop on columns right the circle
        if(s > c)
          break;
        end
        i = tmp_i; %start with the last column we stopped at
        for j = 1: rows % loop on all pixels in the current column
            if(s > c)
                break;
            end
            color = colors{s,3};
            if((rgbImg(j,i,1) <= color(1)+20 && rgbImg(j,i,1) >= color(1)-20) ...
                && (rgbImg(j,i,2) <= color(2)+20 && rgbImg(j,i,2) >= color(2)-20) ...
                && (rgbImg(j,i,3) <= color(3)+20 && rgbImg(j,i,3) >= color(3)-20))
               % if the current color is in the same range[-20: +20] of the color of the category
                colors{s, 5} = [j, i];
                s = s+1;
            end
        end  
        end
    end


%======= search under the circle for the legend =============
    tmp = (uint32(center_y)+r);  
    if( s == 1) % if legend is not found right of the circle
        vertical = 1;
        
    for j = (uint32(center_y)+r): rows %loop on rows under the circle
        if(s > c)
            break;
        end
        if(isempty(colors{1,5}) == 0)
            j = colors{1,5};
            j = j(2)+2;
        end
        for i = 1: columns % loop on all pixels in the current row
            if(s > c)
                break;
            end
            color = colors{s,3};
            if(rgbImg(j,i,1) == color(1) ...
                && rgbImg(j,i,2) == color(2) ...
                && rgbImg(j,i,3) == color(3))
                % if the current color is exactly the color of the category
                colors{s, 5} = [j, i];
                s = s+1;
                tmp = j;
            end
        end
    end
    
    if(s < c)
    j = tmp;
    for j = (uint32(center_y)+r): rows
        if(s > c)
          break;
        end
        
        for i = 1: columns
            if(s > c)
                break;
            end
            color = colors{s,3};
            aa = rgbImg(j,i,1);
            aaa = rgbImg(j,i,2);
            aaaa = rgbImg(j,i,3);
    
            if((rgbImg(j,i,1) <= color(1)+20 && rgbImg(j,i,1) >= color(1)-20) ...
                && (rgbImg(j,i,2) <= color(2)+20 && rgbImg(j,i,2) >= color(2)-20) ...
                && (rgbImg(j,i,3) <= color(3)+20 && rgbImg(j,i,3) >= color(3)-20))
                % if the current color is in the same range[-20: +20] of the color of the category
                colors{s, 5} = [j, i];
                s = s+1;
            end
        end  
        end
    end
    end

%======== search up the circle for the legend ===============
    if( s == 1)
    vertical = 1;    
    for j = (uint32(center_y)+r): rows
        if(s > c)
            break;
        end
        if(isempty(colors{1,5}) == 0)
            j = colors{1,5};
            j = j(2)+2;
        end
        for i = 1: columns
            if(s > c)
                break;
            end
            color = colors{s,3};
            aa = rgbImg(j,i,1);
            aaa = rgbImg(j,i,2);
            aaaa = rgbImg(j,i,3);
    
            if(rgbImg(j,i,1) == color(1) ...
                && rgbImg(j,i,2) == color(2) ...
                && rgbImg(j,i,3) == color(3))
                colors{s, 5} = [j, i];
                s = s+1;
                tmp = j;
            end
        end
    end
    
    if(s < c)
    j = tmp;
    for j = 1 : (uint32(center_y)-r)
        if(s > c)
          break;
        end
        
        for i = 1: columns
            if(s > c)
                break;
            end
            color = colors{s,3};
            aa = rgbImg(j,i,1);
            aaa = rgbImg(j,i,2);
            aaaa = rgbImg(j,i,3);
    
            if((rgbImg(j,i,1) <= color(1)+20 && rgbImg(j,i,1) >= color(1)-20) ...
                && (rgbImg(j,i,2) <= color(2)+20 && rgbImg(j,i,2) >= color(2)-20) ...
                && (rgbImg(j,i,3) <= color(3)+20 && rgbImg(j,i,3) >= color(3)-20))
                colors{s, 5} = [j, i];
                s = s+1;
            end
        end  
        end
    end
    end



%======= crop the lables ============
    for i=1:c
    color = colors{i,5};
    if(vertical == 1)
        limit = 70;
    else      
        limit = columns - color(2) - 10;
    end
    legendRed = rgbImg(color(1)-10: color(1)+17,color(2):color(2)+limit,1);
    legendGreen = rgbImg(color(1)-10: color(1)+17,color(2):color(2)+limit,2);
    legendBlue = rgbImg(color(1)-10: color(1)+17,color(2):color(2)+limit,3);
    % concat 3 layers together
    legendRGB = cat(3,legendRed, legendGreen, legendBlue);
    colors{i,5} = legendRGB;
    
    if(c > 5)
        figure, imshow(legendRGB);
        t = colors{i,4} + "%";
        title(t, 'FontSize',10,'Color','r');
    else
        subplot(c,1,i);
        imshow(legendRGB);
        t = colors{i,4} + "%";
        title(t, 'FontSize',10,'Color','r');
    end


end

%---------------------------------------
end

