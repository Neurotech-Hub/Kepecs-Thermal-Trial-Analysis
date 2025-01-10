function rois = roiFrames(frameData)
    % Display first frame for ROI selection
    % Returns structure containing ROIs for different regions
    
    % Create figure for ROI selection
    roiFig = figure('Name', 'ROI Selection', 'Position', [100, 100, 800, 600]);
    
    % Display first frame
    firstFrame = frameData{1}.temp;
    imagesc(firstFrame);
    colormap('jet');
    axis image;
    title('Select Regions of Interest');
    
    % Create ROIs
    roiNames = {'Active Thermal Element', 'Passive Thermal Element'};
    rois = struct();
    
    for i = 1:length(roiNames)
        % Instructions for each ROI
        subtitle(sprintf('Draw ROI for: %s\nClick and drag to select region', roiNames{i}));
        
        % Create ROI and wait for user to draw
        roi = drawrectangle('Label', roiNames{i});
        wait(roi);
        
        % Store ROI position
        rois.(matlab.lang.makeValidName(roiNames{i})) = roi.Position;
    end
    
    % Update title after all ROIs are selected
    title('ROIs Selected');
    subtitle('');
end
