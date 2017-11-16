function [velo_x, velo_y] = LK_Track_Pyramid_Iterative(raw_img1, raw_img2, X, Y)

    % Constants
    win_rad = 5;
    accuracy_threshold = .01;
    max_iterations = 20;
    max_levels = Maximum_Pyramid_Level(raw_img1, 128);
    num_points = size(X,1);
    % Get images for each pyramid levels
    img1_pyramidized = generate_pyramid(raw_img1, max_levels);
    img2_pyramidized = generate_pyramid(raw_img2, max_levels);
   
    U = X/2^max_levels;
    V = Y/2^max_levels;

    for level = max_levels:-1:1
        % Get image for this level
        img1 = img1_pyramidized{level};
        img2 = img2_pyramidized{level};
        [num_rows, num_cols] = size(img1);

        % Calculate velocity matrix
        %{ 
        Using estimation method, which is not accurate enough
        img1x = zeros(size(img1,1),size(img1,2));
        img1y = zeros(size(img1,1),size(img1,2));
        img1y(1:size(img1,1)-1,:) = - img1(2:size(img1,1),:) + img1(1:size(img1,1)-1,:);
        img1y(size(img1,1),:) = 0;
        img1x(:,1:size(img1,2)-1) = - img1(:,2:size(img1,2)) + img1(:,1:size(img1,2)-1);
        img1x(:,size(img1,2)) = 0;
        %}
        % Calculate velocity of img1 using sobel kernel for higher accuracy
        vertical_velo_kernel = [1 2 1; 0 0 0; -1 -2 -1];
        img1_velo_x = imfilter(img1,vertical_velo_kernel','circular');
        img1_velo_y = imfilter(img1,vertical_velo_kernel,'circular');
        
        for point = 1 : num_points
            level_x = U(point)*2;
            level_y = V(point)*2;
            [cols_range, rows_range, query_points_x, query_points_y, is_out_of_bound] = generate_window(level_x, level_y, win_rad, num_rows, num_cols);
            if is_out_of_bound 
                continue; 
            end 
            I_x = interp2(cols_range,rows_range,img1_velo_x(rows_range,cols_range),query_points_x,query_points_y);
            I_y = interp2(cols_range,rows_range,img1_velo_y(rows_range,cols_range),query_points_x,query_points_y);
            I_d = interp2(cols_range,rows_range,img1(rows_range,cols_range),query_points_x,query_points_y);
            % Iterative improvement for an abitrary number of steps or
            % until error is smaller than accuracy_threshold
            for i = 1 : max_iterations
                [cols_range, rows_range, query_points_x, query_points_y, is_out_of_bound] = generate_window(level_x, level_y, win_rad, num_rows, num_cols);
                if is_out_of_bound, break; end
                I_t = interp2(cols_range,rows_range,img2(rows_range,cols_range),query_points_x,query_points_y) - I_d;
                % Calculate the current estimate
                current_estimate = [I_x(:),I_y(:)]\I_t(:);
                level_x = level_x + current_estimate(1);
                level_y = level_y + current_estimate(2);
                if max(abs(current_estimate)) < accuracy_threshold
                    break; 
                end
            end
            U(point) = level_x;
            V(point) = level_y;
        end
    end
    % Get only one velocity to maintain group structure
    velo_x = median(U-X);
    velo_y = median(V-Y);
end