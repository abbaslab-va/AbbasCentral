# Welcome to AbbasCentral!
This is the Github repository for the Abbas Lab's framework for behavioral, neural, and video data processing.
The classes and functions are designed to be as flexible as possible, allowing the user to customize the inputs according to their specific needs. 
It contains functions for analyzing performance and positional data during behavior in freely moving mice, as well as processing and analyzing synchronous neural recordings. 

## Code standards

Below you can find guidelines to adhere to when writing new methods or changing existing ones that, when followed, will help to keep this codebase as readable and consistent as possible.

### Class interfaces
* All methods should have a function header in the class interface. 
* Methods should be defined in separate files for large classes where it would be unwieldy to define them all in the class interface file
* Maintain single line spacing between methods and keep them organized by function
* "Friend" functions like plots can be kept in the class interface, commented out

### Naming
* Variables should be named in camel case (i.e. myVariable)
* Functions should be all lower case with underscores (i.e. my_function())
* Classes should use pascal case (i.e. MyClass)
* Dot syntax is preferred for object methods (i.e. myObject.my_method())

### Documentation
* All functions should have a function header with a description of the function, inputs, and outputs
* All new methods should be updated in this readme file to match their function headers
* Comments should be used to explain the reasoning behind any non-obvious code

## Data organization
This software package makes several fundamental assumptions about your data organization that must be followed if you want full functionality for the BehDat and ExpManager classes:

1) Data is organized heirarchically, with a single parent directory housing folders for each animal recorded during an experiment, each containing subfolders that house all of the data from individual experiments. Within each individual session folder, there should be at minimum a .NS6, .NEV, cluster_info.tsv, and spike_times.npy file.

2) A file called "config.ini" must be present in the root directory of your experiment folder that you select when you call the function select_experiment. This file is used to indicate the relationship between the timestamp recieved by your acquisition system and the experimental time points they are marking, as well as information about electrode regions and task-specific information like trial types, outcomes, and stim types for experiments with optogenetics.

3) The experiment is trialized, with a trial start timestamp sent by the Bpod system at the beginning of each trial. This timestamp should be called "Trial Start" in the config.ini file (no quotes - see example below). Open-field experiments with no trials are also supported, although it is recommended to at least use TTL inputs to the Blackrock acquisition system to timestamp points of interest in the experiment. 

### config.ini   
An example layout for this file is shown below. While there must be a timestamp called Trial Start for trialized experiments, the remaining information in this example should be rewritten in your experiment to match those parameters.

```
[info]
Experimenter = Your name here
StartState = Name of the bpod state that sends the Trial Start Timestamp


[timestamps]
Off = 65528
Trial Start = 65529
Laser On = 65530
Forage = 65531
Reward = 65532
Punish = 65533

[regions]
PFC = [1:25, 27, 29, 31]
NACC = 26
MD = 28
VTA = 30
VHIP = 32

[trialTypes]
Left = 1
Right = 2

[outcomes]
Correct = 1
Incorrect = 0

[stimTypes]
No Stim = 0
Sample 1 = 1
Delay 1 = 2
Sample 2 = 3
Delay 2 = 4
```

* The above [timestamps] section contains key-value pairs, giving names to the numbered timestamps that can be used for indexing functions such as trialize_spikes or find_event. An example call:
    
    `trializedSpikes = obj.trialize_spikes('Trial Start');`

    `ts = obj.find_event('event', Forage', 'trialType', 'Left', 'outcomes', 'Correct');`

* The [regions] section indicates the relationship between electrode channels and implanted regions, which can be used to examine neurons from a certain region or specific relationships between one or more regions. 
* [trialTypes] is used to indicate the type of trial you wish to investigate. The name assigned to a trial type or a collection of trial types is arbitrary and is to assist the researcher in making explicit their desired subset of data. This is extracted from the Bpod session file, in the 'TrialTypes' field.
* [outcomes] details the meaning of the trial outcomes saved to the Bpod session file in the field 'SessionPerformance'. Again, these serve as a way to allow the researcher to subdivide the data using explicit and obvious mapping to english "macros".
* [stimTypes] indicates the laser stimulation parameters for each trial, from the Bpod field 'StimTypes'.

# BpodParser Class

