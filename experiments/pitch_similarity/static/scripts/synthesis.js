// var script = document.createElement('script');
// script.type = 'text/javascript';
// script.src = "https://unpkg.com/tone@next/build/Tone.js";
// document.head.appendChild(script);

var default_dict = {
  "attack": 0.2,
  "decay": 0.1,
  "sustain_amp": 0.8,
  "duration": 1,
  "reg": 0.1,
  "NH": 10, // default_dict["NH"] should be the maximum number of harmonics that is needed for any synthesis given the shepardize value
  "inharmonicity": 2, // 2 is the harmonic series
  "synth": "harmonic",
  "parametrization": "bass",
  "shepardize": false,
  "NSH": 10, // the number of octave transpositions used to create a Shepard tower (runs from -NSH to NSH). 
            // With NH=10 harmonics, can go up to NSH=5 without crashing, though it's too small for inversion invariance. 
            // Can do pure with NSH=10 by setting NH=1, then harmonic = pure or NSH=10 and NH = 4 (recovers Nori's chords)
  "rolloff": 3, //ORIGINAL IS 3!
  "custom_timbre": []
}


play_chord = function (active_nodes, chord_dict) {
    // Generate a chord, the number of notes involved is specified by the list of intervals
    // The input is provided by a dictionary of the following form
    // chord_dict{
    //   "f0": float // bass tone frequency in midi,
    //   "intervals": [int1,int2,int3,...] // list of intervals from bass tone in midi
    //   "synth": str // the type of synthesis, e.g. "pure", "harmonic", "stretched"
    //   "inharmonicity": the amount of inharmonic stretching desired
    //   "parametrization": how the chord intervals are parametrized
    // }
  
    var chord = {...chord_dict}
    var intervals = [0].concat(chord["intervals"])
    var N = intervals.length
  
    for (key in default_dict) {
      if (!(key in chord)){
        chord[key] = default_dict[key]
      }
    }

    if (!chord["rolloff"]){chord["rolloff"] = default_dict["rolloff"]}

    chord["NH"]=get_NH_NSH(chord["shepardize"])[0]
    chord["NSH"]=get_NH_NSH(chord["shepardize"])[1]

    var weights = util_complex(chord["NH"],chord["rolloff"]);

    if (chord["synth"] == "pure") {
      timbre = new Array(chord["NH"]).fill(0);
      timbre[0] = weights[0];
      chord["inharmonicity"] = 2;
    } else if (chord["synth"] == "harmonic"){
      timbre = weights
      chord["inharmonicity"] = 2;
    } else if (chord["synth"] == "stretched"){
      timbre = weights
      chord["inharmonicity"] = 2.1;   
    } else if (chord["synth"] == "compressed"){
      timbre = weights
      chord["inharmonicity"] = 1.9;
    } else if (chord["synth"] == "gamelan"){
      timbre = new Array(chord["NH"]).fill(0);
      for (n=0;n<4;n++){
        timbre[n] = 1
      }
      chord["inharmonicity"] = 2;
    }
    
    if (chord["custom_timbre"] && chord["custom_timbre"].length>0){
      timbre = chord["custom_timbre"]
      console.assert(chord["NH"] - timbre.length >= 0, "Length of custom timbre must not exceed %d!", chord["NH"])
      topad = new Array(chord["NH"] - timbre.length).fill(0);
      timbre = timbre.concat(topad)
    }

    freqs = []
    current = chord["f0"]
    for (i=0;i<N;i++){
      if (chord["parametrization"] == "bass"){
        freqs = freqs.concat([util_midi2freq(chord["f0"] + intervals[i])])
      } else if (chord["parametrization"] == "cumulative") {
        current = current + intervals[i]
        freqs = freqs.concat([util_midi2freq(current)])
      }
      
    }
    
    if (INST_NAMES.includes(chord["synth"])){
      instrument = INSTRUMENTS[chord["synth"]]
      instrument.triggerAttackRelease(freqs, 0.9)
    } else {
      custom_timbre_synth(active_nodes,freqs,timbre,chord)
    }  
  
}
  
util_freq2midi = function (freq) {
    return Math.log2(freq/440)*12 + 69
}

util_midi2freq = function (midi) {
    return (Math.pow(2,(midi-69)/12))*440
}

util_complex = function (NH,rolloff) {
    var partials = []
    var norm = 0

    for (i=1;i<=NH;i++){
        weight = - Math.log2(i) * rolloff
        weight = Math.pow(10,weight/20) // decays at the rate of 12 dB/octave
        partials = partials.concat([weight])
        norm = norm + Math.pow(weight,2)
    }

    return partials.map(x => x/Math.sqrt(norm))

}

