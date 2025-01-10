function [frameData, video_info] = getFrameSubset(trialPath, startFrame, numFrames)
    % Gets a subset of frames from the thermal video file
    % startFrame: First frame to read (1-based index)
    % numFrames: Number of frames to read (-1 for all remaining frames)
    
    fprintf('Starting getFrameSubset for trial: %s\n', trialPath);
    
    % Find the thermal video file in the trial path
    videoFiles = dir(fullfile(trialPath, '*.tmjsn'));
    if isempty(videoFiles)
        error('No thermal video file (*.tmjsn) found in trial path');
    end
    fullFileName = videoFiles(1).name;
    fullFile = fullfile(trialPath, fullFileName);
    fprintf('Found thermal video file: %s\n', fullFileName);
    
    % Open file and get ETX positions
    fprintf('Scanning file structure...\n');
    fid = fopen(fullFile);
    
    % Read in chunks to find ETX positions
    chunkSize = 1024 * 1024; % 1MB chunks
    etxPositions = [];
    filePos = 0;
    etxChar = char(hex2dec('0x03'));
    
    while ~feof(fid)
        chunk = fread(fid, chunkSize, '*char')';
        etxIndices = strfind(chunk, etxChar);
        etxPositions = [etxPositions, etxIndices + filePos];
        filePos = filePos + length(chunk);
    end
    
    totalFrames = length(etxPositions) - 1;
    fprintf('Found %d total frames\n', totalFrames);
    
    % Validate input parameters
    if startFrame < 1 || startFrame > totalFrames
        error('startFrame must be between 1 and %d', totalFrames);
    end
    
    if numFrames == -1
        numFrames = totalFrames - startFrame + 1;
    end
    endFrame = min(startFrame + numFrames - 1, totalFrames);
    
    % Initialize frameData and timing info
    frameData = cell(1, endFrame - startFrame + 1);
    firstFrameTime = '';
    firstFrameDate = '';
    lastFrameTime = '';
    lastFrameDate = '';
    
    % Read requested frames
    fprintf('Reading frames %d to %d...\n', startFrame, endFrame);
    
    % Position file at start of requested frame
    startPos = 0;
    if startFrame > 1
        startPos = etxPositions(startFrame - 1) + 1; % Skip the ETX character
    end
    fseek(fid, startPos, 'bof');
    
    lastProgress = 0;
    for f = 1:(endFrame - startFrame + 1)
        currentFrame = startFrame + f - 1;
        
        % Calculate frame length
        if currentFrame == 1
            frameLength = etxPositions(1);
        else
            frameLength = etxPositions(currentFrame) - etxPositions(currentFrame-1) - 1;
        end
        
        % Read frame data
        frameStr = fread(fid, frameLength, '*char')';
        
        % Clean the frame string and ensure it's a valid JSON object
        frameStr = strtrim(frameStr);
        if ~isempty(frameStr) && frameStr(end) == etxChar
            frameStr = frameStr(1:end-1);
        end
        
        try
            % Process frame
            frameData{f} = struct();
            if startsWith(frameStr, '"metadata"')
                frameStr = ['{', frameStr];
            end
            if ~endsWith(frameStr, '}')
                frameStr = [frameStr, '}'];
            end
            
            % Parse the JSON data
            jsonData = jsondecode(frameStr);
            
            % Extract only the necessary fields for the frame
            if isfield(jsonData, 'metadata')
                frameData{f}.metadata = jsonData.metadata;
                % Track timing information
                if f == 1
                    firstFrameTime = jsonData.metadata.Time;
                    firstFrameDate = jsonData.metadata.Date;
                end
                lastFrameTime = jsonData.metadata.Time;
                lastFrameDate = jsonData.metadata.Date;
            end
            
            % Process the frame data using processTcamJsonFrame
            [temp, camera_settings, metadata] = processTcamJsonFrame(jsonData);
            frameData{f}.temp = temp;
            frameData{f}.camera_settings = camera_settings;
            if ~isfield(frameData{f}, 'metadata')
                frameData{f}.metadata = metadata;
            end
            
        catch ME
            fprintf('Error processing frame %d: %s\n', currentFrame, ME.message);
            fprintf('Frame string length: %d\n', length(frameStr));
            fprintf('First 100 characters: %s\n', frameStr(1:min(100,length(frameStr))));
            debugFile = fullfile(trialPath, sprintf('debug_frame_%d.json', currentFrame));
            fid_debug = fopen(debugFile, 'w');
            fwrite(fid_debug, frameStr);
            fclose(fid_debug);
            fprintf('Saved problematic frame to: %s\n', debugFile);
            rethrow(ME);
        end
        
        % Skip ETX character
        fseek(fid, 1, 'cof');
        
        % Display progress
        progress = floor(100 * f / (endFrame - startFrame + 1));
        if progress >= lastProgress + 10
            fprintf('%d%% complete (%d/%d frames)\n', progress, f, endFrame - startFrame + 1);
            lastProgress = progress - mod(progress, 10);
        end
    end
    
    % Get video info from the next frame
    fprintf('Reading video metadata...\n');
    % Read as uint8 first to handle potential encoding issues
    videoInfoRaw = fread(fid, etxPositions(endFrame+1) - etxPositions(endFrame) - 1, '*uint8');
    
    try
        % First try direct char conversion
        videoInfoStr = char(videoInfoRaw)';
        
        % If it doesn't start with expected pattern, try other encodings
        if ~(startsWith(videoInfoStr, '{"metadata"') || startsWith(videoInfoStr, '"metadata"'))
            encodings = {'UTF-8', 'ASCII', 'ISO-8859-1', 'windows-1252'};
            
            for enc = encodings
                try
                    videoInfoStr = native2unicode(videoInfoRaw, enc{1});
                    if startsWith(videoInfoStr, '{"metadata"') || startsWith(videoInfoStr, '"metadata"')
                        fprintf('Successfully decoded using %s encoding\n', enc{1});
                        break;
                    end
                catch
                    continue;
                end
            end
        end
        
        % Ensure we have a valid string
        if ~ischar(videoInfoStr) || ~(startsWith(videoInfoStr, '{"metadata"') || startsWith(videoInfoStr, '"metadata"'))
            error('Failed to decode video metadata into valid JSON format');
        end
        
        % Clean up the string
        videoInfoStr = strtrim(videoInfoStr);
        
        % Ensure proper JSON structure
        if startsWith(videoInfoStr, '"metadata"')
            videoInfoStr = ['{', videoInfoStr];
        end
        
        % Find the end of the metadata section (before radiometric data)
        parts = split(videoInfoStr, ',"radiometric"');
        videoInfoStr = parts{1};
        
        % Ensure the JSON object is properly closed
        % Count opening and closing braces
        openBraces = sum(videoInfoStr == '{');
        closeBraces = sum(videoInfoStr == '}');
        
        % Add missing closing braces if needed
        while closeBraces < openBraces
            videoInfoStr = [videoInfoStr, '}'];
            closeBraces = closeBraces + 1;
        end
        
        % For debugging
        fprintf('Processed video info string: %s\n', videoInfoStr);
        
        jsonData = jsondecode(videoInfoStr);
        
        % Create a standardized video_info structure
        video_info = struct();
        if ~isempty(firstFrameTime)  % Use the actual frame times we processed
            video_info.start_time = firstFrameTime;
            video_info.start_date = firstFrameDate;
            video_info.end_time = lastFrameTime;
            video_info.end_date = lastFrameDate;
            video_info.num_frames = endFrame - startFrame + 1;  % Use actual number of frames processed
            video_info.version = 1;
        end
        
    catch ME
        fprintf('Error processing video info: %s\n', ME.message);
        fprintf('Video info string length: %d\n', length(videoInfoStr));
        fprintf('First 100 characters: %s\n', videoInfoStr(1:min(100,length(videoInfoStr))));
        % Save both raw and processed data for debugging
        debugFile = fullfile(trialPath, 'debug_video_info.json');
        fid_debug = fopen(debugFile, 'w');
        fwrite(fid_debug, videoInfoStr);
        fclose(fid_debug);
        debugRawFile = fullfile(trialPath, 'debug_video_info_raw.bin');
        fid_debug = fopen(debugRawFile, 'w');
        fwrite(fid_debug, videoInfoRaw);
        fclose(fid_debug);
        fprintf('Saved problematic video info to: %s\n', debugFile);
        fprintf('Saved raw video info to: %s\n', debugRawFile);
        rethrow(ME);
    end
    
    fclose(fid);
    fprintf('Frame subset processing complete!\n');
end 