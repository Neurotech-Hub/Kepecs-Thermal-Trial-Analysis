function [centroids, distances] = calculateBlobMovement(blobMasks)
    % Calculate blob centroids and movement between frames
    % blobMasks: cell array of binary masks for each frame
    % centroids: Nx2 array of [x,y] coordinates for each frame (NaN if no blob)
    % distances: Nx1 array of distances moved between consecutive frames (NaN if no movement)
    
    numFrames = length(blobMasks);
    centroids = nan(numFrames, 2);
    distances = nan(numFrames, 1);
    
    % Calculate centroids for each frame
    for i = 1:numFrames
        if ~isempty(blobMasks{i})
            % Get blob region properties
            stats = regionprops(blobMasks{i}, 'Centroid');
            if ~isempty(stats)
                centroids(i,:) = stats.Centroid;
            end
        end
    end
    
    % Calculate distances between consecutive frames
    for i = 2:numFrames
        if ~any(isnan(centroids(i,:))) && ~any(isnan(centroids(i-1,:)))
            % Calculate Euclidean distance
            dx = centroids(i,1) - centroids(i-1,1);
            dy = centroids(i,2) - centroids(i-1,2);
            distances(i) = sqrt(dx^2 + dy^2);
        end
    end
end 