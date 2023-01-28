# Welcome to AbbasCentral!
This is the github repository for the Abbas Lab's framework for behavioral, neural, and video data processing.
The classes and functions are designed to be as flexible as possible, allowing the user to customize the inputs according to their specific needs. 
It contains functions for analyzing performance and positional data during behavior in freely moving mice, as well as processing and analyzing synchronous neural recordings. 

This software package makes several fundamental assumptions about your data organization that must be followed if you want full functionality:

* Data is organized heirarchically, with a single parent directory housing folders for each animal recorded during an experiment, each containing subfolders that house all of the data from individual experiments.

* A file called "config.ini" must be present in the root directory of your data folder that you select when you call the function select_experiment. This file can be blank, but it is used to indicate the relationship between the timestamp recieved by your acquisition system and the experimental time points they are marking. An example layout for this file is shown below:

```
[timestamps]
'Off' = 65528
'Trial Start' = 65529
'Laser On' = 65530
'Forage' = 65531
'Reward' = 65532
'Punish' = 65533
[experimenter]
'Experimenter' = 'Your name here'
```

* The above [timestamps] section contains key-value pairs, giving names to the numbered timestamps that can be used for indexing functions such as trialize_spikes. An example call:
    
    `trializedSpikes = trialize_spikes('Laser On', 2)`