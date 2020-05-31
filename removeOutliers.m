%% Removes outlier data by the number of outlierish condition indicators and measuring conditions
    %
    %   indicatorsTable - input data.
    %       Must be table with first 4 columns measuring conditions
    %
    %   minNum_Outliers - input int.
    %       Must be integer. How many condition indicators must be outliers to
    %       remove data row
function [indicatorsTable_RmOut, countRm_all, countRm_bin] = removeOutliers(indicatorsTable, option)
    arguments
        indicatorsTable table
        option.minNumOutliers int8 {mustBePositive(option.minNumOutliers)} = 3
    end

    while true
        try
            measurements_per_speed = double(input('\n Num. of measurements per same speed (Number MUST be the same as measurements_per_speed in the acquireData function to work properly \n'))
            break
        catch
            warning('Problem using function.  Assigning a value of 0.');
        end
    end

    % Initialization
    countRm_all = 0;
    countRm_bin = [];
    indicatorsTable_RmOut = table();

    % Removal process
    for i = 1:measurements_per_speed:height(indicatorsTable)
        data = indicatorsTable(i:i+(measurements_per_speed-1),:);
        [~ , TF] = rmoutliers(data{:,5:49}, 'MinNumOutliers',option.minNumOutliers);
        countRm_all = countRm_all + sum(TF);
        countRm_bin = [countRm_bin; sum(TF)];
        indicatorsTable_RmOut = [indicatorsTable_RmOut; data(~TF,:)];
    end
end