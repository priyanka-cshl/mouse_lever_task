filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 2;

%% lever

% https://www.mathworks.com/help/signal/ug/take-derivatives-of-a-signal.html

trial_on = Traces.Trial{idx};
lever = Traces.Lever{idx};

Fs = 500;
t = 0:1/Fs:(length(lever)-1)/Fs;

figure;
pwelch(lever,[],[],[],Fs)

%% 

Nf = 50; 
Fpass = 20; 
Fstop = 40;

d = designfilt('differentiatorfir','FilterOrder',Nf, ...
    'PassbandFrequency',Fpass,'StopbandFrequency',Fstop, ...
    'SampleRate',Fs);

fvtool(d,'MagnitudeDisplay','zero-phase','Fs',Fs)

%% 

dt = t(2)-t(1);

velocity = filter(d,lever)/dt;

delay = mean(grpdelay(d));

tt = t(1:end-delay);
vd = velocity;
vd(1:delay) = [];

tt(1:delay) = [];
vd(1:delay) = [];

%%
[pkp,lcp] = findpeaks(lever);
zcp = zeros(size(lcp));

[pkm,lcm] = findpeaks(-lever);
zcm = zeros(size(lcm));

subplot(2,1,1)
plot(t,lever,t([lcp lcm]),[pkp -pkm],'or')
xlabel('Time (s)')
ylabel('Displacement (cm)')
grid

subplot(2,1,2)
plot(tt,vd,t([lcp lcm]),[zcp zcm],'or')
xlabel('Time (s)')
ylabel('Speed (cm/s)')
grid

%%

accel = filter(d,velocity)/dt;

at = t(1:end-2*delay);
ad = accel;
ad(1:2*delay) = [];

at(1:2*delay) = [];
ad(1:2*delay) = [];

subplot(2,1,1)
plot(tt,vd)
xlabel('Time (s)')
ylabel('Speed (cm/s)')
grid

subplot(2,1,2)
plot(at,ad)
ax = gca;
ax.YLim = 2000*[-1 1];
xlabel('Time (s)')
ylabel('Acceleration (cm/s^2)')
grid
