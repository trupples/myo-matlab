classdef MyoUI < handle
    properties
        f   % figure
        wf  % Long waveform
        fwf % Frame waveform
        sp  % Spectrogram
        fsp % Frame spectrum
        interp % Interpreted signal
        spectrogramWidth % Number of "columns" in the spectrogram for each frame

        closed
    end
    methods
        function self = MyoUI(Vmin, Vmax, Fs, P, N, freqs, spectrogramWidth, freqinterval)
            self.f = figure('Name', 'Myoelectric measurements');

            self.spectrogramWidth = spectrogramWidth;

            gl = tiledlayout(2, 2);

            % Long waveform + interpreted signal
            ax = nexttile(gl);
            %ax.Layout.Row = 1;
            %ax.Layout.Column = 1;
            self.wf = plot(ax, linspace(-P, 0, Fs*P)', zeros(Fs*P, 1));
            axis(ax, [-P 0 Vmin, Vmax]);
            xlabel(ax, 't [s]');
            ylabel(ax, 'x [V]');
            title(ax, 'Waveform');
            hold(ax, 'on');
            self.interp = area(ax, repmat(linspace(-P, 0, Fs/N*P)', 1, 2), zeros(Fs/N*P, 2));
            legend(ax, 'x', 'RMS(x)', 'max(TK(x))');
            ylabel(ax, 'y');
            grid(ax, 'on');

            % Last frame waveform
            ax = nexttile(gl);
            %ax.Layout.Row = 1;
            %ax.Layout.Column = 2;
            self.fwf = plot(ax, linspace(-N/Fs, 0, N)', zeros(N, 1));
            axis(ax, [-N/Fs 0 Vmin Vmax]);
            xlabel(ax, 't [s]');
            ylabel(ax, 'x [V]');
            title(ax, 'Last frame waveform');
            grid(ax, 'on');

            % Long spectrogram
            ax = nexttile(gl);
            %ax.Layout.Row = 2;
            %ax.Layout.Column = 1;
            [X, Y] = meshgrid(linspace(-P, 0, Fs/N*P*spectrogramWidth), freqs);
            self.sp = pcolor(ax, X, Y, zeros(length(freqs), Fs/N*P*spectrogramWidth));
            self.sp.EdgeAlpha = 0;
            colormap(ax, viridis(256));
            axis(ax, [-P 0 min(freqinterval) max(freqinterval)]);
            xlabel(ax, 't [s]');
            ylabel(ax, 'f [Hz]');
            title(ax, 'Waterfall');
            grid(ax, 'on');

            % Last frame spectrogram
            freqsfft = Fs*(0:N/2)'/N;
            ax = nexttile(gl);
            %ax.Layout.Row = 2;
            %ax.Layout.Column = 2;
            self.fsp = semilogx(ax, ones(length(freqsfft), 1), freqsfft);
            axis(ax, [db2mag(-90) Vmax min(freqinterval) max(freqinterval)]);
            ticks = [-90, -60, -30, -12, 0, mag2db(Vmax)];
            xticks(ax, db2mag(ticks));
            xticklabels(ax, arrayfun(@(db) sprintf('%ddB', db), ticks, 'UniformOutput', false));
            %set(ax, 'YAxisLocation', 'right');
            ylabel(ax, 'f [Hz]');
            xlabel(ax, 'A [V]');
            title(ax, 'Last frame spectrum');
            grid(ax, 'on');

            self.closed = false;
        end

        function displayProcessedFrame(self, t, x, A, y)
        % DISPLAYPROCESSEDFRAME Update MyoUI with a new frame, consisting
        % of: a time vector |t|, a measured time-domain amplitude vector
        % |x|, a frequency-domain amplitude vector |A|, and an interpreted
        % measured value |y|.

            N = length(t);

            % Long waveform
            longt = [self.wf.XData(N+1:end), t'];
            self.wf.XData = longt;
            self.wf.YData = [self.wf.YData(N+1:end), x'];
            self.wf.Parent.XLim = [longt(1) longt(end)];

            % Interpreted signal
            for i = 1 : 2
                self.interp(i).XData = [self.interp(i).XData(2:end), mean(t)];
                self.interp(i).YData = [self.interp(i).YData(2:end), y(i)];
            end

            % Frame waveform
            self.fwf.XData = [self.fwf.XData t'];
            self.fwf.YData = [self.fwf.YData x'];
            self.fwf.Parent.XLim = [t(1) t(end)];
    
            % Spectrogram
            %self.sp.XData = [self.sp.XData(:,self.spectrogramWidth+1:end), repmat(t', size(Awl, 1), 1)];
            self.sp.XData = [self.sp.XData(:,self.spectrogramWidth+1:end), repmat(t(end), size(A, 1), 1)];
            self.sp.ZData = [self.sp.ZData(:,self.spectrogramWidth+1:end), A];
            self.sp.CData = [self.sp.CData(:,self.spectrogramWidth+1:end), A];
            self.sp.Parent.XLim = [self.sp.XData(1,1) t(end)];

            % Frame spectrum
            self.fsp.XData = A;

            drawnow;
        end

        function closed = isclosed(self)
            closed = self.closed;
        end

        function closeReq(self)
            self.closed = true;
        end
    end
end