util_shepard = function (NSH,NSH_max,freq,inharmonicity) {
  var weights = []
  var norm = 0
  gamma = Math.log2(inharmonicity) // inharmonic rescaling factor

  for (n=0;n<2*NSH+1;n++){
      curr_freq = util_freq2midi(freq * Math.pow(inharmonicity,n - NSH))
      weight = util_gaussian(curr_freq,gamma*65.5,gamma*8.2) // a Gaussian weight centered at the mid point of the midi scale, rescaled if needed for inharmonic compatability
      weights = weights.concat([weight])
      norm = norm + Math.pow(weight,2)
  }

  weights = weights.map(x => x/Math.sqrt(norm))

  padding = new Array(NSH_max-NSH).fill(0); // symmetric padding around the central weights to keep a fixed size
  weights = padding.concat(weights)
  weights = weights.concat(padding)

  return weights

}

util_gaussian = function(x,mu,sigma){
  N = Math.sqrt(2*Math.PI*(sigma**2))
  return 1/N * Math.exp(-1 * ((x - mu) ** 2) / (2 * sigma ** 2))
}

custom_timbre_synth = function(active_nodes,freqs,timbre,chord){
  var NH = timbre.length;
  var ampEnv = active_nodes["envelope"];

  if (chord["shepardize"]){
    NSH = chord["NSH"] 
  } else {
    NSH = 0
  }

  NH_max=get_NH_NSH(chord["shepardize"])[0] // the NH used in the setter function
  NSH_max=get_NH_NSH(chord["shepardize"])[1] // the NSH used in the setter function

  for (i=0;i<freqs.length;i++){
    freq = freqs[i]
    tone_nodes = active_nodes["complex_" + String(i)]
    // generate shepard weight tower around freq of width NSH, and then zero-pad to width default_dict["NSH"]
    sweights = util_shepard(NSH,NSH_max,freq,chord["inharmonicity"]) 
    // default_dict["NH"] captures the actual number of nodes used in the synethsizer setter 
    for (j=0;j<2*NSH_max+1;j++){ 
      // generate Shepard octave compatible with stretching 
      curr_freq = freq * Math.pow(chord["inharmonicity"],j - NSH_max) 
      for (k=0;k<NH;k++){ 
        osc = tone_nodes[j][k][0]
        gain = tone_nodes[j][k][1]

        if (chord["synth"] == "gamelan" && i>0) {

          freq_vals = get_custom_freqs(chord["synth"],NH)
          osc.frequency.value = curr_freq * freq_vals[k]

        } else {

          osc.frequency.value = curr_freq * Math.pow(chord["inharmonicity"],Math.log2(k+1))

        }

        gain.gain.value = sweights[j] * timbre[k] 
      }
    }
  }
  ampEnv.triggerAttackRelease((chord["attack"] + chord["decay"])*(1 + chord["reg"]))
}

additive_synth_setter = function(N,shepardize){

  NH=get_NH_NSH(shepardize)[0]
  NSH=get_NH_NSH(shepardize)[1]

  var control_nodes = {}
  var ampEnv = new Tone.AmplitudeEnvelope({
    "attack": default_dict["attack"],
    "decay": default_dict["decay"],
    "sustain": default_dict["sustain_amp"],
    "release": default_dict["duration"],
    "attackCurve" : "linear",
    "releaseCurve" : "exponential"
  }).toDestination();

  for (i=0;i<N;i++){

    var tone_nodes = util_2d_array(2*NSH+1,NH)

    for (j=0;j<2*NSH+1;j++){
      for (k=0;k<NH;k++){
        var osc = new Tone.Oscillator({"type": "sine", "volume": -17});
        var gain = new Tone.Gain();
        osc.connect(gain).start();
        gain.connect(ampEnv);
        tone_nodes[j][k] = [osc,gain];
      }
    }

    control_nodes["complex_" + String(i)] = tone_nodes

  }

  control_nodes["envelope"] = ampEnv

  return control_nodes

}

util_2d_array = function(M,N) {
  var matrix = new Array(M)
  for (m=0;m<matrix.length;m++) {
    matrix[m] = new Array(N)
  }
  return matrix
}

