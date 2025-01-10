function [frameData,video_info] = processTcamVideo(fullFile)

fid = fopen(fullFile);
raw = fread(fid,inf);
str = char(raw');
% in a video file each frame is separated by a etx character with hex code
% 0x03, split the string into frames and process each frame as a json
% string
framesStr = split(str, char(hex2dec('0x03')));
fclose(fid);
frameData ={};
for f = 1: numel(framesStr)-2
    frameData{f} = {};
    frameData{f}.cameraJson = jsondecode(framesStr{f});
    [temp camera_settings metadata] = processTcamJsonFrame(frameData{f}.cameraJson);
    frameData{f}.temp = temp;
    frameData{f}.camera_settings = camera_settings;
    frameData{f}.metadata= metadata;
end
video_info = jsondecode(framesStr{f+1});

end