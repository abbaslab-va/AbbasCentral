cd E:\Behavior\Laser
matdir = dir('*.mat');
for file = 1:numel(matdir)
    sessName = matdir(file).name;
    if strfind(sessName, "Nested")
        figTitle = "Nested";
    elseif strfind(sessName, "Pulsatile")
        figTitle = "Pulsatile";
    else
        figTitle = "Sine";
    end
    load(matdir(file).name)
    bpod_sankey(SessionData)
    set(gcf, 'Position', get(0, 'ScreenSize'));
    title(figTitle)
end