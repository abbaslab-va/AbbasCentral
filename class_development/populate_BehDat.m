function sessObj = populate_BehDat(sessPath, n)
%This function will create a behavioral object that contains all neural and 
%behavioral data for the recorded behavioral sesison.
cd(sessPath)
try
    load('SessionData.mat', 'SessionData')
catch
    warning('No Bpod session named SessionData.mat found in %s', sessPath)
end

[~,FolderName] = fileparts(sessPath);   

NEV_file = strcat(sessPath,'\',FolderName, '.nev');
if ~isempty(dir(fullfile(sessPath , '*.nev')))
    NEV=openNEV(NEV_file);
end

sf = NEV.MetaTags.SampleRes;
numSamples = NEV.MetaTags.DataDuration;

timestamps = adjust_timestamps(NEV, SessionData.nTrials);

spikeStruct = get_spike_info(sessPath);

%For LFP
% NS_6 = strcat(sessPath,'\',FolderName, '.ns6');
% if ~isempty(dir(fullfile(sessPath , '*.ns6')))
%     openNSx(NS_6)
% end

sessObj = BehDat(n, sf, numSamples, spikeStruct, [], [], timestamps, SessionData);