This class is in development as an experimental alternative to the current way bpod objects are parsed. As it stands, the BehDat class methods contain the necessary logic to extract task-specific components and variables from the session property of this class, a Bpod SessionData file. A BpodParser object is able to parse bpod session structures and return information that is aligned with the clock from the bpod session, enabling functionality when no neural recording is present. This output can then be aligned to neural data using the trial start timestamps that should be present in every session where neural data is recorded, or to video data that is synchronized through the state machine, like the e3v BNC TTL sync. Ultimately, the bpod property in a BehDat object (described below) will be replaced with a BpodParser object, massively simplifying the existing find_bpod_event methodology.

## BpodParser Properties

    session - a BpodSession structure
    info - a structure containing subfields:
        > path - Path to the experimental session data
        > name - The subject's name
        > trialTypes - structure containing key-value pairs from config.ini
        > outcomes - structure containing key-value pairs from config.ini
        > startState - the name of the bpod state that starts each trial

## BpodParser user-facing methods

`eventTimes = event_times(obj, varargin)`

**OUTPUT:**

* eventTimes - a 1xT cell array of event times from a BpodSession, where T is the number of trials

**INPUT:** 

* 'event' - a named Bpod event ('Port1In', regular expressions ('Port[123]Out'))

*optional name/value pairs*

* 'withinState' - Only return events within certain bpod states
* 'excludeState' - Opposite behavior from withinState
* 'priorToState' - Return the last (bpod) event(s) prior to a bpod state
* 'afterState' - Return the first event(s) after a bpod state
* 'priorToEvent' - Return the last (bpod) event(s) prior to a bpod event
* 'afterEvent' - Return the first event(s) after a bpod event

`event_sankey(obj, varargin)`

This function outputs a sankey plot showing the transitions between bpod
events. By default, it displays all event transitions from all trial
types, but users can use name-value pairs to only analyze certain
combinations of trial types and outcomes, as well as only transitions to
or from a certain event.

***optional name/value pairs:***
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'inputEvents' - a string or cell array of strings of desired input events to visualize
* 'outputEvents' - a string or cell array of strings of desired output events to visualize

`stateEdges = state_times(obj, stateName)`

**OUTPUT:**

* stateEdges - a 1xN cell array of state edges where N is the number of trials

**INPUT:**

* stateName - a name of a bpod state to find edges for

`state_sankey(obj, varargin)`

This function outputs a sankey plot showing the transitions between bpod
states. By default, it displays all state transitions from all trial
types, but users can use name-value pairs to only analyze certain
combinations of trial types and outcomes, as well as only transitions to
or from a certain state.

***optional name/value pairs:***
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'inputStates' - a string or cell array of strings of desired input
* states to visualize
* 'outputStates' - a string or cell array of strings of desired output states to visualize


`frameTimes = e3v_bpod_sync(obj)`

Returns frame times relative to the Bpod State Machine internal clock for a video recorded using the e3vision watchtower on the whitematter PC.

**OUTPUT:**

*frameTimes - a 1xF vector of frame times, where F is the number of frames


# BehDat Class

This class is intended to abstract behavioral sessions and their accompanying data into a class object that can call functions to quickly and cleanly manipulate and visualize the underlying data. Since objects of this class represent a single session, collections of sessions must have an external associated experimental metadata variable. This variable and the array of session objects that it helps manage are both generated by the function 

`[sessions, metadata] = select_experiment;`

which brings up an interactive directory selection menu. If your data is properly organized according to the above specifications, this function will initialize an array of BehDat objects that is equal in length to the total number of session subfolders across all subjects within the parent directory.

## Experiment metadata

This is a structure that accompanies the BehDat object array generated from select_experiment. It contains fields:

    subjects - a 1xS cell array with names of each of the S subjects in the experiment
    path - a string to the local directory that houses the experimental data
    experimenter - The name of the experimenter (set up in config file)

