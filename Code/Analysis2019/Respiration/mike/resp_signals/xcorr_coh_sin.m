a = 0:0.1:20;

x = sin(a);
y = sin(a+1);

figure; hold on;
plot(a,x,'b');
plot(a,y,'r');

[r,lags] = xcorr(x, y, 'normalized');

figure;
plot(lags, r);

figure;
mscohere(x,y);