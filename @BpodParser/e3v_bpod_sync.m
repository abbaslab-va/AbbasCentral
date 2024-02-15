function frameTimes = e3v_bpod_sync(obj)
% 
% This method returns frame times relative to the Bpod State Machine internal clock for a video
% recorded using the e3vision watchtower on the whitematter pc.
%
% OUTPUT:
%     frameTimes - a 1xF vector of frame times, where F is the number of frames