## BehDat Properties

    info - a structure containing subfields:
        > path - Path to the experimental session data
        > name - The subject's name. Will match one of the subjects in metadata.subjects
        > baud - Sampling rate of the neural aquisition hardware
        > samples - Number of samples captured in the neural session
        > trialTypes - structure containing key-value pairs from config.ini
        > outcomes - structure containing key-value pairs from config.ini
        > startState - the name of the bpod state where the trial start timestamp is sent
    spikes - a structure containing subfields:
        > times - a 1xN cell array of spike times, where N is the number of neurons
        > region - 1xN cell array of brain regions of the single units
        > channel - 1xN double list of original channels on acquisition hardwarea
        > fr - average firing rate over the whole session
        > waveforms - a 1xN cell array of average waveform shapes
        > halfValleyWidth - waveform width at half of max depolarization
        > halfPeakWidth - waveform width at half of max hyperpolarization
        > peak2valley - difference in amplitude from peak to valley
        > exciteOutput - generated from find_mono. Indices of neurons monosynaptically downstream from the given neuron.
        > exciteXcorr - 50 ms wide cross correlogram between the two neurons across the whole session.
        > exciteWeight - strength of the correlation in terms of standard deviations of the peak above baseline.
    timestamps - a structure containing subfields:
        > times - a 1xT double array of timestamp times, where T is the number of timestamps
        > codes - a 1xT double array of timestamp codes (i.e. 65529)
        > keys - a structure containing key strings that can be used by the user to reference specific timestamp codes. Set up in config.ini file
        > trialStart - a 1xT vector of timestamps denoting the start of trials. Generated during populate_BehDat
    bpod - a SessionData file from a Bpod session
    coordinates - x and y coordinates from DeepLabCut, imported from csv
    LabGym - an Fx1 cell array of behaviors from LabGym, where F is the number of video frames in the recording. These frames must be somehow synchronized to the experiment, either through input to the Bpod State Machine or to the neural acquisition system. 

## BehDat Methods

Methods for the BehDat class can be thought of as generally belonging to one of 4 categories: Bpod, Spike, LFP, and Video. Some functions do not belong explicitly to any of these categories, but are still useful for manipulating the data. These are listed under the "Other" category.

### ***Bpod***
`[numTT, numCorrect] = outcomes(obj, val)`

This function returns a vector by trial type of the number of completed trials of each trial type, as well as the number correctly completed for the trial type of interest.

**OUTPUT:**
* numTT - 1xT vector where T is the number of trial types. Stores # of each trial type completed in obj.bpod
* numCorrect - 1xT vector where T is the number of trial types. Stores # of trial types with the outcome specified by correctOutcome. If no argument is given, the default value of numCorrect is for outcomes of 1.

**INPUT:**
* correctOutcome - optionally include an integer value in your function call to
calculate performance outcomes other than 1.

`plot_performance(obj, outcome, panel)`

Plots bpod performance bar chart by trial type.

**INPUT:**
* outcome - the outcome whose percentage is being visualized
* panel - a panel handle from AbbasCentral (optional)

`state_sankey(obj, varargin)`

This function outputs a sankey plot showing the transitions between bpod
states. By default, it displays all state transitions from all trial
types, but users can use name-value pairs to only analyze certain
combinations of trial types and outcomes, as well as only transitions to
or from a certain state.

***optional name/value pairs:***
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'inputStates' - a string or cell array of strings of desired input
* states to visualize
* 'outputStates' - a string or cell array of strings of desired output states to visualize

`event_sankey(obj, varargin)`

This function outputs a sankey plot showing the transitions between bpod
events. By default, it displays all event transitions from all trial
types, but users can use name-value pairs to only analyze certain
combinations of trial types and outcomes, as well as only transitions to
or from a certain event.

***optional name/value pairs:***
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'inputEvents' - a string or cell array of strings of desired input events to visualize
* 'outputEvents' - a string or cell array of strings of desired output events to visualize

`timestamps = find_bpod_event(obj, varargin)`

Finds the timestamps in the sampling rate of the neural acquisition system corresponding to a bpod event.

**OUTPUT:**
* timestamps - a 1xE vector of timestamps from the desired event

**INPUT:**
***optional name/value pairs:***
* 'event' -  an event character vector from the bpod SessionData
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'trials' - a vector of trial numbers to include in the output
* 'priorToEvent' - a character vector of an event to include only timestamps that occur before the event
* 'excludeEventsByState' - a character vector of a state to exclude trials from the output that contain this state
* 'withinState' - a character vector, string, or cell array of states to include only timestamps that occur within this state

`stateEdges = find_bpod_state(obj, stateName, varargin)`

Returns the start and end timestamps of a bpod state per trial in the sampling rate of the neural acquisition system.

**OUTPUT:**
* stateEdges - a 1xT cell array of 2xN matrices, where T is the number of trials and N is the number of times the state was entered in the trial. The first row of the matrix is the start time of the state, and the second row is the end time of the state.

