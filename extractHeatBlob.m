function [blobMask, blobTemps, f] = extractHeatBlob(frame, rois, doPlot)
    % Extract heat blob from thermal frame
    % frame: structure containing thermal frame data
    % rois: structure containing ROI coordinates
    % doPlot: boolean flag to enable/disable diagnostic plotting
    % f: figure handle (if doPlot is true)
    
    if nargin < 3
        doPlot = false;
    end
    
    blob_area_threshold = 400;
    temp_threshold = 30;
    f = [];

    % Initialize outputs
    blobMask = [];
    blobTemps = [];
    
    % Create and show ROI mask
    roiMask = false(size(frame.temp));
    activeROI = round(rois.ActiveThermalElement);
    passiveROI = round(rois.PassiveThermalElement);
    
    roiMask(activeROI(2):activeROI(2)+activeROI(4), ...
        activeROI(1):activeROI(1)+activeROI(3)) = true;
    roiMask(passiveROI(2):passiveROI(2)+passiveROI(4), ...
        passiveROI(1):passiveROI(1)+passiveROI(3)) = true;
    
    % Create temperature threshold mask
    tempMask = frame.temp > temp_threshold & ~roiMask;
    
    % Find connected components
    CC = bwconncomp(tempMask);
    
    if CC.NumObjects > 0
        % Get area of each component
        areas = cellfun(@numel, CC.PixelIdxList);
        
        % Find largest component meeting size criterion
        [maxArea, maxIdx] = max(areas);
        
        if maxArea >= blob_area_threshold
            % Create mask for largest blob
            blobMask = false(size(frame.temp));
            blobMask(CC.PixelIdxList{maxIdx}) = true;
            
            % Get actual temperature values for the blob
            blobTemps = frame.temp;
            blobTemps(~blobMask) = NaN; % Set non-blob areas to NaN
        end
    end
    
    % Optional diagnostic plotting
    if doPlot
        f = figure('Name', 'Blob Detection Steps', 'Position', [100, 100, 1200, 400]);
        
        % Original temperature data
        subplot(1,4,1)
        imagesc(frame.temp);
        colormap('jet');
        colorbar;
        title('Original Temperature Data');
        axis image;
        
        % Show ROI mask
        subplot(1,4,2)
        imagesc(roiMask);
        title('ROI Mask (excluded regions)');
        axis image;
        
        % Show temperature threshold mask
        subplot(1,4,3)
        imagesc(tempMask);
        title(sprintf('Temperature Threshold Mask (>%d°C)', temp_threshold));
        axis image;
        
        % Show final blob or diagnostic message
        subplot(1,4,4)
        if ~isempty(blobMask)
            imagesc(blobTemps, 'AlphaData', ~isnan(blobTemps));
            colormap('jet');
            colorbar;
            title(sprintf('Final Blob (Area: %d, Avg Temp: %.1f°C)', ...
                maxArea, mean(blobTemps(~isnan(blobTemps)))));
        else
            if CC.NumObjects > 0
                title(sprintf('No blob ≥ %d pixels\nLargest area: %d', ...
                    blob_area_threshold, maxArea));
            else
                title('No connected components found');
            end
        end
        axis image;
        
        % Add overall title
        sgtitle(sprintf('Frame Time: %s %s', frame.metadata.Date, frame.metadata.Time));
    end
end 