function vibratory_data = acquireData(mounted, engine_id,measurements_per_speed, option)
    arguments
        mounted (1,1) double {mustBeNumeric,mustBeReal}
        engine_id (1,1) int8 {mustBeNumeric,mustBeReal}
        measurements_per_speed (1,1) int8 {mustBeNumeric,mustBeReal}
        option.WarmUp logical = false
        option.Plot logical = false
    end

% Initialization of workspace
delete(instrfindall);
table_row = 0;
names = ['X','Y','Z'];

% Open communication
a = AccelBoard('COM3');
stop(a.Timer);

% Motor warm up
if option.WarmUp == true
    disp('Warming up...')
    setMotorSpeedPerc(a,100)
    pause(180);
    setMotorSpeedPerc(a,0)
    pause(5);
end

% Preallocate table (without preallocation +10 seconds for 2000 measurements)
vibratory_data = array2table(zeros(length(100:-10:100)*length(1:measurements_per_speed),7), 'VariableNames',{'Time','Engine_ID','Power','Mounted','Vibration_X','Vibration_Y','Vibration_Z'} );
vibratory_data.Time = string(vibratory_data.Time);
vibratory_data.Vibration_X = num2cell(vibratory_data.Vibration_X);
vibratory_data.Vibration_Y = num2cell(vibratory_data.Vibration_Y);
vibratory_data.Vibration_Z = num2cell(vibratory_data.Vibration_Z);  

% Sets motor speed in %
for motor_speed = 100:-10:10
    
    % Sets motor speed according to loop setting
    setMotorSpeedPerc(a,motor_speed)
    text = ['Measuring at the power lvl of: ', num2str(motor_speed),'...'];
    disp(text)
    
    % Waits for approximate time in seconds untill signal gets steady
    pause(4);
    
    % Sets number of measurements for each motor speed
    for num_measurements = 1:measurements_per_speed
        table_row = table_row+1;
        
        % Break between measurements
        pause(1);
        
        % Acquire and rescale data from accelboard
        [x,y,z,t] = a.getData;
        X = rescale([x,y,z],-5,5,'InputMin',0,'InputMax',600);
        
        % Plot time domian vibratory data
        if option.Plot == true
            figure(1)
            for h = 1:3
                subplot(3,1,h)
                plot(t,X(:,h))
                title(sprintf('Axis %s in the Time Domain. Power lvl: %.2f V', names(h),motor_speed))
            end
        end
        
        % Apend table with currently measured data
        vibratory_data.Time(table_row) = convertCharsToStrings(datestr(now));
        vibratory_data.Engine_ID(table_row) = engine_id;
        vibratory_data.Power(table_row) = motor_speed;
        vibratory_data.Mounted(table_row) = mounted;
        vibratory_data.Vibration_X(table_row) = {array2timetable(X(:,1),'SampleRate',2500)};
        vibratory_data.Vibration_Y(table_row) = {array2timetable(X(:,2),'SampleRate',2500)};
        vibratory_data.Vibration_Z(table_row) = {array2timetable(X(:,3),'SampleRate',2500)};
        
    end
    
    % Wait until DC motor cools down a bit
    if motor_speed > 10
        disp('Cooling down...')
        setMotorSpeedPerc(a,0)
        pause(120)
    end
end

% Stop motor and close session
setMotorSpeedPerc(a,0)
a.close

% Save as .mat
filetime = datestr(now,'yyyymmmdd_HHMMSS');
if vibratory_data.Power(1) == 100
    orderspeed = 'des';
else
    orderspeed = 'asc';
end
save(sprintf('%s_ID-%i_mnt-%s_%s.mat',filetime, engine_id, num2str(mounted), orderspeed),'vibratory_data')

end