get_NH_NSH = function(shepardize) {
  if (!shepardize){
    NH = default_dict["NH"] // default_dict["NH"] should be the maximum number of harmonics that is needed for any synthesis (without crashing)
    NSH = 0 // when shepardize is false this doesn't play any role, but the setter requires it regardless, so we set it to the smallest value (to avoid too many audio nodes)
  } else {
    NH = 4 // default_dict["NH"] should be the maximum number of harmonics that is needed for any synthesis, we take it to be 4 for shepard since we need NSH=10
    NSH = default_dict["NSH"]
  }
  return [NH,NSH]
}

play_list = function(active_nodes,chords) {
  var n = chords.length;
  var onsets = new Array(n).fill(0);

  for (i = 0; i < n; i ++) {
    chord = chords[i];
    if (i < n - 1) {
      onsets[i + 1] = onsets[i] + 1.6; //1.8
    }
    play_chord_with_delay(active_nodes, chord, 1000 * onsets[i]);
  }
};

play_chord_with_delay = function(active_nodes, chord, delay) {
setTimeout(function() {
  play_chord(active_nodes, chord);
}, delay);
};

get_custom_freqs = function(type,NH){
  
  if (type=="gamelan"){

    freqs = [1,1.52,3.46,3.92]
    freqs = freqs.concat(new Array(NH - 4).fill(1))

  } else {

    freqs = []

  }
  
  return freqs

}

none_helper = function(value){
  if (value == "None"){
      return null
  } else {
      return JSON.parse(value)
  }    
} 


// const piano = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/acoustic_grand_piano-mp3/"
// }).toDestination();

// piano.volume.value = 15;

// // const xylophone = new Tone.Sampler({
// // 	urls: {
// // 		C3: "C3.mp3",
// //     Db3: "Db3.mp3",
// //     D3: "D3.mp3",
// //     Eb3: "Eb3.mp3",
// //     E3: "E3.mp3",
// //     F3: "F3.mp3",
// //     Gb3: "Gb3.mp3",
// //     G3: "G3.mp3",
// //     Ab3: "Ab3.mp3",
// //     A3: "A3.mp3",
// //     Bb3: "Bb3.mp3",
// //     B3: "B3.mp3",
// // 		C4: "C4.mp3",
// //     Db4: "Db4.mp3",
// //     D4: "D4.mp3",
// //     Eb4: "Eb4.mp3",
// //     E4: "E4.mp3",
// //     F4: "F4.mp3",
// //     Gb4: "Gb4.mp3",
// //     G4: "G4.mp3",
// //     Ab4: "Ab4.mp3",
// //     A4: "A4.mp3",
// //     Bb4: "Bb4.mp3",
// //     B4: "B4.mp3",
// //     C5: "C5.mp3",
// //     Db5: "Db5.mp3",
// //     D5: "D5.mp3",
// //     Eb5: "Eb5.mp3",
// //     E5: "E5.mp3",
// //     F5: "F5.mp3",
// //     Gb5: "Gb5.mp3",
// //     G5: "G5.mp3",
// //     Ab5: "Ab5.mp3",
// //     A5: "A5.mp3",
// //     Bb5: "Bb5.mp3",
// //     B5: "B5.mp3",
// // 		C6: "C6.mp3",
// // 	},
// // 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/xylophone/"
// // }).toDestination();

// // xylophone.volume.value = 15;

// const violin = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/violin-mp3/"
// }).toDestination();

// violin.volume.value = 15;

// const guitar = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/acoustic_guitar_nylon-mp3/"
// }).toDestination();

// guitar.volume.value = 12;

// // const saxophone = new Tone.Sampler({
// // 	urls: {
// // 		C3: "C3.mp3",
// //     Db3: "Db3.mp3",
// //     D3: "D3.mp3",
// //     Eb3: "Eb3.mp3",
// //     E3: "E3.mp3",
// //     F3: "F3.mp3",
// //     Gb3: "Gb3.mp3",
// //     G3: "G3.mp3",
// //     Ab3: "Ab3.mp3",
// //     A3: "A3.mp3",
// //     Bb3: "Bb3.mp3",
// //     B3: "B3.mp3",
// // 		C4: "C4.mp3",
// //     Db4: "Db4.mp3",
// //     D4: "D4.mp3",
// //     Eb4: "Eb4.mp3",
// //     E4: "E4.mp3",
// //     F4: "F4.mp3",
// //     Gb4: "Gb4.mp3",
// //     G4: "G4.mp3",
// //     Ab4: "Ab4.mp3",
// //     A4: "A4.mp3",
// //     Bb4: "Bb4.mp3",
// //     B4: "B4.mp3",
// //     C5: "C5.mp3",
// //     Db5: "Db5.mp3",
// //     D5: "D5.mp3",
// //     Eb5: "Eb5.mp3",
// //     E5: "E5.mp3",
// //     F5: "F5.mp3",
// //     Gb5: "Gb5.mp3",
// //     G5: "G5.mp3",
// //     Ab5: "Ab5.mp3",
// //     A5: "A5.mp3",
// //     Bb5: "Bb5.mp3",
// //     B5: "B5.mp3",
// // 		C6: "C6.mp3",
// // 	},
// // 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/alto_sax-mp3/"
// // }).toDestination();

