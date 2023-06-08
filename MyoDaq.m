classdef MyoDaq < handle
    properties
        d
        N
        lastt
        T
        tt
    end
    methods
        function self = MyoDaq(Fs, N)
            dl = daqlist("ni"); % All connected NI devices
            if isempty(dl)
                error("No connected device");
            end
            di = dl{1, "DeviceInfo"};
            assert(di.Model == "NI ELVIS II" || di.Model == "NI ELVIS II+"); % Double check :)
            devid = di.ID; % Get its id
            fprintf('Connected to %s, %s\n', di.Model, devid);
            
            d = daq("ni");
            d.Rate = Fs;
            addinput(d, devid, "ai0", "Voltage");
           % addoutput(d, devid, "ao0", "Voltage");

            self.d = d;
            self.N = N;
            self.lastt = 0;
            self.T = N / Fs;
        end

        function start(self, processFrame)
            self.d.ScansAvailableFcn = @(d, ~) saf(self, d, processFrame);
            self.d.ScansAvailableFcnCount = self.N;
            start(self.d, "continuous");

            self.tt = tic;
        end

        function stop(self)
            stop(self.d);
        end

        function [x, t] = read(self)
            [x, t, ~] = read(self.d, self.N, "OutputFormat", "Matrix");
        end

        function saf(self, d, hnd)
            while d.NumScansAvailable >= self.N
                data = read(d, self.N);
                t = seconds(data.Time);
                x = data.Variables;
                y = hnd(t, x);
                %write(d, pwm(y, self.N));
                write(d, ones(self.N, 1) * y); % The board itself handles PWM generation

                % Compare real time to measurement time to see how much the
                % processing is lagging behind the measurements
                ttt = toc(self.tt);
                fprintf('Lagging %fs\n', ttt - t(end));
            end
        end
    end
end