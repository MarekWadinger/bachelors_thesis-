%% Feature extraction from vibratory data in form of timetables
function indicatorsTable = extractFeatures(raw_data)
    arguments
        raw_data table
    end

    % Initialization of workspace
    %Fs = 2500;            % Sampling frequency
    L = 2500;             % Length of signal in samples

    % Preallocate - not compusory but speeds up program a bit
    % MUST CHANGE NUM OF COLUMNS  ACCORDING TO NUM OF INDICATORS
    indicatorsArray  = zeros(height(raw_data), 48);

    % Iterative process of computing condition indicators
    for num_measurement = 1:height(raw_data)

        % Acquire and rescale data from accelboard
        X = [raw_data.Vibration_X{num_measurement}.Var1, raw_data.Vibration_Y{num_measurement}.Var1, raw_data.Vibration_Z{num_measurement}.Var1];

        eng_id = raw_data.Engine_ID(num_measurement);
        speed_level = raw_data.Power(num_measurement);
        mounted = raw_data.Mounted(num_measurement);

        % FFT
        Y = fft(X);
        P2 = abs(Y/L);  % Normalized two-sided spectrum
        P1 = P2(1:L/2+1,1:3); % Prva hodnota je divna a vynechavame ju, L/2?
        P1(2:end-1) = 2*P1(2:end-1);

        indicatorsArray(num_measurement, :) = [eng_id speed_level mounted std(X) rms(X)./mean(abs(X)) rms(X) mean(X) skewness(X) kurtosis(X) peak2rms(X) std(P1) rms(P1)./mean(abs(P1)) rms(P1) mean(P1) skewness(P1) peak2peak(P1) peak2rms(P1) max(P1)];

    end

    % Create table and add variable names
    indicatorsTable = [table(raw_data.Time) array2table(indicatorsArray)];
    indicatorsTable.Properties.VariableNames = {'Time', 'Engine_ID', 'Power', 'Mounted'...
        'std_x', 'std_y', 'std_z', ...
        'shapefactor_x', 'shapefactor_y', 'shapefactor_z', ...
        'rms_x', 'rms_y', 'rms_z', ...
        'mean_x', 'mean_y', 'mean_z', ...
        'skewness_x', 'skewness_y', 'skewness_z', ...
        'kurtosis_x', 'kurtosis_y', 'kurtosis_z', ...
        'peaktorms_x', 'peaktorms_y', 'peaktorms_z', ...
        'fd-std_x', 'fd-std_y', 'fd-std_z', ...
        'fd-shapefactor_x', 'fd-shapefactor_y', 'fd-shapefactor_z', ...
        'fd-rms_x', 'fd-rms_y', 'fd-rms_z', ...
        'fd-mean_x', 'fd-mean_y', 'fd-mean_z', ...
        'fd-skewness_x', 'fd-skewness_y', 'fd-skewness_z', ...
        'fd-peak2peak_x', 'fd-peak2peak_y', 'fd-peak2peak_z', ...
        'fd-peaktorms_x', 'fd-peaktorms_y', 'fd-peaktorms_z', ...
        'fd-max_x', 'fd-max_y', 'fd-max_z'};
    
    for num_measurement = 1:height(indicatorsTable)
        indicatorsTable.Class(num_measurement) = categorical(cellstr(sprintf('p%im%.2f\n',indicatorsTable.Power(num_measurement),indicatorsTable.Mounted(num_measurement))));
    end
    
end
