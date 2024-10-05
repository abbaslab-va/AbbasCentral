function [pwr, freqs, phase, lfpAll] = cwt_power(obj, varargin)

% Calculates the power of a signal using a continuous wavelet transform
% and returns the power and phase of the signal at the specified frequencies.
% OUTPUT:
%     pwr - a 1xC cell array of power values for each channel
%     freqs - a 1xC cell array of frequencies used in the cwt
%     phase - a 1xC cell array of phase values for each channel
% INPUT:
%     event - a string of a state named in the config file (required)
% optional name-value pairs:
%     > 'edges' - 1x2 vector distance from event on either side in seconds
%     > 'freqLimits' - a 1x2 vector specifying cwt frequency limits
%     > 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
%     > 'calculatePhase' - boolean specifying if phase should be calculated (default = true)
%     > 'trialType' - a trial type found in config.ini
%     > 'outcome' - an outcome character array found in config.ini
%     > 'offset' - a number that defines the offset from the alignment you wish to center around.

% default input values
defaultAveraged = false;
defaultPhase = false;
defaultSF = 2000;
validSF = @(x) isnumeric(x) && x > 0 && x < obj.info.baud;
validOutputOpts = {'quiet', 'verbose', 'q', 'v'};
validOutput = @(x) any(cellfun(@(y) strcmp(x, y), validOutputOpts));

% input validation scheme
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'calculatePhase', defaultPhase, @islogical);
addParameter(p, 'samplingFreq', defaultSF, validSF);
addParameter(p, 'outputStyle', 'quiet', validOutput)
addParameter(p, 'ChirpYes', defaultAveraged, @islogical)

parse(p, varargin{:});    
averaged = p.Results.averaged;
trialized = presets.trialized;
calculatePhase = p.Results.calculatePhase;
samplingFreq = p.Results.samplingFreq;
outputStyle = p.Results.outputStyle;
ChirpYes = p.Results.ChirpYes;
% set up filterbank and downsample signal
baud = obj.info.baud;
downsampleRatio = baud/samplingFreq;
sigLength = (presets.edges(2) - presets.edges(1)) * samplingFreq;
filterbank = cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency', samplingFreq, 'TimeBandwidth',60, 'FrequencyLimits',presets.freqLimits, 'VoicesPerOctave', 10);
try
    numChan = obj.info.numChannels;
catch 
    %warning('No channel num found (likely due to noPhy - setting to 32 (default value)).')
    numChan = 32;
end
%lfpAll = cell(1, numChan);
% timestamp and trialize event times
% if ChirpYes
%     eventTimes = obj.find_bpod_state('ChirpPlay','preset', presets, 'trialized', false)';
%     eventTimes=cellfun(@(x) cell2num(x{1}), eventTimes,'UniformOutput',false);
% 
% 
% else 
eventTimes = obj.find_event('preset', presets, 'trialized', false);
% end 

try
    edgeVec = round(presets.edges * baud) + eventTimes';
    edgeCells = num2cell(edgeVec, 2);
catch
    %pwr = [];
    phase = [];
    freqs = [];
    return
end
disp(numel(edgeCells))
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);

timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCells, 'uni', 0);
ns6_dir = dir(fullfile(parentDir, sub,'*.ns6'));
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, ns6_dir.name), x), timeStrings, 'uni', 0);
lfp = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);
clear NS6
%pwr = cell(1, numChan);
phase = cell(1, numChan);
freqs = cell(1, numChan);

lfpDownsampled = cellfun(@(x) downsample(x, downsampleRatio), lfp, 'uni', 0);
clear lfp


%% 
% find channels of object for 2 regions 
try
    acc_ch = obj.info.regions.PFC;
    cla_ch = obj.info.regions.CLA;
catch 
    acc_ch = obj.info.channels.PFC;
    cla_ch = obj.info.channels.CLA;
end

% calculate power and phase by channel... slow and yeilds the same results
% as averaging over channels first. So average over appropriate channels 

%check for bad sessions and channels 
if size(lfpDownsampled,1)<5
    clearvars pwr
    pwr.cla=[];
    pwr.acc=[];
    lfpAll.cla=[];
    lfpAll.acc=[];
    freqs=[];
    disp(obj.info.path)
    
else


%ACC power 
clearvars AS f
acc_lfp_check=cellfun(@(x) x(:,acc_ch), lfpDownsampled, 'uni',false);
acc_lfp_check=mean(reshape(cell2mat(acc_lfp_check),[size(acc_lfp_check{1}),numel(acc_lfp_check)]),3);

