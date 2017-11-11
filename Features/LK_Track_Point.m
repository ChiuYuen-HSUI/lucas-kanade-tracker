% Return the best-guess velocity of point (x,y) on img1 to img2
% To be used in a pyramid implementation
function [dx, dy] = LK_Track_Point(img1, img2, x, y, win_size, d)
    % Constants
    win_rad = floor(win_size/2);
    max_steps = 20;
    num_cols = size(img1,2);
    num_rows = size(img1,1);
    accuracy_threshold = 0.05; % purely abbitrary now
    % Intensity derivative matrices
    I_y = double(uint8(zeros(num_rows, num_cols)));
    I_x = double(uint8(zeros(num_rows, num_cols)));
    for row = 1 : num_rows-1
      I_x(row,:) = img1(row+1,:)-img1(row,:);
    end
    I_x(num_rows,:) = 0;
    for col = 1 : num_cols-1
      I_y(:,col) = img1(:,col+1)-img1(:,col);
    end
    I_y(:,num_cols) = 0;
    % square derivatives
    I_xx = I_x.^2;
    I_yy = I_y.^2;
    I_xy = I_x.*I_y;
    % Gaussian smoothing + double summation
    gauss_kern = gausswin(win_size) * gausswin(win_size).';
    W_x = conv2(gauss_kern, I_x);
    W_y = conv2(gauss_kern, I_y);
    W_xx = conv2(gauss_kern, I_xx);
    W_yy = conv2(gauss_kern, I_yy);
    W_xy = conv2(gauss_kern, I_xy);
    Z = [W_xx(x,y) W_xy(x,y); W_xy(x,y) W_yy(x,y)];
    % Iterative improvement of estimation
    % Either run for max_steps times or until error residual smaller than
    % accuracy_threshold
    d_current = [0;0];
    for step = 1 : max_steps
        b = [0;0];
        for i = x - win_rad : x + win_rad
            for j = y - win_rad : y + win_rad
                if (not(i < 0 || j < 0 || i > num_rows || j > num_cols) &&  not(i+d_current(1)+d(1)< 0 || j+d_current(2)+d(2) < 0 || i+d_current(1)+d(1) > num_rows || j+d_current(2)+d(2) > num_cols))
                    I_t = img1(i,j) - img2(i + d_current(1) + d(1), j + d_current(2) + d(2));
                    b = b + [I_t*W_x(i,j);I_t*W_y(i,j)];
                end
            end
        end
        guess = Z\b;
        d_current = round(d_current + guess);
        if (abs(guess) < accuracy_threshold)
            break;
        end
    end
    d = d_current;
    dx = d(1);
    dy = d(2);
end