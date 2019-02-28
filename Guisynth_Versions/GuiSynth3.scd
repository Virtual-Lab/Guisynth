(

// -----------------------------------------------------------------------
//                              Example - Program
//                       Granulator and Synths width GUI
//               Granulator with popup - menu for choosing files
//        Parameters - mapped to Sliders, Rangers, Knobs and Numberboxes
//
// -----------------------------------------------------------------------

// -----------------------------------------------------------------------
//                                                 global settings
// -----------------------------------------------------------------------

var granulator1, granulator2;
var m_player, sampler;
var channelsOut = 2;
var mas, bus, effect1, source;
//var player = Dictionary.new;

// Server Settings

//s.quit;
//s.reboot;
o = Server.local.options;

//ServerOptions.devices;
//o.device = "Fireface 800(AA)";
//o.device = "Soundflower (64ch)";
//o.device = "Soundflower (2ch)";
o.device = "JackRouter";

o.numOutputBusChannels = channelsOut;
o.memSize = 2.pow(20);
o.numAudioBusChannels = 2048;
o.sampleRate = 44100;
o.maxNodes = 1024*12;
s.volume = -16;

~channelsOut = 2;
~guiClock = AppClock.new;

s.waitForBoot ({


	// create an objects (~main)
	~main = ~main ? ();
	// create a ~main-Window (Instrument)
	if(~main.window != nil, {~main.window.close});
	~main.window = Window.new("Instrument", Rect(150, 400, 1044, 900), border: true, scroll: true).front;
	~main.window.view.decorator =  FlowLayout(~main.window.bounds, 0@0);

	// create sampler-Window (Instrument)
	~object1 = CompositeView(~main.window, Rect(0, 0, 520, 2000), scroll: true).front
	.onClose_({~object1.free});
	~object1.decorator =  FlowLayout(~object1.bounds, 0@0);

	// create asynth-Window (Instrument)
	~object2 = CompositeView(~main.window, Rect(520, 0, 520, 2000), scroll: true).front
	.onClose_({~object2.free});
	~object2.decorator =  FlowLayout(~object1.bounds, 0@0);


	// -----------------------------------------------------------------------
	//                                                 Synth Definitions
	// -----------------------------------------------------------------------

	// ------------------- Soundfile Player without envelope

	SynthDef(\sfplayer, {
		arg sndbuf, out = 0, rate = 1, pan = 0,  loop = 0, amp = 0.9, trigger = 1, pos = 0, width = 2;

		var bufnum = sndbuf;
		var rateScale = BufRateScale.kr(bufnum)*rate;

		var sfplayer = PlayBuf.ar(sndbuf.numChannels,
			bufnum,
			rateScale,
			trigger,
			pos*BufFrames.kr(bufnum),
			loop) * amp;

		var limiter = Limiter.ar(sfplayer, 1, 0.01);

		var output = PanAz.ar(~channelsOut, limiter, pan, width: width);

		Out.ar(out, output);
	}).add;

	// ******************** Granulator

	SynthDef(\granulator1, {
		arg gate = 1, puls = 20, width = 2, sndbuf, envbuf,
		dur = 0.1, dur = [0.09, 0.11],
		pos = 0, pos = [0, 1],
		pitch = [0.99, 1.01],
		dens = [20, 20],
		pan = [-0.5, 0.5], pan = 0,
		vol = [0.8, 1];

		var env, density, granulator, output;

		env = EnvGen.kr(
			Env([0, 1, 0], [1, 1], \sin, 1),
			gate: gate,
			levelScale: 1,
			doneAction: 2);

		density = Impulse.kr(WhiteNoise.kr(densMax, densMin)+puls);

		granulator = GrainBuf.ar(
			numChannels: 2,
			trigger: density,
			dur: WhiteNoise.kr(1).range(durMin, durMax), // size of the grain
			sndbuf: sndbuf,
			rate: WhiteNoise.kr(1).range(pitchMin, pitchMax),
			pos: WhiteNoise.kr(1).range(posMin, posMax),
			interp: 2, // pitchshifting interpolation: 1 = no, 2 = linear, 4 = cubic
			pan: WhiteNoise.kr(1).range(panMin, panMax), // depends on number of channels: 1: no panning, 2:
			envbufnum: envbuf) * env * LFNoise2.kr(density).range(volMin, volMax);

		output = PanAz.ar(~channelsOut, granulator, pan, width: width);

		Out.ar(0, output);
	}).add;


	// ******************** Granulator2

	SynthDef(\granulator2, {
		|outBus, sideBus, bufnum, startPos, rate = 1, sustain = 0.02, ts = 1, attac = 0.01, release = 0.1, amp = 0.2, pan = 0.5, width = 2|

		var env1 = EnvGen.ar(Env.sine(sustain, 1), timeScale: ts, doneAction: 2);
		/*var env2 = EnvGen.ar(Env.perc(attac, release, 1, 0), timeScale: ts, doneAction: 2);
		var env3 = EnvGen.ar(Env.triangle(sustain, 1), timeScale: ts, doneAction: 2);*/

		var grain = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, 1, BufFrames.ir(bufnum)*startPos, 0);

		var output = grain * env1 * amp;

		OffsetOut.ar(outBus, PanAz.ar(~channelsOut, output, pan, width: width));

	}, \ir.dup(5)).add;

	// Synth Multichannel - Definition - Additiver Synth mit zufälligen Obertönen – Frequenz und Ampl. Contr.
	SynthDef(\glocke, {
		arg out = 0, volume = 0, freq = 200, spread = 0.1,
		ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, release = 0.4, curve = -4,
		pan = 0, xpan = 0, ypan = 0, gate = 1;

		var n = 5, synth, output, random;

		var env = EnvGen.kr(Env.adsr(attack, decay, sustain, release, curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		synth = Mix.fill(n, {|i|
			random = (freq.lag(0.2)  * Rand(1-spread,(1+spread)) * (i+1));
			SinOsc.ar(random, 0, 1/n)})
		* volume * env;

		output = PanAz.ar(2, synth, xpan, 1);

		Out.ar(out, output);

	}).add;

	// Synth Multichannel - Definition - Additiver Synth mit zufälligen Obertönen – Frequenz und Ampl. Contr.
	SynthDef(\glocke2, {
		arg out = 0, volume = 0, freq = 200, spread = 0.1,
		ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, hold = 1, release = 0.4, curve = -4,
		pan = 0, xpan = 0, ypan = 0, gate = 1;

		var n = 5, synth, output, random;

		var env = EnvGen.kr(Env([0, 1, sustain, sustain, 0], [attack, decay, hold, release], curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		synth = Mix.fill(n, {|i|
			random = (freq.lag(0.2)  * Rand(1-spread,(1+spread)) * (i+1));
			SinOsc.ar(random, 0, 1/n)})
		* volume * env;

		output = PanAz.ar(2, synth, xpan, 1);

		Out.ar(out, output);

	}).add;

	SynthDef(\ampMod, { arg out = ~volumeBus, rate = 1, volume = 0.2, ampl = 0.3, lag = 0.5;
		var output = Pulse.kr(rate, 0.5, ampl, volume).lag(lag/rate);
		Out.kr(out, output);
	}).add;

	SynthDef(\freqMod, { |out = 0, rate = 0.1, mul = 100, add = 200|
		var output = SinOsc.kr(rate, 0, mul, add);

		Out.kr(out, output);
	}).add;

	mas = Group.new;
	bus = Group.new;
	effect1 = Group.new;
	source = Group.new;

	// ----------------------------------------------------------------------
	//                                  make Player Prototype - Pseudoklasse
	// ----------------------------------------------------------------------
	~m_player = { arg object, mode, m_window = ~oject1, height = 300, file = True, list = [];

		object = ();
		// ----------------------------------------------------------------------
		//              create a Window for the instrument within the ~main Window
		//              and flexible flow-Layout Layout
		// ----------------------------------------------------------------------
		object.createWindow = {

			if(object.window != nil, {object.window.close});
			object.window = CompositeView(m_window, Rect(0, 0, 500, height)).front
			.onClose_({object.window.free});

			//object.window = ~main.window;

			// FlowLayout (flexible layout)
			object[\window].decorator =  FlowLayout(object.window.bounds);
			object.layout = object.window.decorator;

			// labeling the window
			object.label = CompositeView(object.window, Rect(0, 0, 500, 18))
			.background_(Color.grey(0.6));
			object.label.decorator = FlowLayout(object.label.bounds, 4@0, 0@2);
			object.labeltext = StaticText(object.label, 180@18)
			.string_(mode)
			.font_(Font("Helvetica-bold", 14))
			.stringColor_(Color.white);
			//.background_(Color.blue);
		};

		object.createWindow.value;

		if (file != False, {
			// ----------------------------------------------------------------------
			//                make Soundfile-Window - set default bufferlength
			// ----------------------------------------------------------------------
			object.createFile = {

				object.sfsource = ""; //Array.fill(~instruments, s.sampleRate * 30);
				object.bufferlength = 5.0; //bufferlength of 5 seconds
				//object.buffer = Buffer.alloc(s, s.sampleRate * 5.0, 1, bufnum: i);  // create a buffer
				object.file = false; // for loading a Soundfile
				object.soundfile = SoundFile.new; // read a soundfile - create a dummy

				// create a waveform window
				object.sfwindow = SoundFileView.new(object.window, Rect(10, 8, 500, 80));

			};

			object.createFile.value;

			// ----------------------------------------------------------------------
			//                                  create a filebrowser with a Popup - Menue
			// ----------------------------------------------------------------------//

			object.createBrowser = {

				object.filebrowser = PopUpMenu(object.window, Rect(0,0,200,20));
				object.folder = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "field/");
				object.files = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "field/").files;

				object.filenames = Array.fill(object.files.size, { |index| object.files[index].fileName});
				object.filebrowser.items = object.filenames;
				object.filebrowser.value = rand(object[\files].size);

				object.sfsource = object.files[object.filebrowser.value].fullPath;
				object.buffer = Buffer.readChannel(s, object.sfsource, channels: 0);
			};

			object.createBrowser.value;

			// ----------------------------- Filebrowser - Action

			object.filebrowser.action = { |selection|

				// load Filepath
				object.drawSoundfile.stop;
				object.sfsource = object.files[selection.value].fullPath;
				object.file = true; // variable is a file?
				object.refreshSoundfileView.value();

			};

			// ------------------------ Button für Folder-Auswahl (doesn't work yet

			/*	object.startbuttonGui1 = Button(object.window, Rect(0,0,50,20))
			.states_([["choose folder", Color.black, Color.white]])
			.action_({ |val|
			FileDialog.new({ |path|
			object.files = path;
			object.createBrowser.value(object.files)}, {}, 3, 0, false);
			});*/

			// ----------------------------------------------------------------------
			//                                   create/refresh a SoundfileVie
			// ----------------------------------------------------------------------//

			object.refreshSoundfileView = {

				object.buffer = Buffer.readChannel(s, object.sfsource, channels: 0,
					action: {
						// .............. Sound mit geladenem Buffer (Soundfile) zeichnen
						object.soundfile = SoundFile.openRead(object.sfsource);

						defer {
							object.sfwindow.soundfile = object.soundfile;            // set soundfile
							object.sfwindow.read(0, object.soundfile.numFrames);     // read in the entire file.
							object.sfwindow.refresh;  // refresh sfwindow

							"Refresh".postln;
						};

				})

			};

			// ------------ create a SoundfileView while Recording immediatly (not used yet)

			object.drawSoundfile =   Task {

				postf("recording file .... \n");
				//object.refreshSelection.start;

				loop {
					// Buffer in ein Array laden
					object.buffer.loadToFloatArray(0, object.buffer.numFrames,
						{ |d| object.datas = d } );

					// Array ins File-sfWindow laden
					defer{object.sfwindow.data = object.datas};

					0.2.yield; // Refresh Rat
				};
			};
		});

		// ----------------------------------------------------------------------
		//                      Controls
		// ----------------------------------------------------------------------

		// presettings of Samplers, granulators, ...;

		object.sampler = {

			object.list = [
				'volume', [0.0, 1.0, 0.9], "Slider",
				'pan', [-1.0, 1.0, 0.1], "Slider",
			];
		};


		object.granulator1 = {

			object.list = [
				'vol', [0, 2, 0.9, 1], "Ranger",
				'pan', [-1.0, 1.0, -0.5, 0.5], "Ranger",
				'pitch', [0.01, 5.0, 0.99, 1.01], "Ranger",
				'dur', [0.001, 1, 0.2, 0.25], "Ranger",
				'pos', [0, 1.0, 0.1, 0.12], "Ranger",
				'dens', [5, 100, 20, 30], "Ranger",
				'puls', [1, 100, 20], "Slider",
			];

		};



		object.granulator2 = {

			object.list = [
				'pos', [0, 1, 0.1, 0.5], "Ranger",
				'vol', [0, 2, 0.9, 1], "Ranger",
				'pan', [-1.0, 1.0, -1.0, 1], "Ranger",
				'pitch', [0.01, 5.0, 0.99, 1.01], "Ranger",
				'dens', [0.0001, 0.5, 0.01, 0.05], "Ranger",
				'dur', [0.01, 2, 0.1, 1.25], "Ranger",
			];

		};

		object.glocke = {

			object.list = [
				'trigger', [0, 20, 0.2], "Trigger",
				'volume', [0, 2, 0.5], "Knob",
				'freq', [20, 8000, 220], "Knob",
				'xpan', [-1.0, 1.0, 0], "Knob",
				'attack', [0, 5.0, 0.01], "Knob",
				'decay', [0, 2, 0.1], "Knob",
				'sustain', [0, 1, 0.6], "Knob",
				'release', [0, 10, 0.2], "Knob",
				'ts', [0.01, 10, 1], "Knob",
				'curve', [-5, 5, -4], "Knob",
				//'dur', [0, 20, 0.5], "Slider",
			];

		};

		object.glocke2 = {

			object.list = [
				'trigger', [0, 20, 0.2], "Trigger",
				'volume', [0, 2, 0.5, 1], "Ranger",
				'freq', [20, 8000, 220, 440], "Ranger",
				'xpan', [-1.0, 1.0, -0.5, 0.5], "Ranger",
				'hold', [0, 10, 0.01, 0.1], "Ranger",
				'dens', [0.0001, 0.5, 0.01, 0.05], "Ranger",
				'attack', [0, 5.0, 0.01], "Knob",
				'decay', [0, 2, 0.1], "Knob",
				'sustain', [0, 1, 0.6], "Knob",
				'release', [0, 10, 0.2], "Knob",
				'ts', [0.01, 10, 1], "Knob",
				'curve', [-5, 5, -4], "Knob",
				'spread', [-5, 5, -4], "Knob",
			];

		};

		object[\toggle] = { |name|

			object[(name[0]++"Gui").asSymbol] = Button(object.window, Rect(0,0,50,20))
			.states_([[name[0], Color.black, Color.white], [name[1], Color.black, Color.grey]])
			.action_({ |val|
				//	object.startbutton.value = val.value;
				object[(name[0]++"Control").asSymbol].value(val.value);

			});

			object[(name[0]++"Control").asSymbol] = { |val|

				if (object[(name[0]++"Gui").asSymbol].value != val,
					{ defer {object[(name[0]++"Gui").asSymbol].value = val} });

				object[(name[0]++"Bus").asSymbol].set(val);
				object[(name[0]++"Val").asSymbol] = val;

				if (object[(name[0]++"Val").asSymbol] == 1, {
					object.[(mode++name[0]).asSymbol].value;
				}, {
					object.[(mode++name[1]).asSymbol].value;
				});

				postf("Play %: Status %\n", mode, object[(name[0]++"Val").asSymbol]);

				postf("Value: %\n", val);

			};

			object[(name++"DrawGui").asSymbol] = Task {

				loop {

					object[(name++"Bus").asSymbol].get({ |val|

						object[(name++"Val").asSymbol] = val;

						//postf("Change value Parameter: %, Value: %\n", name, val);

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					});

					0.1.wait;
				}
			};

		};

		object[\setTrigger] = { |name, values|

			var min = values[0], max = values[1], currentVal = values[2];

			object[(name++"Gui").asSymbol] = Button(object.window, Rect(0,0,50,20))
			.states_([[name, Color.black, Color.white], [name, Color.black, Color.white]])
			.action_({ |val|
				//	object.startbutton.value = val.value;
				object[(name++"Control").asSymbol].value(val.value);

			});

			object[(name++"Control").asSymbol] = { |val|

				object[(mode++name).asSymbol].start;

			};

			object[(name++"Time").asSymbol] = currentVal;

			// Numberbox for time parameter

			object[(name++"TimeSetGui").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| object[(name++"Time").asSymbol] = val.value};

			object[(name++"TimeSetGui").asSymbol].clipLo = 0;
			object[(name++"TimeSetGui").asSymbol].value  = currentVal;


			// labeling the Number Box

			object[(name++"LabelBox").asSymbol] = CompositeView(object.window, Rect(0, 0, 40, 20))
			.background_(Color.grey(0.6));

			object[(name++"LabelText").asSymbol] = StaticText(object[(name++"LabelBox").asSymbol], Rect(5, 0, 35, 20))
			.string_("time")
			.font_(Font("Helvetica-bold", 12))
			.stringColor_(Color.white)
			.background(Color.grey(0.6));




			object.layout.nextLine;

		};

		object[\setSlider] = { |name, values|

			var min = values[0], max = values[1], currentVal = values[2];

			postf("Slider Parametername: %, Received Values: %\n", name, values);

			object[(name++"Val").asSymbol] = currentVal;

			object[(name++"Bus").asSymbol] = Bus.control(s, 1).value = currentVal;

			object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			/*Spec.add((mode++name++"Spec").asSymbol, object[(name++"Spec").asSymbol]);*/

			object[(name++"Gui").asSymbol] = EZSlider(object.window, 350@20, name, object[(name++"Spec").asSymbol],
				{ |val| object[(name++"Control").asSymbol].value(val.value)}, currentVal);

			object[(name++"Lo").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| min = val.value;
				object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);
				object[(name++"Gui").asSymbol].controlSpec = object[(name++"Spec").asSymbol];
			};
			object[(name++"Lo").asSymbol].value = min;

			object[(name++"Hi").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| max = val.value;
				object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);
				object[(name++"Gui").asSymbol].controlSpec = object[(name++"Spec").asSymbol];
			};
			object[(name++"Hi").asSymbol].value = max;

			object[(name++"setSpec").asSymbol] = { |spec|
				var min = spec[0], max = spec[1];

				object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);
				object[(name++"Gui").asSymbol].controlSpec = object[(name++"Spec").asSymbol];
				object[(name++"Lo").asSymbol].value = min;
				object[(name++"Hi").asSymbol].value = max;
			};

			object[(name++"Control").asSymbol] = { |val|

				object[(name++"Bus").asSymbol].set(val);
				object[(name++"Val").asSymbol] = val;

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val });
				};

				postf("Value: %\n", val.value)

			};

			object[(name++"DrawGui").asSymbol] = Task {

				loop {

					object[(name++"Bus").asSymbol].get({ |val|

						object[(name++"Val").asSymbol] = val;

						//postf("Change value Parameter: %, Value: %\n", name, val);

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					});

					0.1.wait;
				}
			};

			object.layout.nextLine;
		};


		object[\setRanger] = { |name, values|

			var min = values[0], max = values[1];
			var preMin = values[2], preMax = values [3];

			postf("Parametername: %, Received Values: %\n", name, values);

			object[(name++"Min").asSymbol] = preMin;
			object[(name++"Max").asSymbol] = preMax;

			object[(name++"MinBus").asSymbol]= Bus.control(s, 1).value = preMin;
			object[(name++"MaxBus").asSymbol] = Bus.control(s, 1).value = preMax;


			object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			object[(name++"Gui").asSymbol] = EZRanger(object.window, 350@20, name, object[(name++"Spec").asSymbol],
				{ |sl|
					object[(name++"Control").asSymbol].value(sl.value);
					/*object[(name++"MinBus").asSymbol].set(sl.value[0]);
					object[(name++"MaxBus").asSymbol].set(sl.value[1]);*/

			}, [preMin, preMax]);

			object[(name++"Lo").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| min = val.value;
				object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);
				object[(name++"Gui").asSymbol].controlSpec = object[(name++"Spec").asSymbol];
			};
			object[(name++"Lo").asSymbol].value = min;

			object[(name++"Hi").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| max = val.value;
				object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);
				object[(name++"Gui").asSymbol].controlSpec = object[(name++"Spec").asSymbol];
			};
			object[(name++"Hi").asSymbol].value = max;

			object[(name++"Control").asSymbol] = { |val|

				if (val.size < 2, { val = [val, val] });

				object[(name++"MinBus").asSymbol].set(val[0]);
				object[(name++"Min").asSymbol] = val[0];

				object[(name++"MaxBus").asSymbol].set(val[1]);
				object[(name++"Max").asSymbol] = val[1];

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val });
				};

				postf("Value: %\n", val);
			};

			//object[(name++"drawGuiClock")] = AppClock.new;

			object[(name++"DrawGui").asSymbol] = Task {

				loop {

					object[(name++"MinBus").asSymbol].get({ |val|

						object[(name++"Min").asSymbol] = val;

						//postf("Change value Parameter: %, Value: %\n", name, val);

						defer {

							if (object[(name++"Gui").asSymbol].lo != val, {
								object[(name++"Gui").asSymbol].lo = val })
						}
					});

					object[(name++"MaxBus").asSymbol].get({ |val|

						object[(name++"Max").asSymbol] = val;

						//postf("Change value Parameter: %, Value: %\n", name, val);

						defer {
							if (object[(name++"Gui").asSymbol].hi != val, {
								object[(name++"Gui").asSymbol].hi = val  } )
						}
					});

					0.1.wait;
				}
			};

			object.layout.nextLine;


			//AppClock.play(object[(name++"DrawGui")]);

		};

		object[\setKnob] = { |name, values|

			var min = values[0], max = values[1], currentVal = values[2];

			postf("Slider Parametername: %, Received Values: %\n", name, values);

			object[(name++"Val").asSymbol] = currentVal;

			object[(name++"Bus").asSymbol]= Bus.control(s, 1).value = currentVal;

			object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			"here".postln;

			object[(name++"Gui").asSymbol] = EZKnob(object.window, 50@90, name, object[(name++"Spec").asSymbol],
				{ |val| object[(name++"Control").asSymbol].value(val.value)}, currentVal);

			object[(name++"Control").asSymbol] = { |val|
				object[(name++"Bus").asSymbol].set(val);
				object[(name++"Val").asSymbol] = val;

				postf("Value: %\n", val.value);

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val; })
				}

			};

			object[(name++"DrawGui").asSymbol] = Task {

				loop {

					object[(name++"Bus").asSymbol].get({ |val|

						object[(name++"Val").asSymbol] = val;

						//postf("Change value Parameter: %, Value: %\n", name, val);

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					});

					0.1.wait;
				}
			};


		};

		/*EZKnob*/

		// ----------------------------------------------------------------------
		//                                       grainplayer - Controls
		// ----------------------------------------------------------------------

		// Wenn es einen MVC-erfordert: object.startbutton = Bus.control();


		// -------------------  Soundfile-Player-Start

		object.samplerOn= { arg command;

			object.track = Synth.head(source, \sfplayer, [\sndbuf, object.buffer, \rate, 1, \loop, 0]);
			object.track.map(\amp, object.volumeBus);
			object.track.map(\pan, object.panBus);
		};

		// -------------------  Soundfile-Player-Stop

		object.samplerOff= { arg command;

			object.track.release(0.2);
			object.track.free;

		};

		// -------------------  Soundfile-Granulator-Start

		object.granulator1On= { arg command;


			object.track = Synth.head(source, \granulator1, [\sndbuf, object.buffer, \envbuf, -1]);
			object.track.map(\volMin, object.volMinBus);
			object.track.map(\volMax, object.volMaxBus);
			object.track.map(\panMin, object.panMinBus);
			object.track.map(\panMax, object.panMaxBus);
			object.track.map(\durMin, object.durMinBus);
			object.track.map(\durMax, object.durMaxBus);
			object.track.map(\posMin, object.posMinBus);
			object.track.map(\posMax, object.posMaxBus);
			object.track.map(\pitchMin, object.pitchMinBus);
			object.track.map(\pitchMax, object.pitchMaxBus);
			object.track.map(\densMin, object.densMinBus);
			object.track.map(\densMax, object.densMaxBus);
			object.track.map(\puls, object.pulsBus);



		};

		// ------------------- Soundfile-Granulator-Stop

		object.granulator1Off= { arg command;

			object.track.set(\gate, 0);

			object.track.free;

		};

		object.granulator1Task1 = Task {

			// Something to do

		};

		object.granulator2On= { arg command;

			object.granulator2Task.start;

		};

		object.granulator2Off= { arg command;

			object.granulator2Task.stop;

		};

		object.granulator2Task = Task {

			var dur, time;

			loop {

				dur = rrand(object[\densMin], object[\densMax]);
				time = dur;

				if (time < 0.0001, {time = 0.0001});

				object.track = Synth.head(source, \granulator2,
					[\bufnum, object.buffer,
						\startPos, object[\posMin].rrand(object[\posMax]),
						\amp, object[\volMin].rrand(object[\volMax]),
						\rate, object[\pitchMin].rrand(object[\pitchMax]),
						\pan, object[\panMin].rrand(object[\panMax]),
						\sustain, object[\durMin].rrand(object[\durMax]),
						\channels, ~outChannels
				]);

				time.wait;
			};

		};

		// ----------------------------------------------------------------------
		//                        Synth Player Controls
		// ----------------------------------------------------------------------


		// -------------------  Glockensynth-Start

		object.glockeOn= { arg command;

			object.track = Synth.head(source, \glocke, [\gate, 1, \outBus, 0]);
			object.track.map(\volume, object.volumeBus);
			object.track.map(\freq, object.freqBus);
			object.track.map(\xpan, object.xpanBus);
			object.track.map(\attack, object.attackBus);
			object.track.map(\decay, object.decayBus);
			object.track.map(\sustain, object.sustainBus);
			object.track.map(\release, object.releaseBus);
			object.track.map(\ts, object.tsBus);
			object.track.map(\curve, object.curveBus);

		};

		object.glocketrigger = Task { arg command;

			object.track = Synth.head(source, \glocke, [\gate, 1, \outBus, 0]);
			object.track.set(\volume, object.volumeVal);
			object.track.set(\freq, object.freqVal);
			object.track.set(\xpan, object.xpanVal);
			object.track.set(\attack, object.attackVal);
			object.track.set(\decay, object.decayVal);
			object.track.set(\sustain, object.sustainVal);
			object.track.set(\release, object.releaseVal);
			object.track.set(\ts, object.tsVal);
			object.track.set(\curve, object.curveVal);

			object[\triggerTime].wait;

			object.track.release;


		};

		// -------------------  Soundfile-Player-Stop

		object.glockeOff= { arg command;

			object.track.release;
			//object.track.free;

		};

		object.glocke2On= { arg command;

			object.glocke2Task.start;

		};

		object.glocke2Off= { arg command;

			object.glocke2Task.stop;

		};

		object.glocke2Task = Task {

			var dur, time;

			loop {

				time = object[\densMin].rrand(object[\densMax]);

				if (time < 0.0001, {time = 0.0001});

				object.track = Synth.head(source, \glocke2,
					[\out, 0,
						\volume, object[\volumeMin].rrand(object[\volumeMax]),
						\freq, object[\freqMin].rrand(object[\freqMax]),
						\xpan, object[\xpanMin].rrand(object[\xpanMax]),
						\hold, object[\holdMin].rrand(object[\holdMax]),
						\attack, object[\attackVal],
						\decay, object[\decayVal],
						\sustain, object[\sustainVal],
						\release, object[\releaseVal],
						\curve, object[\curveVal],
						\ts, object[\tsVal],
						\spread, object[\spreadVal]
				]);

				time.wait;
			};

		};

		object.glocke2trigger = Task { arg command;

			object.track = Synth.head(source, \glocke, [\gate, 1, \outBus, 0]);
			object.track.set(\volume, object.volumeVal);
			object.track.set(\freq, object.freqVal);
			object.track.set(\xpan, object.xpanVal);
			object.track.set(\attack, object.attackVal);
			object.track.set(\decay, object.decayVal);
			object.track.set(\sustain, object.sustainVal);
			object.track.set(\release, object.releaseVal);
			object.track.set(\ts, object.tsVal);
			object.track.set(\curve, object.curveVal);

			object[\triggerTime].wait;

			object.track.release;


		};


		// ----------------------------------------------------------------------
		//                        Draw Controls and Values
		// ----------------------------------------------------------------------

		object[mode.asSymbol].value;

		// draw the toggles, sliders and rangers

		object[\toggle].value(['On', 'Off']);

		//object.layout.nextLine;

		object[\makeGui] = { | values |

			var quant = values.size/3;

			quant.do { |i|
				var name = values[i*3];
				var varis = values[(i*3)+1];
				var type = values[(i*3)+2];

				postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);

				object[("set"++type).asSymbol].value(name, varis);
			};
		};

		object[\makeGui].value(object.list);

		object.refreshSoundfileView.value();



		object;

	};

	~granulator1 = ~m_player.value(~granulator1, "granulator1", ~object1, height: 305);
	~granulator2 = ~m_player.value(~granulator2, "granulator2", ~object1, height: 280);
	~glocke = ~m_player.value(~glocke, "glocke", ~object2, height: 170, file: False);
	~glocke2 = ~m_player.value(~glocke2, "glocke2", ~object2, height: 280, file: False);
	~sampler = ~m_player.value(~sampler, "sampler", ~object1, height: 200, file: True);
	//player.start;

})

);