**INPUT:**
* stateName - a character vector of the state to find

***optional name/value pairs:***
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'trials' - a vector of trial numbers to include in the output

### ***Spikes***

`timestamps = find_event(obj, varargin)`

Returns the timestamps in the sampling rate of the neural acquisition system corresponding to a wire TTL signal recieved by the system during recording.

**OUTPUT:**
* timestamps - a 1xE vector of timestamps from the desired event

**INPUT:**
***optional name/value pairs:***
* 'event' -  an event character vector found in the config.ini file
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini

`spikesByTrial = trialize_spikes(obj, trialStart)`

Returns a Nx1 cell array, where N is the number of neurons in the session. Each cell contains a 1xT cell array, where T is the number of trials. The contents of each of these cells will be the spike times in each trial for that neuron.

**OUTPUT:**
* spikesByTrial - Nx1 cell array

**INPUT:**
* trialStart - an event named in config.ini marking the start of each trial

`binnedSpikes = bin_spikes(obj, eventEdges, binSize)`

**OUTPUT:**
* binnedSpikes - an N x T binary matrix of binned spikes around an event, where N is the number of neurons in the session and T is the number of bins.

**INPUT:**
* eventEdges - a 1x2 vector specifying the edges to bin between
* binSize - the size of the bins in ms

`binnedTrials = bin_neuron(obj, neuron, varargin)`

**OUTPUT:**
* binnedTrials - an E x T binary matrix of spike times for a neuron, where E is the number of events and T is the number of bins

**INPUT:**
* neuron - number to index a neuron as organized in the spikes field

***optional name/value pairs:***
* 'event' - an event character vector found in the config.ini file
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'edges' - 1x2 vector distance from event on either side in seconds
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'binSize' - an optional parameter to specify the bin width, in ms. default value is 1

`raster(obj, neuron, varargin)`

Plots a spike raster in a new figure according to the input parameters.

**INPUT:**
* neuron - index of neuron from spike field of object

***optional name/value pairs:***
* 'event' - a string of a state named in the config file
* 'edges' - 1x2 vector distance from event on either side in seconds
* 'binSize' - a number that defines the bin size in ms
* 'trialType' - a trial type found in config.ini
* 'outcome' - an outcome character array found in config.ini
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'panel' - an optional handle to a panel (in the AbbasCentral app)
* 'bpod' - a boolean that determines whether to use bpod or native timestamps

`smoothSpikes=psth(obj, neuron, varargin)`

Plots a smoothed psth for a neuron around an event according to the input parameters. This function accepts the same arguments as raster.

**OUTPUT:**
* smoothSpikes- a vector of smoothed spike times

`[zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)`

Returns smoothed Z-Scored firing rates centered around events

**OUTPUT:**
* zMean - NxT matrix of z-scored firing rates, where N is the number of neurons and T is the number of bins
* zCells - a 1xE cell array where E is the number of events. Each cell contains an NxT matrix of firing rates for that trial.
* trialNum - an index of the bpod trial the event occurred in

**INPUT:**
* baseline - string, name of the event to use as baseline
* bWindow - 1x2 vector, time window to use for baseline FR
* event - string, name of the event to use as event
* eWindow - 1x2 vector, time window to use for event FR
* binWidth - scalar, width of the bins in milliseconds

`[corrScore, trialTypes] = xcorr(obj, event, edges)`

Computes the cross-correlogram of the spike trains of all neurons centered 
around the specified event. 

**OUTPUT:**
* corrScore - a 1xE cell array where E is the number of events. Each cell contains an NxN matrix of cross-correlograms for that trial.
* trialTypes - a 1xE vector of trial types for each trial

**INPUT:**
* event - a string of an event named in config.ini
* edges - 1x2 vector specifying distance from the event in seconds

`plot_xcorr(obj, ref, target, window)`

Plots the cross correlogram of two neurons in a given window

**INPUT:**
* ref - index of the reference neuron
* target - index of the target neuron
* window - number of bins to correlate on either side of the center

`find_mono(obj)`

