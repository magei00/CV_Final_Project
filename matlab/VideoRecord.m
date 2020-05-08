
global cam
%Make sure to stop the camera if it's reserved
if exist('cam','var')
    if isa(cam,'VideoInput')
        delete(cam)
    end
end


cam = 0;

CreatePreviewWindow;

function CreatePreviewWindow
    global cam
    [~,~,screenWidth, screenHeight] = feval(@(y) y{:}, num2cell(get(0, 'ScreenSize')));
    f = figure('Name', 'Video Recording Preview', ...
        'Position', [(screenWidth-1280)/2, (screenHeight-720)/2, 1280, 720]);
    
    previewDisabledText = uicontrol('Style', 'text', ...
        'Units', 'normalized',...
        'Position', [.3, .5, .4, .16],...
        'Visible', 'off',...
        'String', 'Preview is disabled for performance',...
        'FontSize', 35,...
        'BackgroundColor', 'black',...
        'ForegroundColor', 'white');
    
    startButton = uicontrol('Parent', f,...
            'String', 'Start Recording', ...
            'Units', 'normalized',...
            'Position', [0.3, 0.05, 0.18, .05],...
            'FontSize', 15,...
            'Callback', @startRecording);;
    
    stopButton = uicontrol('Parent', f,...
        'String', 'Stop Recording', ...
        'Units', 'normalized',...
        'Position', [0.5, 0.05, 0.18, .05],...
        'FontSize', 15,...
        'Enable', 'off',...
        'Callback', @stopRecording);    
        
    % Whether a recording is in progress or not
    recording = false;
    
    % Temp, will hold the recorded frames before writing to a file
    frames = 0;
       
    % Selected camera options, will get values from the drop downs
    selectedAdaptor = 0;
    selectedCamera = 0;
    selectedFormat = 0;
       
    % Call the function to create the drop downs
    CameraChoice(f);
        
    % Temp, will be used as the image to show the camera preview
    hImage = 0;
    
    % Called to create a preview feed of the camera
    function CreatePreview
        % Need to reset the current camera, in case the parameters have
        % changed
        if cam ~= 0
            recording = false;
            stop(cam);
            closepreview(cam);
            delete(cam);
        end
        
        % Create a new videoinput with the current parameters
        cam = videoinput(selectedAdaptor,selectedCamera,selectedFormat);
        
        % Recording parameters
        triggerconfig(cam, 'manual');
        set(cam, 'FramesPerTrigger', 1);
        set(cam, 'ReturnedColorspace', 'gray');
        cam.FrameGrabInterval = 1;
        
        % Preview image parameters
        vidRes = cam.VideoResolution;
        nBands = cam.NumberOfBands;
        hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
        preview(cam, hImage);
    end
    
    % Handles drop down logic
    function CameraChoice(f)
        % Get the connected cameras info
        hw = imaqhwinfo;
        adaptors = hw.InstalledAdaptors;
        
        t = uicontrol(f, 'Style', 'text', ...
            'Position', [10,0,100,50],...
            'String', 'Select a camera');
        
        % References to the drop downs
        adaptorUI = adaptorPopup;
        cameraUI = cameraSelect;
        formatUI = formatPopup;
        
        % Drop down for the camera selection
        function camera = cameraSelect
            camera = uicontrol(f, 'Style', 'popupmenu', 'Position', [130, 0, 200, 30]);
            
            % Get the names of the camers connected to the selected adaptor
            dev =imaqhwinfo(selectedAdaptor);
            devIDs = {dev.DeviceInfo.DeviceName};
            camera.String = devIDs;
            
            camera.Callback = @selection;
            
            % Call the callback to update the formats drop down, to show
            % the correct values for this camera
            feval(@selection, camera, []);
            
            % Save the setting and update formats when camera is changed
            function selection(src,event)
                val = camera.Value;
                str = camera.String;
                selectedCamera = val;
                
                % Delete formats drop down and create a new one with the
                % values for the new selected camera
                if ~isempty(event)
                    delete(formatUI);
                end
                formatUI = formatPopup;
            end
        end
        
        % Drop down for format selection
        function format = formatPopup
            format = uicontrol(f, 'Style', 'popupmenu', 'Position', [350, 0, 200, 30]);
            
            % Get available formats
            dev =imaqhwinfo(selectedAdaptor,selectedCamera);
            formats = dev.SupportedFormats;
            format.String = formats;
            
            format.Callback = @selection;
            
            % Call the callback manually to update selected format
            feval(@selection, format, []);
            
            % Update selected format and initialize a preview feed with the
            % new parameters
            % Changing any of the other drop downs will call this function
            % eventually, from left to right: Adaptor calls Camera, Camera
            % calls Format, Format calls CreatePreview
            function selection(src,event)
                val = format.Value;
                str = format.String;
                selectedFormat = str{val};
                CreatePreview;
            end
        end
        
        % Drop down for the adaptors
        function adaptor = adaptorPopup
            adaptor = uicontrol(f, 'Style', 'popupmenu', 'Position', [15, 0, 100, 30]);
            
            % Get adaptor names
            adaptor.String = adaptors;
            
            % For the first time save the first adaptor found as the
            % selected
            adaptor.Callback = @selection;
            feval(@selection, adaptor, []);
            
            % Save selection and update camera drop down
            function selection(src,event)
                val = adaptor.Value;
                str = adaptor.String;
                selectedAdaptor = str{val};
                
                % Delete the previous drop down and create a new one with
                % the values for the new selected adaptor
                if ~isempty(event)
                    delete(cameraUI);
                end
                cameraUI = cameraSelect;
            end
        end
    end

    function startRecording(src, event)
        dlg = inputdlg('Enter desired duration, leave empty if you want to stop recording manually');
        duration = str2num(dlg{1});

        if size(duration,1) == 0
            duration = 1000000;
        else
            duration = duration(1);
        end

        start(cam);
        
        % Stop preivew when recording, as it is a significant performance
        % overhead when recording, which in turn makes it impossile to get
        % real time video
        closepreview(cam);
        previewDisabledText.Visible = 'on';
        
        % Toggle button interactivity
        stopButton.Enable = 'on';
        startButton.Enable = 'off';

        % Initialize frames as a cell array
        % We don't know size, so 1 will do for now
        frames = cell(500,1);

        % Set recording flag to true
        recording = true;

        % Frame counter
        counter = 1;
        
        pause(0.2);
        
        tic;
        while (toc <= duration && recording == true)
            % Replace start recording button text with the elapsed time
            s = seconds(toc);
            s.Format = 'mm:ss';
            startButton.String = char(s);

            % Take a snapshot
            i = getsnapshot(cam);

            % Add to the frames array
            frames(counter, 1) = {i};
            counter = counter + 1;      
        end


        % Perform required steps when recording is over
        if recording == true
            stopRecording;
        end
        
        % Free cam cache
        %stop(cam);
        flushdata(cam);
        
        % Start previewing again
        CreatePreview;

    end

    function stopRecording(src, event)
        % Set recording flag to false
        recording = false;
           
        % Write the frames to a video file
        startButton.String = 'Writing Video';
        
        timenow = datestr(now,'hhMMss_ddmmyy');
        vid = VideoWriter([timenow,], 'MPEG-4');
        vid.FrameRate = 30;
        vid.Quality = 40;
        
        open(vid);
        
        for i=1:size(frames,1)
            if isempty(frames{i,1})
                break;
            end
            
            writeVideo(vid, frames{i,1});
        end
        
        close(vid);
        
        % Update buttons        
        previewDisabledText.Visible = 'off';
        startButton.String = 'Start Recording';
        startButton.Enable = 'on';
        stopButton.Enable = 'off';
        

        
        answer = questdlg('Proceed with the calibration?',...
            'Calibrate',...
            'Yes', 'No', 'Yes');
        
        switch answer
            case 'Yes'
                % Calibrate using the recorded video
                display(answer);      
        end
    end
end