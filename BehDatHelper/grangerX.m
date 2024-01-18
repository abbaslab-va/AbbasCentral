function [x2yS,y2xS,x2yT,y2xT]=grangerX(data,srate,frex,varargin)
% GRANGERX Compute temporal and spectral Granger causality estimates
%
% Usage:
%  [x2yS,y2xS,x2yT,y2xT]=grangerX(data,srate,frex)
%
% Inputs:
%   data    - [chans x time x trial] EEG data (must be 2 channels)
%   srate   - sampling rate in Hz
%   frex    - list of frequencies (enter [] for only time-domain computation)
%
% Optional inputs:
%   win     - window length (default value: ~200 ms)
%   order   - AR model order (default value: ~4 ms)
%
% Outputs:
%   x2yS, y2xS - estimated causality over time/frequency
%   x2yT, y2xT - estimated causality over time

% written from Mike X Cohen (mikexcohen@gmail.com)

%% setup and initialize
if isempty(varargin)
    win=round(200/(1000/srate));
    order=round(4/(1000/srate));
end

if length(varargin)==1
    win=varargin{1};
    order=round(4/(1000/srate));
end

if length(varargin)==2
    win=varargin{1};
    order=varargin{2};
end

if size(data,1)~=2, error('Data must have two channels (first dimension)!'); end

x2yT=zeros(1,size(data,2)-win);
y2xT=zeros(1,size(data,2)-win);
x2yS=zeros(length(frex),size(data,2)-win);
y2xS=zeros(length(frex),size(data,2)-win);

%% go!
for timei=1:size(data,2)-win
    
    % data from all trials in this time window
    tempdata=reshape(data(:,timei:timei+win-1,:),2,win*size(data,3));
    
    %% fit AR models (model estimation from bsmart toolbox)
    [Ax,Ex] = armorf(tempdata(1,:),size(data,3),win,order);
    [Ay,Ey] = armorf(tempdata(2,:),size(data,3),win,order);
    [Axy,E] = armorf(tempdata     ,size(data,3),win,order);
    
    % corrected covariance (for spectral analysis)
    eyx = E(2,2) - E(1,2)^2/E(1,1); 
    exy = E(1,1) - E(2,1)^2/E(2,2);
    N = size(E,1);
    
    %% time-domain causal estimate
    y2xT(timei)=log(Ex/E(1,1));
    x2yT(timei)=log(Ey/E(2,2));
    
    %% get the power spectrum from these data
    if ~isempty(frex)
        for fi=1:length(frex)

            H = eye(N); % identity matrix
            for m = 1:order
                H = H + Axy(:,(m-1)*N+1:m*N)*exp(-1i*m*2*pi*frex(fi)/srate);
            end
            H = inv(H);
            S = H*E*H'/srate;

            % compute causal gain from taking other variable's past into account
            y2xS(fi,timei) = log(abs(S(1,1))/abs(S(1,1)-(H(1,2)*eyx*conj(H(1,2)))/srate)); %Geweke's original measure
            x2yS(fi,timei) = log(abs(S(2,2))/abs(S(2,2)-(H(2,1)*exy*conj(H(2,1)))/srate));
        end
    end
end

%bananas=3;