Only needs to be run on an object one time. This identifies putative monosynaptic connections so that fewer cross-correlations have to be run when running trialize_mono functions. The spike fields below will be populated in the object after a call to find_mono:

    > exciteOutput - indices of neurons monosynaptically downstream from the given neuron.
    > exciteXcorr - 50 ms wide cross correlogram between the two neurons across the whole session.
    > exciteWeight - strength of the correlation in terms of standard deviations of the peak above baseline.

`plot_mono(obj, varargin)`

Plots a figure for each cross-correlation between neurons in the BehDat object. If no arguments are given, plots all neurons with a connection identified. If a single argument is given, it should be a vector of reference neuron indices to plot.

`G = plot_digraph(obj, trialized, panel)`

Plots a figure for each cross-correlation between neurons in the BehDat object. If no arguments are given, plots all neurons with a connection identified. If a single argument is given, it should be a vector of reference neuron indices to plot. This function currently only accepts trialized weights from excitatory connections, should be modified to parse name-value pair arguments and accept excitatory and inhibitory weights. It plots the network graph of the neurons with significant cross correlations and their weights. The size of the nodes is proportional to the number of spikes in the neuron. If the argument trialized is given, it should be the output from the function trialize_mono_excitatory. This will plot the average weights from the trialized data.

`weightsEx = trialize_mono_excitatory(obj, trialType, alignment, edges, varargin)`

**OUTPUT:**
* weightsEx - an N x 1 cell array with excitatory connection weights for neuron pairs identified from find_mono, in the event window given by alignment and edges.

**INPUT:**
* trialType - a trial type char array that is in config.ini
* alignment - an alignment char array that is in config.ini
* edges - a 1x2 vector that defines the edges from an event within which spikes will be correlated

***optional name/value pairs:***
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini

`weightsIn = trialize_mono_inhibitory(obj, trialType, alignment, edges, varargin)`

### ***LFP***

`[pwr, freqs, phase] = cwt_power(obj, varargin)`

Calculates power, frequency, and phase using the continuous wavelet transform.

**OUTPUT:**
* pwr - a 1xC cell array of band power where C is the number of channels
* freqs - a 1xF cell array of strings of frequency bands
* phase - a 1xC cell array of phases where C is the number of channels

**INPUT:**
***optional name-value pairs:***
* 'event' - a string of a state named in the config file (default is TrialStart)
* 'edges' - 2x2 vector distance from event on either side in seconds (default = [-2 2])
* 'trialType' - a trial type found in config.ini
* 'outcome' - an outcome character array found in config.ini
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'freqLimits' - a 1x2 vector specifying cwt frequency limits (default = [1 120])
* 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
* 'calculatePhase' - boolean specifying if phase should be calculated (default = true)

`[ppc_all, spikePhase, ppc_sig] = ppc(obj, event, varargin)`

`filteredLFP = filter_signal(obj, alignment, freqLimits, varargin)`

**OUTPUT:**
* filteredLFP - a cell array where each cell holds the trialized filtered LFP signal for that channel

**INPUT:**
* event - a string of a state named in the config file
* freqLimits - a 1x2 vector specifying cwt frequency limits
***optional name-value pairs:***
* 'edges' - 2x2 vector distance from event on either side in seconds (default = [-2 2])
* 'trialType' - a trial type found in config.ini
* 'outcome' - an outcome character array found in config.ini
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'bpod' - a boolean specifying if the bpod event should be used (default = false)
* 'filter' - a string specifying the type of filter to use (default = 'bandpass', alternate = 'butter')

### ***Video***

`stateFrames = find_state_frames(obj, stateName, varargin)`

Provides video frames that synchronize with a bpod event when collected using the e3vision watchtower. For use with trialize_rotation.

**OUTPUT:**
* stateFrames - a 1xN vector of frame times where N is the number of trials.

**INPUT:**
* stateName - a name of a bpod state to align to

***optional name/value pairs:***
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'eos' - a boolean that if true, aligns to the end of a state rather than the start

`rotVec = trialize_rotation(obj, stateName, varargin)`

Trializes the zeroed rotation of a subject around a particular bpod event. By default, calculates the rotation in the 1 second following the event. 

**OUTPUT:**
* rotVec - a 1xN cell array where N is the number of trials. Each cell contains a 1xf vector of angle data where f is the number of frames in the period of interest for each trial.

**INPUT:**
* stateName - a name of a bpod state to align to

***optional name/value pairs:***
* 'edges' - 1x2 vector distance from event on either side in seconds
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini
* 'eos' - a boolean that if true, aligns to the end of a state rather than the start

