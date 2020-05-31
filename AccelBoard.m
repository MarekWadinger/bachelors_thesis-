classdef AccelBoard < handle
    
    properties
        Port
        Serial
        RawBins
        Bins = struct('x',[],'y',[],'z',[])
        Data = struct('x',[],'y',[],'z',[])
        BytesCount
        BinsToRead
        Timer
    end
    
    properties (Constant)
        BAUD_RATE = 115200
        BIN_SIZE = 250
        FREQ = 2500
        SIGNAL_LENGHT = 2500 % Length of signal in samples
        SIGNALS = 3
        BYTES_PER_SAMPLE = 2
        NUM_OF_BINS = 10
        MODE = 'byte'
        TIMER_PERIOD = 2
        NAMES = {'x','y','z'}
    end
    
    methods
        
        function obj = AccelBoard(port)
            obj.BytesCount = obj.BIN_SIZE*obj.BYTES_PER_SAMPLE*obj.SIGNALS;
            obj.Port = port;
            obj.initSerialObj();
            obj.initTimer();
            obj.connect();
            obj.Data.t = (0:1/obj.FREQ:1/obj.FREQ*obj.BIN_SIZE*obj.NUM_OF_BINS-1/obj.FREQ)';
            pause(1.5+1/obj.FREQ*obj.BIN_SIZE*obj.NUM_OF_BINS);
            obj.BinsToRead = obj.NUM_OF_BINS;
            obj.requestData();
            start(obj.Timer);
        end
        
        function [x,y,z,t] = getData(obj)
            x = obj.Data.x;
            y = obj.Data.y;
            z = obj.Data.z;
            t = obj.Data.t;
        end
        
        function setMotorSpeedPerc(obj,speed)
            if(speed>100)
                speed = 100;
            elseif(speed<0)
                speed = 0;
            end
            speedInt = round(speed);
            fprintf(obj.Serial,'<M:%d>',speedInt);
        end
        
        function connect(obj)
            fopen(obj.Serial);
        end
        
        function close(obj)
            obj.setMotorSpeedPerc(0);
            fclose(obj.Serial);
            stop(obj.Timer);
        end
        
        function computeFFT(obj)
            disp('computing FFT ...');
            if ~isempty(obj.Data.x)
                x = obj.Data.x;
                y = obj.Data.y;
                z = obj.Data.z;
                t = obj.Data.t;
                X = rescale([x,y,z],-5,5,'InputMin',0,'InputMax',600);
                Y = fft(X);
                P2 = abs(Y/obj.SIGNAL_LENGHT);  % aka hodnota odpoveda frekvencii
                P1 = P2(1:obj.SIGNAL_LENGHT/2+1,1:3);
                P1(2:end-1) = 2*P1(2:end-1);
                f = obj.FREQ*(0:(obj.SIGNAL_LENGHT/2))/obj.SIGNAL_LENGHT;
%                 figure(1)
%                 for i = 1:3                   
%                     subplot(3,1,i)
%                     semilogx(f(:),(P1(:,i)),'color',rand(1,3))
%                     [pks(:,i),locs(:,i)] = findpeaks(P1(:,i), f, 'SortStr','descend','NPeaks',8, 'MinPeakDistance',100);
%                     hold on
%                     semilogx(locs(:,i), pks(:,i), '^r', 'MarkerFaceColor','r')
%                     hold off
%                     xlim([5 inf])
%                     xlabel('f (Hz)')
%                     ylabel('Magnitude')
%                     title(['Single-Sided Megnitude Spectrum of ',obj.NAMES(i),'(t)'])
%                 end
                
                figure(2)                
                for i = 1:3                    
                    subplot(3,1,i)
                    plot(t,X(:,i))
                end
            end
        end
        
    end
    
   
    methods (Access = private)
              
        function initSerialObj(obj)
            obj.Serial = serial(obj.Port);
            set(obj.Serial, 'InputBufferSize', obj.BytesCount);
            set(obj.Serial, 'BaudRate', obj.BAUD_RATE);
            set(obj.Serial, 'BytesAvailableFcnCount', obj.BytesCount);
            set(obj.Serial, 'BytesAvailableFcnMode', obj.MODE);
            set(obj.Serial, 'BytesAvailableFcn', @(~,~)obj.readData());
        end
        
        function initTimer(obj)
            obj.Timer = timer;
            set(obj.Timer, 'ExecutionMode', 'fixedRate');
            set(obj.Timer, 'Period', obj.TIMER_PERIOD);
            set(obj.Timer, 'TimerFcn', @(~,~) obj.computeFFT());
        end
        
        function readData(obj)
            obj.RawBins = fread(obj.Serial, obj.SIGNALS*obj.BIN_SIZE, 'uint16');
            obj.processData();
        end
        
        function processData(obj)
            idx = 1;
            bin = obj.NUM_OF_BINS-obj.BinsToRead+1;
            for i = 1 : 3 : obj.BIN_SIZE*obj.SIGNALS
                obj.Bins.x(idx,bin) = obj.RawBins(i);
                obj.Bins.y(idx,bin) = obj.RawBins(i+1);
                obj.Bins.z(idx,bin) = obj.RawBins(i+2);
                idx = idx+1;
            end
            obj.BinsToRead = obj.BinsToRead-1;
            if obj.BinsToRead > 0
                obj.requestData();
            else
                obj.processBins();
                obj.BinsToRead = obj.NUM_OF_BINS;
                obj.requestData();
            end
        end
        
        function processBins(obj)
            obj.Data.x = obj.Bins.x(:);
            obj.Data.y = obj.Bins.y(:);
            obj.Data.z = obj.Bins.z(:);
        end
        
        function requestData(obj)
            fprintf(obj.Serial,'<P:1>');
        end
        
    end
    
end