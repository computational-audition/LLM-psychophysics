# A javascript synthesizer based on Tone.js

Open demo.html and listen to the different options by clicking on the “Click me!” button.

Full list of changeable parameters is summarised in DEFAULT_PARAMS and can be customised by passing the parameter of interest through the “synth” dictionary of the stimulus. 

CAVEAT: for now channels simply represent different timbres and all “notes” are played sequentially, in the next stage it should be possible to generalise this using Poly.Synth. 

## Basic usage instructions

1. Preload additive synthesiser nodes by running generate_additive_nodes().
2. Preload any sampler instruments of interest from instrument.js e.g. 

LOADED_INSTRUMENTS = {
		“piano”:  load_sampler(“piano”)
		}

3. Define desired stimulus, see demo.html for examples.
4. Play stimulus by running play_stimulus(stimulus)