GetFileDialog
FileDialog.new({ |path| path.postln }, {}, 2, 0);
Dialog.openPanel

m = ()
m.test = 1
m[\test]

~granulator1.granulator1On;
~granulator1[\volControl].value([0.9, 1]);
~granulator1[\panControl].value([-1, 1]);
~granulator1[\durControl].value([0.02, 0.1]);
~granulator1[\densControl].value([20, 40]);
~granulator1[\pitchControl].value([1, 1.5]);
~granulator1[\pulsControl].value(10);

~control1 = Synth(\ampMod, [\out, ~granulator1[\pitchMinBus], \rate, 0.2, \volume, 0.8]);
~freqMod = Synth(\freqMod, [\out, ~granulator1[\pulsBus]]);
~control1.free;
~freqMod.free;

~granulator1[\pitchdrawGui].start;

~granulator1[\pitchMinBus].set(0.2);

~granulator1[\pitchMinBus].get({ |val| postf("Bus Value: %\n", val)});

~granulator1.granulator1Off;

[1, 0].size;

3.size;
[0.2, 4, 4.5, 45].choose;
[60.midicps,62.midicps,64.midicps,67.midicps].choose;
[60.midicps,62.midicps,64.midicps,67.midicps].wchoose([0.1, 0.2, 0.3, 0.4]);
\test.asString;
a= 4; b = 10; c=2.3; d= 16;
f = (a + b + c + d)
a = a /f;
b = b / f;
c = c / f;
d = d/ f;
(a + b + c + d)

g = True;
\test === 'test'
(
var object = 2;
object
)