// // saxophone.volume.value = 15

// const clarinet = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/clarinet-mp3/"
// }).toDestination();

// clarinet.volume.value = 10

// const harpsichord = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/harpsichord-mp3/"
// }).toDestination();

// harpsichord.volume.value = 15

// const trumpet = new Tone.Sampler({
// 	urls: {
// 		C3: "C3.mp3",
//     Db3: "Db3.mp3",
//     D3: "D3.mp3",
//     Eb3: "Eb3.mp3",
//     E3: "E3.mp3",
//     F3: "F3.mp3",
//     Gb3: "Gb3.mp3",
//     G3: "G3.mp3",
//     Ab3: "Ab3.mp3",
//     A3: "A3.mp3",
//     Bb3: "Bb3.mp3",
//     B3: "B3.mp3",
// 		C4: "C4.mp3",
//     Db4: "Db4.mp3",
//     D4: "D4.mp3",
//     Eb4: "Eb4.mp3",
//     E4: "E4.mp3",
//     F4: "F4.mp3",
//     Gb4: "Gb4.mp3",
//     G4: "G4.mp3",
//     Ab4: "Ab4.mp3",
//     A4: "A4.mp3",
//     Bb4: "Bb4.mp3",
//     B4: "B4.mp3",
//     C5: "C5.mp3",
//     Db5: "Db5.mp3",
//     D5: "D5.mp3",
//     Eb5: "Eb5.mp3",
//     E5: "E5.mp3",
//     F5: "F5.mp3",
//     Gb5: "Gb5.mp3",
//     G5: "G5.mp3",
//     Ab5: "Ab5.mp3",
//     A5: "A5.mp3",
//     Bb5: "Bb5.mp3",
//     B5: "B5.mp3",
// 		C6: "C6.mp3",
// 	},
// 	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/trumpet-mp3/"
// }).toDestination();

// trumpet.volume.value = 15

const flute = new Tone.Sampler({
	urls: {
		C3: "C3.mp3",
    Db3: "Db3.mp3",
    D3: "D3.mp3",
    Eb3: "Eb3.mp3",
    E3: "E3.mp3",
    F3: "F3.mp3",
    Gb3: "Gb3.mp3",
    G3: "G3.mp3",
    Ab3: "Ab3.mp3",
    A3: "A3.mp3",
    Bb3: "Bb3.mp3",
    B3: "B3.mp3",
		C4: "C4.mp3",
    Db4: "Db4.mp3",
    D4: "D4.mp3",
    Eb4: "Eb4.mp3",
    E4: "E4.mp3",
    F4: "F4.mp3",
    Gb4: "Gb4.mp3",
    G4: "G4.mp3",
    Ab4: "Ab4.mp3",
    A4: "A4.mp3",
    Bb4: "Bb4.mp3",
    B4: "B4.mp3",
    C5: "C5.mp3",
    Db5: "Db5.mp3",
    D5: "D5.mp3",
    Eb5: "Eb5.mp3",
    E5: "E5.mp3",
    F5: "F5.mp3",
    Gb5: "Gb5.mp3",
    G5: "G5.mp3",
    Ab5: "Ab5.mp3",
    A5: "A5.mp3",
    Bb5: "Bb5.mp3",
    B5: "B5.mp3",
		C6: "C6.mp3",
	},
	baseUrl: "https://instrument-sampler.s3.amazonaws.com/soundfonts/flute-mp3/"
}).toDestination();

flute.volume.value = 10

INSTRUMENTS = {
  // "piano": piano,
  // "xylophone": xylophone,
  // "violin": violin,
  // "guitar": guitar,
  // "harpsichord": harpsichord,
  // "saxophone": saxophone,
  // "clarinet": clarinet,
  "flute": flute,
  // "trumpet": trumpet
}

INST_NAMES = Object.keys(INSTRUMENTS)