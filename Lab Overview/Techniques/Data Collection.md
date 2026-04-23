This is the first step in the data lifecycle. Data collected in the Abbas Lab comes from multiple sources, often synchronized to each other, and is stored in different formats and locations. The main data streams collected are [[Electrophysiology]], [[Behavior]], and [[Video]] data.

#### Ephys
The [[Microwire drives]] are used in conjunction with the [[Cereplex Direct]] to record electrical signals from various regions. This system is also used to synchronize the behavior data from the [[Bpod State Machine]] and video data from the [[e3Vision]] camera system with the neural data stream. Separately, [[Probes]] can be used in experiments with [[Neuropixels]] data acquisition for recordings with known geometry.

#### Behavior
Behavior protocols are programmed using [[Bpod]] API, and data is saved to a [[MATLAB]] .mat file in a user-specified directory. Typically, all of the computers running a behavior rig will output their saved behavior session files to a common data root. This lives on a hard drive in the [[Behavior Room]], which at the time of writing is connected to the Blackrock laptop.

#### Video
The [[e3Vision]] camera system is a hub that can accommodate up to 8 cameras recording simultaneously on a single synchronization signal. This signal can be connected to an external data acquisition source to timestamp each individual frame. This does limit synchronization of multiple simultaneous [[Electrophysiology]] recordings to independent camera streams.

#### Histology
Slice histology is used to verify electrode placements and confirm proper viral expression. Mice undergo perfusion, brains are collected and frozen, and slices are prepared for microscopic examination. The microscope that we use is in Building 101, room 4xx