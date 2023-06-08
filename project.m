clear;
close all;

%% Parameters

Fs = 10000;
P = 5;
FPS = 10;
N = Fs / FPS;
T = 1 / FPS;

Q = 20;
bw = 50 / Fs * 2 / Q;
[b, a] = iircomb(Fs / 50, bw, 'notch');

global filtstate;
filtstate = a(2:end) * 0;

ui = MyoUI(-5, 5, Fs, P, N, Fs*(0:N/2)'/N, 1, [10 500]);

%d = MyoDaq(Fs, N);
d = MyoReplay('myo 2023-04-24 dorsal middle finger pulse then slow.csv');

pause;

tic
start(d, @(t, x) processFrame(t, x, ui, N, d, a, b));

function y = processFrame(t, x, ui, N, d, fila, filb)
    global filtstate;
    toc;
    tic

    [x, filtstate] = filter(filb, fila, x, filtstate);
    
    Y = fft(x);
    A = abs(Y / N);
    A = A(1:N/2+1);
    A(2:end) = 2 * A(2:end);

    tk = x(2:end-1).^2 - x(1:end-2) .* x(3:end);
    ytk = max(tk);

    y = [rms(x); ytk];

    if ~ishandle(ui.f)
        disp('CLOSED');
        stop(d);
        return;
    end
    displayProcessedFrame(ui, t, x, A, y);
end
