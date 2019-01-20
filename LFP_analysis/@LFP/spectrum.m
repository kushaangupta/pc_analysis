function spectrum(obj,win,range)
% generate time-frequency spectrum
% win: Hamming window length in seconds (default 1 min)
% range: 2 elements vector defining the beginning and end of the time
%        window for extraction

if nargin < 2
    win=60;
end
if nargin < 3
    range=[obj.t(1) obj.t(end)];
end

wdw=win*obj.fs;
nol=floor(.5*wdw);
nfft = max([obj.nfft 2^nextpow2(wdw)]);
f = 0:obj.fs/nfft:obj.fs/2; %estimate to Nyquist

lfp=obj.lfp(obj.t>=range(1) & obj.t<=range(2));

[spec,~,t]=spectrogram(lfp,wdw,nol,nfft,obj.fs);
spec=log(abs(spec));

obj.spec.spectrum = spec;
obj.spec.t = t;
obj.spec.f = f;