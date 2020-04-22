pause on

picture_interval = 1; %in seconds
picture_name = "img";
n_pictures = 5;

camList = webcamlist
cam = webcam(1)
preview(cam);

for i = 1:n_pictures
    img = snapshot(cam);
    image(img);
    imwrite(img,picture_name+i+".png");
    pause(picture_interval)
end
clear cam


