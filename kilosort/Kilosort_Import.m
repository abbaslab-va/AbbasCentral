%This script asks you to choose the folder that your raw data is in. Then, 
%it runs a different import scrip[ depending upon which type of files it 
%detects in the chosen folder. It will currently choose between a Blackrock 
%and Whitematter import function (Neuropixels coming soon...).

ChosenExperiment = uigetdir('Choose a Folder'); %Pick the folder for the experiment you want to import
cd(ChosenExperiment)

files = dir(ChosenExperiment);

RemoveNoise = 1;

%Blackrock
if contains([files.name], '.ns6')

    [~,FolderName] = fileparts(ChosenExperiment);

    NS_6 = strcat(ChosenExperiment,'\',FolderName, '.ns6');
    if ~isempty(dir(fullfile(ChosenExperiment , '*.ns6'))) == 1
    openNSx(NS_6)
    end

    if RemoveNoise == 1

       RMS_Treshold = 5;

       [~, linear_index] = max(abs(NS6.Data(1:28,:)), [], 'all');
       [row, ~] = ind2sub([size(NS6.Data(1:28,:), 1), size(NS6.Data(1:28,:), 2)], linear_index);
       temp_noise_trace = NS6.Data(row, :);
       temp_rms = rms(temp_noise_trace);
       noise_peaks = find(abs(temp_noise_trace) > temp_rms*RMS_Treshold);
       noise_separation = find(diff(noise_peaks) > 20000);
       
       noisy_periods = {};
       
       if any(noise_peaks < 10001) 
                 
           n = find(noise_peaks < 10001, 1, 'last');
           Early_Noise = noise_peaks(n)-1;
           
       else
     
           n = 1;

       end

       for time = 1:length(noise_separation)+1

           if time <= length(noise_separation)
                    
              if exist('Early_Noise', 'var') == 1

                  noisy_periods{time} = noise_peaks(n)-Early_Noise:noise_peaks(noise_separation(time));
                  n = noise_separation(time)+1; 
                  clear Early_Noise

              elseif n >= 1

                  noisy_periods{time} = noise_peaks(n)-10000:noise_peaks(noise_separation(time))+10000;
                  n = noise_separation(time)+1; 

              end


           elseif time > length(noise_separation)
              
              if noise_peaks(end)+10000 > length(temp_noise_trace)

                  noisy_periods{time} = noise_peaks(n)-10000:noise_peaks(end);

              else

                noisy_periods{time} = noise_peaks(n)-10000:noise_peaks(end)+10000;

              end

              
           end
          
       end
       
       temp_columns = 1:1:length(NS6.Data);
       noisy_periods = cell2mat(noisy_periods);
       temp_columns(noisy_periods) = [];
       Data_noise_removed = NS6.Data(1:28, temp_columns);
%        Data_noise_removed = Data_noise_removed(1:28, :);      

       figure
       subplot(1,2,1)
       plot(temp_noise_trace)
       subplot(1,2,2)
       plot(Data_noise_removed(row,:))
 
       fileID = fopen('kilosort_Raw.bin', 'w');
       fwrite(fileID, Data_noise_removed, 'int16');
       fclose(fileID);
     
       clear NS6 noise_peaks temp_noise_trace RemoveNoise time temp_rms col n largest_value linear_index

    elseif RemoveNoise == 0

        % Converts raw (30 kHz), unfiltered blackrock data (NS.6 format) into a binary file
        % (kilosort_Raw.bin) used by kilosort to sort spikes. Then saves this file
        % to the current directory, which chould be the folder you chose
        
        kilosort_Raw = zeros(28, length(NS6.Data)); %#ok<PREALL>
        kilosort_Raw = NS6.Data(1:28, :); %This is currently set up assuming the 4 backmost holes on the Neuralynx 32 EIB are left open
        
        fileID = fopen('kilosort_Raw.bin', 'w');
        fwrite(fileID, kilosort_Raw, 'int16');
        fclose(fileID);
        
    end


%Whitematter ---- current geometry is set for the H6-64 channel dual shank cambridge probes

elseif contains([files.name], '.continuous')
    
    probe = [45 11 44 28 57 43 9 25 24 26 42 10 32 27 59 58 12 30 29 46 60 63 13 15 61 62 16 31 48 14 64 47 ...
        50 2 51 37 3 33 17 53 5 21 52 4 8 35 56 1 40 19 22 49 38 39 7 6 23 36 54 20 18 55 34 41];
    hs = [51 64 60 58 55 50 43 47 38 34 29 21 17 12 8 3 63 61 57 54 52 46 41 37 32 28 24 20 15 11 6 2 ...
        62 56 53 59 49 44 40 35 31 26 23 18 14 9 5 1 48 45 42 39 36 33 30 27 25 22 19 16 13 10 7 4];
    hs_probe = hs(probe);
    
    for channel = 0:63
    
        fid = fopen(strcat('100_HS_CH', num2str(channel), '.continuous'));
        hdr = fread(fid, 1024, 'char*1');
        
        n=1;
        while ~feof(fid)
            
            try
            timestamp = fread(fid, 1, 'int64',0,'l');
            N = fread(fid, 1, 'uint16',0,'l');
            recordingNumber = fread(fid, 1, 'uint16', 0, 'l');
            samples{n} = int16(fread(fid, N, 'int16',0,'b')');
            recordmarker = fread(fid, 10, 'char*1');
            n = n+1;
            catch
            end
        
        end
        
        kilosort_Raw(channel+1,:) = cell2mat(samples);
        kilosort_Raw(channel+1,:) = int16(kilosort_Raw(channel+1,:));
        fclose('all');
    
    end

    kilosort_Raw = kilosort_Raw(hs_probe, :);
    fileID = fopen('kilosort_Raw.bin', 'w');
    fwrite(fileID, kilosort_Raw, 'int16');
    fclose(fileID);    

    for channel = 0:1
    
        fid = fopen(strcat('102_PAI', num2str(channel), '.continuous'));
        hdr = fread(fid, 1024, 'char*1');
        
        n=1;
        while ~feof(fid)
            
            try
            timestamp = fread(fid, 1, 'int64',0,'l');
            N = fread(fid, 1, 'uint16',0,'l');
            recordingNumber = fread(fid, 1, 'uint16', 0, 'l');
            AnalogIn{n} = fread(fid, N, 'int16',0,'b')';
            recordmarker = fread(fid, 10, 'char*1');
            n = n+1;
            catch
            end
        
        end
        
        AnalogSignals(channel+1,:) = cell2mat(AnalogIn);
        fclose('all');
    
    end

end

% clear files
% save('AnalogSignals', "AnalogSignals")
save('NoisyPeriods', "noisy_periods", "RMS_Treshold", "temp_columns")
