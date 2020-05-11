global cam
global selectedFile
global statusText

%Make sure to stop the camera if it's reserved
if exist('cam','var')
    if isa(cam,'VideoInput')
        delete(cam)
    end
end

cam = 0;

% Selected file to calibrate
selectedFile = 0;


CreatePreviewWindow;

function CreatePreviewWindow
    global statusText
    global cam
    global selectedFile
    
    [~,~,screenWidth, screenHeight] = feval(@(y) y{:}, num2cell(get(0, 'ScreenSize')));
    f = figure('Name', 'Video Recording Preview', ...
        'Position', [(screenWidth-1280)/2, (screenHeight-720)/2, 1280, 720]);
    
    statusText = uicontrol('Style', 'text', ...
        'Units', 'normalized',...
        'Position', [.3, .93, .4, .03],...
        'Visible', 'on',...
        'String', 'Ready',...
        'FontSize', 10);
    
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
            'Callback', @startRecording);
    
    stopButton = uicontrol('Parent', f,...
        'String', 'Stop Recording', ...
        'Units', 'normalized',...
        'Position', [0.5, 0.05, 0.18, .05],...
        'FontSize', 15,...
        'Enable', 'off',...
        'Callback', @stopRecording);    
    
    selectedFileText = uicontrol('Parent', f,...
        'Style', 'text', ...
        'String', 'Select a file', ...
        'Units', 'normalized',...
        'Position', [0.8, 0.093, 0.129, .026],...
        'FontSize', 10,...
        'Enable', 'on',...
        'BackgroundColor', 'white', ...
        'ForegroundColor', 'black'); 
    
    browseButton = uicontrol('Parent', f,...
        'String', 'Brwose', ...
        'Units', 'normalized',...
        'Position', [0.93, 0.09, 0.05, .03],...
        'FontSize', 10,...
        'Enable', 'on',...
        'Callback', @browseForFile); 
    
    calibrateButton = uicontrol('Parent', f,...
        'String', 'Calibrate', ...
        'Units', 'normalized',...
        'Position', [0.8, 0.01, 0.18, .08],...
        'FontSize', 20,...
        'Enable', 'off',...
        'Callback', @calibrate); 
        
    % Whether a recording is in progress or not
    recording = false;
    
    % Temp, will hold the recorded frames before writing to a file
    frames = 0;
       
    % Selected camera options, will get values from the drop downs
    selectedAdaptor = 0;
    selectedCamera = 0;
    selectedFormat = 0;
       
    hw = imaqhwinfo;
    if ~size(hw.InstalledAdaptors,1) == 0
        % Call the function to create the drop downs
        CameraChoice(f);
    else
        previewDisabledText.String = 'No cameras detected';
        previewDisabledText.Visible = 'on';
        previewDisabledText.BackgroundColor = 'white';
        previewDisabledText.ForegroundColor = 'black';
    end    
        
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
        set(cam, 'ReturnedColorspace', 'grayscale');
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
        selectedFile = timenow;
        selectedFileText.String = timenow;
        calibrateButton.Enable = 'on';
        

        
        answer = questdlg('Proceed with the calibration?',...
            'Calibrate',...
            'Yes', 'No', 'Yes');
        
        switch answer
            case 'Yes'
                calibrate; 
        end
    end

    function browseForFile(src, event)
        [file,path,indx] = uigetfile( ...
            {'*.mp4',...
            'Video (*.mp4)'}, ...
            'Select a File');
        
        selectedFile = fullfile(path, file);
        selectedFileText.String = file;
        calibrateButton.Enable = 'on'; 
    end
end

function calibrate(src, event)
    global selectedFile
    global numOfImages
    global statusText
    global params
    global corners
    global worldPoints
    
    video = VideoReader(selectedFile);
    numFrames = video.NumFrames;

    % Sampe one frame every 60 from the video
    images = [];
    for i=1:60:numFrames
        progress = (i/numFrames)*100;
        statusText.String = sprintf('Step 1 of 3: Reading frames from video... %.1f%%', progress);
        temp = read(video, i);
        images = cat(4,images, temp);
    end
    
    statusText.String = 'Step 2 of 3: Detecing corners in the frames of the video...';
    pause(0.1);
    % Detect the pattern in the sampled frames
    [corners, boardSize, patternDetected] = detectCheckerboardPoints(images);
    numOfImages = size(corners,3);
    
    % Plot a scatter plot of the corner points distribution
    figure('Name', 'Chessboard corner points distribution');
    for i=1:numOfImages
        hold on;
        scatter(corners(:,1,i),corners(:,2,i), 50)
    end
    
    
    % ESTIMATE CAMERA PARAMETERS
    % --------------------------
    statusText.String = 'Step 3 of 3: Estimating camera parameters...';
    pause(0.1);
    squareSizeInMM = 22.4;
    
    % Generate a chessboard to use for reprojection
    worldPoints = generateCheckerboardPoints(boardSize,squareSizeInMM);
    
    %imageSize = [2176 3840];
    imageSize = [video.Height video.Width];
        
    params = estimateCameraParameters(corners,worldPoints, ...
        'ImageSize',imageSize, ...
        'EstimateSkew', true,...
        'NumRadialDistortionCoefficients', 3);
    
    statusText.String = 'Ready';
    
    figure('Name', 'Reprojection Errors');
    showReprojectionErrors(params);
    
    figure('Name', 'Estimated pattern 3D positions');
    showExtrinsics(params);
    
    answer = questdlg('Proceed with a non-linear refinement of the estimated parameters? \nWARNING: It can take hours.',...
        'Refine parameters',...
        'Yes', 'No', 'Yes');
    
    switch answer
        case 'Yes'
            nlRefine;
    end
