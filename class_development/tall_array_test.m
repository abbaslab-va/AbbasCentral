%% Create txt file from ns6 data
cd('E:\Ephys\Test')
fileName = 'testVertLong.txt';
if ~exist('NS6', 'var')
    openNSx('*.ns6')
end
fid = fopen(fileName, 'wt');
for ii = 1:size(datVert, 1)
    fprintf(fid, '%d, ', datVert(ii, :));
    fprintf(fid, '\n');
end
fclose(fid)

%% Create datastore from txt file and make tall array

ds = datastore(fileName);
tt = tall(ds);

%%