### ***Other***

`noiseRemoved = remove_noisy_periods(obj, rawData, event, varargin)`

This function will return a matrix where time points corresponding to periods that have been removed prior to kilosorting will be marked with NaN. 

**OUTPUT:**
* noiseRemoved - an NxT matrix with the same dimensions as rawData, with rows corresponding to neurons or trials, and T corresponding to time points in the chosen bin width.

**INPUT:**
* rawData - the output of a function like bin_neuron, ppc, cwt_power, etc. that return a matrix of trialized binned data.
* event - an event string listed in config.ini

***optional name/value pairs:***
* 'edges' - 1x2 vector distance from event on either side in seconds
* 'binWidth' - the size of the bins in ms
* 'offset' - a number that defines the offset from the alignment you wish to center around.
* 'outcome' - an outcome character array found in config.ini
* 'trialType' - a trial type found in config.ini

`goodTrials = trial_intersection(obj, trializedEvents, presets)`

Abstracts away some complexity from the find_event and find_bpod_event functions. Calculates trial set intersections based on the presets.

**OUTPUT**
* goodTrials - logical vector for indexing trial sets

**INPUT**
* trializedEvents - discretized event trial numbers
* presets - a PresetManager object

# ExpManager Class

The ExpManager class' responsibility is to call the BehDat functions on specific collections of sessions from an experiment and return aggregated results that can be used for population-based statistical analyses. 
Furthermore, the ExpManager is the class whose objects' functionality enable the operations of the AbbasCentral app. An ExpManager object is required to use the app, which is described below.

## ExpManager Properties

    sessions - An array of BehDat objects, one per session
    metadata - A structure containing experimental metadata with the following fields:
        > subjects - A cell array of strings that name the subjects with associated sessions
        > path - The root path to the data directory where the project is housed
        > experimenter - The name of the primary experimenter(s)

## ExpManager Methods

`get_size(obj)`

This function calculates the size of the ExpManager object and prints it to the command line.


# PresetManager Class

This class exists to standardize variable arguments that are accepted by many methods across the BpodParser, BehDat, and ExpManager classes. Some of the most common arguments are 'event', 'trialType', 'outcome', 'stimType', 'trials', 'edges', 'offset', and 'binWidth'. These properties and more are described within the class interface for the PresetManager class, located in the BehDatHelper folder. 

There are several advantages to this strategy - one of the first is the massive reduction in boilerplate code that was previously necessary across many class methods in order to parse variable inputs. The second main advantage is the consistency achieved across classes, eliminating the need to change parameters in many files when the central logic is altered. The most common parameters are now stored in a single place that can also be instantiated outside of a function call. For example, you could create a preset variable for calls you commonly make during analysis, eliminating the need to type long lists of name-value pairs in every function call. 

While it is still supported to call a function as follows:

`eventTimes = obj.find_event('event', 'Forage', 'trialType', 'Laser On', 'outcome', 'Correct', 'stimType', 'Sample1', 'offset', 0.5)`

it may be apparent that this can quickly become cumbersome when switching between sets of parameters. You could instead create a PresetManager object using the same parameters as above:

`presetExample = PresetManager('event', 'Forage', 'trialType', 'Laser On', 'outcome', 'Correct', 'stimType', 'Sample1', 'offset', 0.5)`

This variable can then be passed into methods from the BehDat class (and eventually the ExpManager and BpodParser classes as well) using a single argument:

`eventTimes = obj.find_event('preset', presetExample)`

This is also advantageous in the AbbasCentral app, as it allows the user to save combinations of parameters when analyzing data to rapidly switch between presets rather than manually filling out the fields every time, or even visualize two presets on the same graph to compare data.

# AbbasCentral.mlapp


# Example workflow
The following example demonstrates how a researcher may use this package to set up a data pipeline, from collection and spike sorting, to synchronization with parallel data streams, to data analysis, visualization and storage. 

## A) Organize project directory

Collect all files related to individual behavioral sessions in separate directories. Each folder should contain at minimum:
    
* NS6 and NEV file
* Bpod SessionData

    Additionally, directories can contain the following:
* CSV from deeplabcut data (see deeplabcut section for that workflow)


## B) Sort spikes with kilosort

## C) Run LabGym on video files 

## D) Select experiment

