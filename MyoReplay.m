classdef MyoReplay < handle
    properties
        buft
        bufx
        pos
        last
    end
    methods
        function self = MyoReplay(filename)
            data = readmatrix(filename);
            self.buft = data(:,1) - data(1,1);
            self.bufx = data(:,2);
            self.pos = 1;
            self.last = tic;
        end

        function start(self, processFrame)
            
            while self.pos < length(self.buft)
                while toc(self.last) < 0.1
                    pause(0.001);
                end
                self.last = tic;
    
                i = self.pos;
                t = self.buft(i:i+1000-1);
                x = self.bufx(i:i+1000-1);
                self.pos = self.pos + 1000;
                processFrame(t,  x);
            end
        end

        function [x, t] = read(self)
            while toc(self.last) < 0.1
                pause(0.01);
            end
            self.last = tic;

            i = self.pos;
            t = self.buft(i:i+1000-1);
            x = self.bufx(i:i+1000-1);
            self.pos = self.pos + 1000;
        end
    end
end