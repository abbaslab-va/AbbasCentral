
function [Power]=PWR_FUN(lfp,ts,filterbank)

if class(ts)=="cell"
    ts=ts(~cellfun('isempty',ts));
    ts=cell2mat(ts); 
        if size(ts,2)==1
        else 
            ts=ts';
        end 
else 
end 

fs=30000;
norm=rms(lfp);
offset=2 ; %(inseconds);
for trial=1:length(ts)
    lfp_trial=downsample(lfp(ts(trial)-(offset*fs):ts(trial)+((offset*fs)-1)),15)./norm;
    [AS,f]=cwt(lfp_trial,'FilterBank',filterbank);
    Power(trial,:,:)=flip(abs(AS).^2,1);
   

%     cwt(lfp_trial,'FilterBank',filterbank);
%     pause()
%     close all

end 
if ~exist('Power')
    Power=0;
end 

Power=squeeze(mean(Power,1));

% surf(Power)
% view(2)
% shading interp


% for t=1:size(Power,1)
%     figure()
%     surf(squeeze(Power(t,:,:)))
%     view(2)
%     shading interp
%     yticks([1,21,35,52,63,70])
%     yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
%     ylabel('Power')
%     colorbar 
%     caxis([0 1])
%     pause()
%     close all
% end 