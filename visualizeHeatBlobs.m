function visualizeHeatBlobs(blobMasks, blobTemps, frameTimes, body_temp_datetime, body_temp_c)
    % Visualize heat blob evolution using subplots of individual surf plots
    % blobMasks: cell array of binary masks for each frame
    % blobTemps: cell array of temperature matrices for each frame
    % frameTimes: array of datetime values for each frame
    % body_temp_datetime: datetime array of internal temperature measurements
    % body_temp_c: array of internal temperature values in Celsius
    
    % Find valid frames (non-empty blobs)
    validFrames = find(~cellfun(@isempty, blobMasks));
    numValidFrames = length(validFrames);
    
    if numValidFrames == 0
        warning('No valid frames with blobs found.');
        return;
    end
    
    % Calculate subplot layout
    numCols = 2;
    numRows = ceil(numValidFrames / numCols);
    
    % Create figure
    figure('Name', 'Heat Blob Evolution', 'Position', [100, 100, 600*numCols, 600*numRows]);
    
    % Sort frames by time
    validTimes = frameTimes(validFrames);
    [sortedTimes, sortIdx] = sort(validTimes);
    
    % Find global temperature limits for consistent coloring
    allTemps = [];
    for i = validFrames
        if ~isempty(blobTemps{i})
            temps = blobTemps{i}(blobMasks{i});
            allTemps = [allTemps; temps(:)];
        end
    end
    tempLimits = [min(allTemps), max(allTemps)];
    
    % Create subplots
    for idx = 1:numValidFrames
        i = validFrames(sortIdx(idx));
        if ~isempty(blobTemps{i})
            subplot(numRows, numCols, idx);
            
            % Create coordinate matrices
            [height, width] = size(blobTemps{i});
            [X, Y] = meshgrid(1:width, 1:height);
            
            % Get temperature data and mask non-blob regions
            Z = blobTemps{i};
            Z(~blobMasks{i}) = NaN;
            
            % Calculate blob statistics
            blobTemps_valid = Z(~isnan(Z));
            blob_mean = mean(blobTemps_valid);
            blob_std = std(blobTemps_valid);
            
            % Find nearest internal temperature measurement
            [~, nearest_idx] = min(abs(body_temp_datetime - sortedTimes(idx)));
            internal_temp = body_temp_c(nearest_idx);
            
            % Create surface plot for this blob
            surf(X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.9, ...
                'FaceColor', 'interp');
            
            % Set consistent temperature limits
            clim(tempLimits);
            
            % Customize appearance
            colormap('jet');
            
            % Add two-line title with timestamp and statistics
            title({string(sortedTimes(idx)), ...
                sprintf('Blob: %.1f ± %.1f °C; Internal: %.1f °C', ...
                blob_mean, blob_std, internal_temp)}, ...
                'Interpreter', 'none');
            
            % Set labels
            xlabel('X');
            ylabel('Y');
            zlabel('°C');
            
            % Set view angle
            view(-15, 30);
            
            % Add lighting
            lighting gouraud;
            camlight;
        end
    end
    
    % Add overall title
    sgtitle('Heat Blob Evolution Over Time');
    
    % Add colorbar to the figure
    cb = colorbar('Position', [0.92 0.1 0.02 0.8]);
    cb.Label.String = 'Temperature (°C)';
end 