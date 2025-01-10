trialPath = '20250109';

% Get temperature data
[thermal_logger_datetime, active_temp_c, passive_temp_c] = getThermalLoggerData(trialPath);
[body_temp_datetime, body_temp_c] = getInternalBodyTempData(trialPath);

% Get thermal video data and ROIs
[frameData, video_info] = getFrameSubset(trialPath, 1, 10);

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

% Create images directory if it doesn't exist
if ~exist('./images', 'dir')
    mkdir('./images');
end

fprintf('Extracting heat blobs: \n');
% Split frame data into 4 parts and get indices
frameIndices = round(linspace(1, numFrames, 4));
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

% Visualize the heat blob evolution
visualizeHeatBlobs(blobMasks, blobTemps, frameTimes, body_temp_datetime, body_temp_c);
saveas(gcf, './images/heat_blob_evolution.png');
close(gcf);
