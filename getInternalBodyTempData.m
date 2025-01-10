function [datetime_vals, temp_c] = getInternalBodyTempData(trialPath)
    filePath = fullfile(trialPath, 'internalBodyTemp.csv');
    
    % Read the CSV file
    opts = detectImportOptions(filePath);
    opts = setvaropts(opts, 'date', 'InputFormat', 'M/d/yy');  % Specify exact format
    raw = readtable(filePath, opts);
    
    % Extract columns
    dates = raw.date;
    times = raw.time;
    temp_c = raw.temp_c;
    
    % Convert to datetime format
    dateStr = string(dates);
    timeStr = string(times);
    
    % Combine date and time into datetime objects
    datetime_vals = datetime(dateStr + " " + timeStr, 'InputFormat', 'M/d/yy HH:mm');
end 