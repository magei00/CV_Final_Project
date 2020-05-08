%clear all;

if exist('cam','var')
    if isa(cam,'VideoInput')
        delete(cam)
    end
end

cam = 0;

CreatePreviewWindow(cam);


function CreatePreviewWindow(cam)
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
    
    startButton = StartButton;
    
    recording = false;
    
    frames = 0;
    
    function s = StartButton
        s = uicontrol('Parent', f,...
            'String', 'Start Recording', ...
            'Units', 'normalized',...
            'Position', [0.3, 0.05, 0.18, .05],...
            'FontSize', 15,...
            'Callback', @startRecording);
    end
    
    stopButton = uicontrol('Parent', f,...
        'String', 'Stop Recording', ...
        'Units', 'normalized',...
        'Position', [0.5, 0.05, 0.18, .05],...
        'FontSize', 15,...
        'Enable', 'off',...
        'Callback', @stopRecording);
    
    selectedAdaptor = 0;
    selectedCamera = 0;
    selectedFormat = 0;
       
    CameraChoice(f);
        
    function CreatePreview
        if cam ~= 0
            stop(cam);
            closepreview(cam);
            delete(cam);
        end
        cam = videoinput(selectedAdaptor,selectedCamera,selectedFormat);
        triggerconfig(cam, 'manual');
        
        set(cam, 'FramesPerTrigger', 1);
        set(cam, 'ReturnedColorspace', 'gray');
        
        cam.FrameGrabInterval = 1;  % distance between captured frames
        
        vidRes = cam.VideoResolution;
        nBands = cam.NumberOfBands;
        hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
        preview(cam, hImage);
     %   imshow(hImage);
        
        
    end
    
    function CameraChoice(f)
        hw = imaqhwinfo;
        adaptors = hw.InstalledAdaptors;
        
        t = uicontrol(f, 'Style', 'text', ...
            'Position', [15,0,100,50],...
            'String', 'Select a camera');
        
        adaptorUI = adaptorPopup;
        cameraUI = cameraSelect;
        formatUI = formatPopup;
        
        function camera = cameraSelect
            camera = uicontrol(f, 'Style', 'popupmenu', 'Position', [130, 0, 200, 30]);
            
            dev =imaqhwinfo(selectedAdaptor);
            devIDs = dev.DeviceInfo;
            camera.String = {devIDs.DeviceName};
            camera.Callback = @selection;
            feval(@selection, camera, []);
            
            function selection(src,event)
                val = camera.Value;
                str = camera.String;
                selectedCamera = val;
                formatUI = formatPopup;
            end
        end
        
        function format = formatPopup
            format = uicontrol(f, 'Style', 'popupmenu', 'Position', [350, 0, 200, 30]);
            
            dev =imaqhwinfo(selectedAdaptor,selectedCamera);
            formats = dev.SupportedFormats;
            format.String = formats;
            format.Callback = @selection;
            feval(@selection, format, []);
            
            function selection(src,event)
                val = format.Value;
                str = format.String;
                selectedFormat = str{val};
                CreatePreview;
            end
        end
        
        function adaptor = adaptorPopup
            adaptor = uicontrol(f, 'Style', 'popupmenu', 'Position', [15, 0, 100, 30]);
            adaptor.String = adaptors;
            adaptor.Callback = @selection;
            feval(@selection, adaptor, []);
            
            function selection(src,event)
                val = adaptor.Value;
                str = adaptor.String;
                selectedAdaptor = str{val};
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
        closepreview(cam);
        
        previewDisabledText.Visible = 'on';
        stopButton.Enable = 'on';
        startButton.Enable = 'off';

        frames = cell(1,1);

        recording = true;

        counter = 1;
        tic;
        while (toc < duration && recording == true)
            s = seconds(toc);
            s.Format = 'mm:ss';
            startButton.String = char(s);

            i = getsnapshot(cam);

            frames(counter, 1) = {i};
            counter = counter + 1;            
        end

        stopRecording;

    end

    function stopRecording(src, event)
        stop(cam);
        flushdata(cam);
        
        recording = false;
        
        
        startButton.String = 'Writing Video';
        
        timenow = datestr(now,'hhMMss_ddmmyy');
        vid = VideoWriter([timenow,], 'MPEG-4');
        vid.FrameRate = 30;
        vid.Quality = 40;
        
        open(vid);
        
        for i=1:size(frames,1)
            writeVideo(vid, frames{i,1});
        end
        
        close(vid);
        
        
        previewDisabledText.Visible = 'off';
        startButton.String = 'Start Recording';
        startButton.Enable = 'on';
        stopButton.Enable = 'off';
    end


end



% 
% 
% open(vid);
% 
% close(vid);




