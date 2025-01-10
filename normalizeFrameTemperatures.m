function normalizedFrameData = normalizeFrameTemperatures(frameData, rois, thermal_logger_datetime, active_temp_c, passive_temp_c)
    % Normalize frame temperatures using known temperature points from thermal logger
    % Returns frameData with temperature values normalized to degrees Celsius
    
    normalizedFrameData = frameData; % Initialize output structure
    
    % Process each frame
    for i = 1:length(frameData)
        % Convert frame timestamp to datetime
        frameTime = datetime([frameData{i}.metadata.Date ' ' frameData{i}.metadata.Time], ...
            'InputFormat', 'M/d/yy HH:mm:ss.SS');
        
        % Find nearest thermal logger datetime
        [~, idx] = min(abs(thermal_logger_datetime - frameTime));
        
        % Get corresponding known temperatures
        known_active_temp = active_temp_c(idx);
        known_passive_temp = passive_temp_c(idx);
        
        % Get ROI positions (rounded to integers for indexing)
        activeROI = round(rois.ActiveThermalElement);
        passiveROI = round(rois.PassiveThermalElement);
        
        % Extract ROI regions and calculate mean values
        activeRegion = frameData{i}.temp(activeROI(2):activeROI(2)+activeROI(4), ...
            activeROI(1):activeROI(1)+activeROI(3));
        passiveRegion = frameData{i}.temp(passiveROI(2):passiveROI(2)+passiveROI(4), ...
            passiveROI(1):passiveROI(1)+passiveROI(3));
        
        measured_active_temp = mean(activeRegion(:));
        measured_passive_temp = mean(passiveRegion(:));
        
        % Calculate linear transformation parameters
        slope = (known_active_temp - known_passive_temp) / ...
            (measured_active_temp - measured_passive_temp);
        intercept = known_active_temp - slope * measured_active_temp;
        
        % Apply transformation to entire frame
        normalizedFrameData{i}.temp = slope * frameData{i}.temp + intercept;
        
        % Store normalization parameters for reference
        normalizedFrameData{i}.normalization.slope = slope;
        normalizedFrameData{i}.normalization.intercept = intercept;
        normalizedFrameData{i}.normalization.nearest_logger_time = thermal_logger_datetime(idx);
        normalizedFrameData{i}.normalization.time_difference_seconds = seconds(abs(thermal_logger_datetime(idx) - frameTime));
    end
end 