end

function nlRefine(src, event)
    global numOfImages
    global statusText
    global params
    global rotationMatrices
    global translationVectors
    global worldPoints
    global corners
    
    statusText.String = 'Performing non-linear refinement...';
    
    cornerPoints = corners;

    temp = zeros(size(worldPoints,1),1);

    worldP = [worldPoints temp];
    intrinsics = params.Intrinsics;
    rotationMatrices = params.RotationMatrices;
    translationVectors = params.TranslationVectors;

    newRotations = zeros(3,numOfImages);
    newTranslations = zeros(numOfImages,3);

    for i=1:numOfImages
        newRotations(:,i) = rotm2eul(rotationMatrices(:,:,i));
    end

    plotFcns = {'optimplotfunccount', 'optimplotfval', 'optimplotstepsize'};
    options = optimoptions('fminunc', 'Algorithm', 'quasi-newton',...
        'PlotFcns', plotFcns, 'MaxIterations', 1000, 'MaxFunctionEvaluations', 1e10,...
        'UseParallel', false);
    [x, ~, ~, ~] = fminunc(@fun, [intrinsics.FocalLength ,...
        intrinsics.PrincipalPoint,...
        intrinsics.Skew,...
        newRotations(:)',...
        reshape(translationVectors',1,[])], options);

    f1 = x(1);
    f2 = x(2);
    ppx = x(3);
    ppy = x(4);
    skew = x(5);
    outputRotations = x(6:6+3*numOfImages-1);
    outputTranslations = x(6+3*numOfImages:end);


    % Run this part to plot
    % the optimized errors
    % -----------------------
    newIntrinsics = cameraIntrinsics([f1, f2], [ppx, ppy], [1080 1920], ...
        'RadialDistortion', intrinsics.RadialDistortion, ...
        'Skew', skew);

    errorPerImage = [];
    for i=1:numOfImages
        currentRotation = outputRotations((i-1)*3+1:i*3);
        currentTranslation = reshape(outputTranslations((i-1)*3+1:(i-1)*3+3),1,3);
        imagePoints = worldToImage(newIntrinsics, eul2rotm(currentRotation), ...
            currentTranslation, worldP, ...
            'ApplyDistortion', true);
% 
%         errorx = (imagePoints(:, 1) - cornerPoints(:, 1, i));
%         errory = (imagePoints(:, 2) - cornerPoints(:, 2, i));

        errorSum = 0;
        for j=1:size(imagePoints,1)
            error = norm((imagePoints(j, :)- cornerPoints(j,:,i)));
            errorSum = errorSum + error;
        end

        errorPerImage = [errorPerImage; errorSum/size(imagePoints,1)];
    end

    figure('Name', 'Mean Projection Error Per Image After Refinement');
    bar(errorPerImage, 'FaceColor', '#4DBEEE');
    title('Mean Projection Error Per Image After Refinement');
    hold on;
    p = plot(xlim, [mean(errorPerImage) mean(errorPerImage)], '--');
    hold off;
    legend([p], sprintf('Overal Mean Error: %.2f', mean(errorPerImage)));
    % -----------------------
    % Up to here

    function errorOutput = fun(x)
        %     [f1, f2, skew, ppx, ppy, r11, r12, r13, r21, r22, r23, r31, r32, r33, t1, t2, t3] = ...
        %         feval(@(y) y{:}, num2cell(x));

        f1 = x(1);
        f2 = x(2);
        ppx = x(3);
        ppy = x(4);
        skew = x(5);
        rotationMatrices = x(6:6+3*numOfImages-1);
        translationVectors = x(6+3*numOfImages:end);

        intr = cameraIntrinsics([f1, f2], [ppx, ppy], [1080 1920], ...
            'RadialDistortion', intrinsics.RadialDistortion, ...
            'Skew', skew);

        %errorPerImage = [];

        mseSum = 0;
        for i=1:numOfImages
            currentRotation = rotationMatrices((i-1)*3+1:i*3);
            currentTranslation = reshape(translationVectors((i-1)*3+1:(i-1)*3+3),1,3);

            imagePoints = worldToImage(intr, eul2rotm(currentRotation), ...
                currentTranslation, worldP, ...
                'ApplyDistortion', true);

            errorSum = 0;
            for j=1:size(imagePoints,1)
                error = norm((imagePoints(j, :)- cornerPoints(j,:,i)));
                errorSum = errorSum + error;
            end

            %errorPerImage = [errorPerImage; errorSum/size(imagePoints,1)];
            mseSum = mseSum + errorSum;
        end

        errorOutput = mseSum;
    end
end