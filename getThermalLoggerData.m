function [datetime_vals, temp1C, temp2C, varargout] = getThermalLoggerData(trialPath)
    filePath = fullfile(trialPath, 'thermalLogger.csv');

    % Read the raw data as text first
    rawData = readlines(filePath);

    % Find indices of header rows
    headerIndices = find(contains(rawData, 'Place,Date,Time'));

    % Skip the first header (we need it) and remove subsequent headers
    cleanData = rawData(1:headerIndices(1));  % Keep data up to first header
    if length(headerIndices) > 1
        for i = 2:length(headerIndices)
            % Add data between headers (excluding the header rows)
            cleanData = [cleanData; rawData(headerIndices(i-1)+1:headerIndices(i)-1)];
        end
        % Add remaining data after last header
        cleanData = [cleanData; rawData(headerIndices(end)+1:end)];
    end

    % Write cleaned data to temporary file
    tempFile = fullfile(trialPath, 'temp_clean.csv');
    writelines(cleanData, tempFile);

    % Now read the cleaned CSV file
    opts = detectImportOptions(tempFile);
    opts = setvaropts(opts, 'Date', 'InputFormat', 'MM/dd/yy');
    raw = readtable(tempFile, opts);

    % Delete temporary file
    delete(tempFile);

    % Extract columns
    dates = raw.Date;  % Date column
    times = raw.Time;  % Time column
    temp1F = raw.Value;  % First temperature (F)
    temp2F = raw.Value_1;  % Second temperature (F)

    % Convert temperatures from F to C
    temp1C = (temp1F - 32) * (5/9);
    temp2C = (temp2F - 32) * (5/9);

    % First, let's ensure our date and time strings are properly formatted
    dateStr = string(dates);
    timeStr = string(times);

    % Combine date and time into datetime objects
    datetime_vals = datetime(dateStr + " " + timeStr, 'InputFormat', 'MM/dd/yy HH:mm:ss');
    
    % Return rawData as optional output
    if nargout > 3
        varargout{1} = rawData;
    end
end