figure()
subplot(411)
for ch=1:numel(acc_ch)
    hold on
    plot(acc_lfp_check(:,ch))
   % pause()
end 

subplot(413)
correlation_matrix = corr(acc_lfp_check);
mean_correlations = mean(correlation_matrix - diag(diag(correlation_matrix)),2);
imagesc(correlation_matrix);
colorbar;
title(num2str(mean_correlations));


% Step 3: Set a threshold for outliers (e.g., channels with mean correlation < 0.5)
threshold = 0.35; % Adjust this based on your dataset
outlier_channels = find(mean_correlations < threshold);
nocs_acc = setdiff(acc_ch, acc_ch(outlier_channels));

if isempty(nocs_acc)
acc_pwr=[]; 
acc_lfp=[];
freqs=[];
else   

acc_lfp=cellfun(@(x) mean(x(:,nocs_acc),2), lfpDownsampled, 'uni',false);
[AS, f] = cellfun(@(x) cwt(x, 'FilterBank', filterbank), acc_lfp, 'uni', 0);
AS = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
acc_pwr=mean(reshape(cell2mat(AS'),[size(AS{1}),numel(AS)]),3);
end 

%CLA power

clearvars AS f
cla_lfp_check=cellfun(@(x) x(:,cla_ch), lfpDownsampled, 'uni',false);
cla_lfp_check=mean(reshape(cell2mat(cla_lfp_check),[size(cla_lfp_check{1}),numel(cla_lfp_check)]),3);

subplot(412)
for ch=1:numel(cla_ch)
    hold on
    plot(cla_lfp_check(:,ch))
   % pause()
end 

subplot(414)
correlation_matrix = corr(cla_lfp_check);
mean_correlations = mean(correlation_matrix - diag(diag(correlation_matrix)),2);
imagesc(correlation_matrix);
colorbar;
title(num2str(mean_correlations));


% Step 3: Set a threshold for outliers (e.g., channels with mean correlation < 0.5)
threshold = 0.35; % Adjust this based on your dataset
outlier_channels = find(mean_correlations < threshold);
nocs_cla = setdiff(cla_ch, cla_ch(outlier_channels));

clearvars AS f 
if isempty(nocs_cla)
cla_pwr=[]; 
freqs=[];
cla_lfp=[];
else   

cla_lfp=cellfun(@(x) mean(x(:,nocs_cla),2), lfpDownsampled, 'uni',false);
[AS, f] = cellfun(@(x) cwt(x, 'FilterBank', filterbank), cla_lfp, 'uni', 0);
AS = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
cla_pwr=mean(reshape(cell2mat(AS'),[size(AS{1}),numel(AS)]),3);

end 
% 
% figure()
% surf(acc_pwr)
% yticks([1:70])
% yticklabels(freqs)
% view(2)
% shading interp
% colorbar
% 
% figure()
% surf(cla_pwr)
% yticks([1:70])
% yticklabels(freqs)
% view(2)
% shading interp
% colorbar

% parfor c = 1:numChan
%     [AS, f] = cellfun(@(x) cwt(x(:, c), 'FilterBank', filterbank), lfpDownsampled, 'uni', 0);
%     if calculatePhase
%         chanPhase = cellfun(@(x) flip(angle(x), 1), AS, 'uni', 0);
%         chanPhase = cat(3, chanPhase{:});
%         phase{c} = chanPhase;
%     end
%     freqs{c} = flip(f{1});
%     AS = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
%     % clear AS
%     pwr{c} = single(cat(3, AS{:}));
%     if strcmp(outputStyle, 'verbose')
%         disp(num2str(c))
%     end
% end 


% if averaged
%     pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
%     phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
%     lfpAll = cellfun(@(x) mean(cell2mat(x)), lfpAll, 'uni', 0);
%     trialized = false;
% end


% if trialized
%     pwrMat = cat(4, pwr{:});
%     clear pwr
%     pwrReshape = num2cell(pwrMat, [1 2 4]);
%     clear pwrMat
%     pwr = squeeze(cellfun(@(x) squeeze(x), pwrReshape, 'uni', 0));
% end

if strcmp(outputStyle, 'verbose')
    disp(obj.info)
end

%clearvars pwr
pwr.cla=cla_pwr;
pwr.acc=acc_pwr;
lfpAll.acc=acc_lfp;
lfpAll.cla=cla_lfp;
if exist('f','var')
    freqs = flip(f);
else 
   freqs=[]; 
end 
disp(obj.info.path)

end 








