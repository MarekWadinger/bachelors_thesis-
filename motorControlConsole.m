%% Find port 
instrfindall

%% Start connection on mac
a = AccelBoard('/dev/cu.usbmodem14101');

%% Start connection on windows
a = AccelBoard('COM3');

%% Remove opened connections
delete(instrfindall)

%% Set motor speed
setMotorSpeedPerc(a,0)

%% Start timer that computes fast fourier transforation (FFT) of vibratory data every second
start(a.Timer);

%% Stop timer
stop(a.Timer);

%% Compute FFT manually
a.computeFFT

%% Close connection
a.close

%%
diagnosticFeatureDesigner

%%
classificationLearner
