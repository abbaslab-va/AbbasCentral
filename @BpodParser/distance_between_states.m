function stateDist = distance_between_states(obj, state1, state2, varargin)

presets = PresetManager(varargin{:});
state1Times = obj.state_times(state1, 'preset', presets, 'trialized', true, 'returnEnd', true);
state2Times = obj.state_times(state2, 'preset', presets, 'trialized', true, 'returnStart', true);
containsBothStates = cellfun(@(x, y) ~isempty(x) && ~isempty(y), state1Times, state2Times);
stateDist = cellfun(@(w, x) cellfun(@(y, z) z - y, w(end), x(1)), state1Times(containsBothStates), state2Times(containsBothStates), 'uni', 0);
stateDist = cat(2, stateDist{:});
