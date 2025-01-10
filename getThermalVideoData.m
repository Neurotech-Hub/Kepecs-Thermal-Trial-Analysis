function [frameData, video_info] = getThermalVideoData(trialPath)
    fprintf('Starting getThermalVideoData for trial: %s\n', trialPath);
    
    % Find the thermal video file in the trial path
    videoFiles = dir(fullfile(trialPath, '*.tmjsn'));
    if isempty(videoFiles)
        error('No thermal video file (*.tmjsn) found in trial path');
    end
    fullFileName = videoFiles(1).name;
    fullPathName = trialPath;
    fprintf('Found thermal video file: %s\n', fullFileName);
    
    % Create extracted thermal data folder if it doesn't exist
    extracted_thermal_folder = fullfile(fullPathName, 'extracted thermal data');
    if ~exist(extracted_thermal_folder, 'dir')
        mkdir(extracted_thermal_folder);
        fprintf('Created new directory for extracted data\n');
    end

    % Read in the thermal data in string format
    fullFile = fullfile(fullPathName, fullFileName);
    fprintf('Reading thermal video file...\n');
    fid = fopen(fullFile);
    raw = fread(fid, inf);
    str = char(raw');
    
    % Split the string into frames using ETX character (hex 0x03)
    fprintf('Splitting video into frames...\n');
    framesStr = split(str, char(hex2dec('0x03')));
    fclose(fid);
    fprintf('Found %d frames to process\n', numel(framesStr)-2);
    
    % Initialize frameData cell array
    frameData = cell(1, numel(framesStr)-2);
    
    % Process the json string data into thermal matrices
    fprintf('Beginning frame processing...\n');
    lastProgress = 0;  % Track the last printed progress
    for f = 1:numel(framesStr)-2
        frameData{f} = struct();
        frameData{f}.cameraJson = jsondecode(framesStr{f});
        [temp, camera_settings, metadata] = processTcamJsonFrame(frameData{f}.cameraJson);
        frameData{f}.temp = temp;
        frameData{f}.camera_settings = camera_settings;
        frameData{f}.metadata = metadata;
        
        % Display progress only when crossing a 10% threshold
        progress = floor(100 * f / (numel(framesStr)-2));
        if progress >= lastProgress + 10
            fprintf('%d%% complete (%d/%d frames)\n', progress, f, numel(framesStr)-2);
            lastProgress = progress - mod(progress, 10);  % Update to last printed progress
        end
    end
    
    % Get video info from the last frame
    fprintf('Extracting video metadata...\n');
    video_info = jsondecode(framesStr{f+1}).video_info;
    
    % Save the data
    fprintf('Saving processed data...\n');
    full_data = struct();
    full_data.video_info = video_info;
    full_data.frame_data = frameData;
    full_data.vid_name = fullFile;
    
    save_path = fullfile(extracted_thermal_folder, ...
        [strrep(fullFileName, '.tmjsn', ''), '_thermal_data.mat']);
    save(save_path, 'full_data', '-v7.3');
    
    fprintf('Thermal video processing complete!\n');
    fprintf('Saved to: %s\n', save_path);
end 