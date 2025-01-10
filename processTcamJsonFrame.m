function[tempArray, cam_settings, metadata]  = processTcamJsonFrame(data)
    %telemetry data
    cam_settings = {};
    metadata = data.metadata;
    telemetry_decoded_bytes = matlab.net.base64decode(data.telemetry);
    telemetry_words =  typecast(uint8(telemetry_decoded_bytes), 'uint16');
    %this describes the telemetry word offset https://github.com/danjulio/lepton/blob/f2c31876e3f9a02c8b55931d2382ef26813e711c/ESP32/tCam-Mini/readme.md
    %because matlab is 1 indexes and the offset in the danjulio github is 0
    %offset, his offset is off by 1 (add 1 to his offset to get the info here)
    % the status word is a combination of word 3 and 4 (4 and 5 with matlab
    % indexing) - so it's two 16-bit or a 32 bit combination
    % each of these 32 bits corresponds to info, which is on the lepton data
    % sheet chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://cdn.sparkfun.com/assets/e/9/6/0/f/EngineeringDatasheet-16465-FLiR_Lepton_8760_-_Thermal_Imaging_Module.pdf
    
    % status bit is a two-word combination, this is all big endian encoded and
    % per the protocol the first word is low and the second is high
    status_bits = [dec2bin(telemetry_words(4+1),16),dec2bin(telemetry_words(3+1),16), ];
    % position 32 is actually bit 0, 31 is bit 1, 30 is bit 2, and so on
    status_bits(32-12);
    %swap_endian_status = dec2bin(swapbytes(uint32(bin2dec(status_bits))))
    
    cam_settings.ffc_desired = status_bits(32-3);
    cam_settings.ffc_state = [status_bits(32-4) status_bits(32-4)];
    cam_settings.agc_state = status_bits(32-12);
    cam_settings.shutter_lockout = status_bits(32-15);
    cam_settings.over_temperature_shutdown_imminent  = status_bits(32-20);
    
    cam_settings.tlinear_enabled_flag = telemetry_words(208+1);
    cam_settings.tlinear_resolution_flag = telemetry_words(209+1);
    
    if cam_settings.tlinear_resolution_flag == 0
        cam_settings.t_linear_resolution = 0.1;
    end
    if cam_settings.tlinear_resolution_flag == 1
        cam_settings.t_linear_resolution = 0.01;
    end
    cam_settings.emissivity_scaled = telemetry_words(99+1);
    cam_settings.emissivity = double(cam_settings.emissivity_scaled)/8192;
    
    
    %radiometric data
    radiometry_decoded = matlab.net.base64decode(data.radiometric);
    raw_pixel_data = double(typecast(uint8(radiometry_decoded), 'uint16'));
    temp = raw_pixel_data*cam_settings.t_linear_resolution-273.15;
    tempArray = reshape(temp,[160,120]);
end