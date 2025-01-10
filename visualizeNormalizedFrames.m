function visualizeNormalizedFrames(normalizedFrameData, maxFrames)
    % Visualize normalized thermal frames with accurate temperature scale
    % normalizedFrameData: cell array of normalized frame data
    % maxFrames: optional parameter to limit number of frames (default 25)
    
    if nargin < 2
        maxFrames = 25;
    end
    
    % Limit number of frames
    numFrames = min(length(normalizedFrameData), maxFrames);
    if length(normalizedFrameData) > maxFrames
        warning('Only displaying first %d frames of %d total frames', maxFrames, length(normalizedFrameData));
    end
    
    % Extract temperature matrices
    tempFrames = cellfun(@(x) x.temp, normalizedFrameData(1:numFrames), 'UniformOutput', false);
    
    % Convert cell array to 4D array for montage
    tempArray = cat(4, tempFrames{:});
    
    % Calculate global temperature range
    minTemp = min(tempArray(:));
    maxTemp = max(tempArray(:));
    
    % Calculate optimal grid size
    if numFrames <= 5
        gridSize = [1 numFrames];
    elseif numFrames <= 10
        gridSize = [2 ceil(numFrames/2)];
    elseif numFrames <= 15
        gridSize = [3 ceil(numFrames/3)];
    elseif numFrames <= 20
        gridSize = [4 ceil(numFrames/4)];
    else
        gridSize = [5 5];
    end
    
    % Create figure
    figure('Name', 'Normalized Thermal Frames', 'Position', [100, 100, 1200, 800]);
    
    % Create montage with consistent temperature scaling
    h = montage(tempFrames, 'Size', gridSize);
    
    % Apply consistent temperature scaling
    clim([minTemp maxTemp]);
    colormap('jet');
    c = colorbar;
    c.Label.String = 'Temperature (°C)';
    
    % Add timestamp to each frame
    ax = gca;
    numRows = gridSize(1);
    numCols = gridSize(2);
    [frameHeight, frameWidth, ~] = size(tempFrames{1});
    
    for i = 1:numFrames
        % Calculate position for timestamp
        row = ceil(i/numCols);
        col = mod(i-1, numCols) + 1;
        
        % Get frame time
        frameTime = datetime([normalizedFrameData{i}.metadata.Date ' ' ...
            normalizedFrameData{i}.metadata.Time], 'InputFormat', 'M/d/yy HH:mm:ss.SS');
        
        % Add timestamp text
        xPos = (col-1)*frameWidth + 5;
        yPos = (row-1)*frameHeight + 20;
    end
    
    % Add title with temperature range
    title(sprintf('Normalized Thermal Frames (%.1f°C to %.1f°C)', minTemp, maxTemp));
end 