trialPath = '20250109';

% Create images directory if it doesn't exist
if ~exist('./images', 'dir')
    mkdir('./images');
end

% Get temperature data
[thermal_logger_datetime, active_temp_c, passive_temp_c] = getThermalLoggerData(trialPath);
[body_temp_datetime, body_temp_c] = getInternalBodyTempData(trialPath);

% Get thermal video data and ROIs
[frameData, video_info] = getFrameSubset(trialPath, 1, 100);

% Create temperature plot
figure('position', [100, 100, 1000, 600]);
plot(thermal_logger_datetime, active_temp_c, 'b-', 'LineWidth', 1.5);
hold on;
plot(thermal_logger_datetime, passive_temp_c, 'r-', 'LineWidth', 1.5);
plot(body_temp_datetime, body_temp_c, 'g-o', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('Time');
ylabel('Temperature (°C)');
title('Temperature Readings Over Time');
legend('Sensor 1 (active)', 'Sensor 2 (passive)', 'Internal Body Temperature','Location','eastoutside');
saveas(gcf, './images/temp_logger_readings.png');

%% 
rois = roiFrames(frameData);
saveas(gcf, './images/rois.png');
close(gcf);
% Now you have access to the ROIs:
% rois.ActiveThermalElement - [x, y, width, height]
% rois.PassiveThermalElement - [x, y, width, height]

% Normalize frame temperatures
normalizedFrameData = normalizeFrameTemperatures(frameData, rois, thermal_logger_datetime, active_temp_c, passive_temp_c);

% After normalizing frames
visualizeNormalizedFrames(normalizedFrameData);
saveas(gcf, './images/normalized_frames.png');
close(gcf);
% Or specify maximum number of frames to display
% visualizeNormalizedFrames(normalizedFrameData, 15);

%% Heat Blob Analysis
% Extract blobs from all frames
numFrames = length(normalizedFrameData);
blobMasks = cell(1, numFrames);    % Initialize cell array for masks
blobTemps = cell(1, numFrames);    % Initialize cell array for temperature data
frameTimes = NaT(1, numFrames);    % Initialize as datetime array with NaT (Not-a-Time)

fprintf('Extracting heat blobs: \n');
frameIndices = 1:numFrames; % round(linspace(1, numFrames, 4));
for i = frameIndices  % Process frames at quarter points
    fprintf('Processing frame %d/%d\n', i, min(10, numFrames));
    % Extract blob data and debug output
    doPlot = (i == frameIndices(1)); % Only plot for first frame
    [blobMask, frameTemps, f] = extractHeatBlob(normalizedFrameData{i}, rois, doPlot);
    
    % Store results
    blobMasks{i} = blobMask;
    blobTemps{i} = frameTemps;
    
    % Get frame time
    frameTimes(i) = datetime([normalizedFrameData{i}.metadata.Date ' ' ...
        normalizedFrameData{i}.metadata.Time], 'InputFormat', 'M/d/yy HH:mm:ss.SS');
    
    % Save diagnostic plot if it was created
    if doPlot && ~isempty(f)
        saveas(f, sprintf('./images/blob_detection_steps_frame.png'));
        close(f);
    end
end
fprintf('done\n');

% Calculate blob movement
[centroids, distances] = calculateBlobMovement(blobMasks);

% Create movement visualization
figure('Name', 'Blob Movement', 'Position', [100, 100, 800, 400]);
subplot(1,2,1);
plot(frameTimes, distances, 'b-o', 'LineWidth', 1.5);
grid on;
xlabel('Time');
ylabel('Distance Moved (pixels)');
title('Blob Movement Over Time');

% Plot centroid positions
subplot(1,2,2);
plot(centroids(:,1), centroids(:,2), 'b-o', 'LineWidth', 1.5);
hold on;
% Add frame numbers
for i = 1:size(centroids,1)
    if ~any(isnan(centroids(i,:)))
        text(centroids(i,1), centroids(i,2), num2str(i), 'FontSize', 8);
    end
end
grid on;
xlabel('X Position (pixels)');
ylabel('Y Position (pixels)');
title('Blob Centroid Positions');
axis image;

% Save movement visualization
saveas(gcf, './images/blob_movement.png');
close(gcf);
%%
% Visualize the heat blob evolution
visualizeHeatBlobs(blobMasks, blobTemps, frameTimes, body_temp_datetime, body_temp_c);
saveas(gcf, './images/heat_blob_evolution.png');
close(gcf);
