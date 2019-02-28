(

// -----------------------------------------------------------------------
//                                              Example - Programm
//                                                Granulator mit GUI
//                                              Popup - Fileauswahl
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

s.waitForBoot ({


	// create an objects (~main)
	~main = ~main ? ();
	// create a ~main-Window (Instrument)
	if(~main.window != nil, {~main.window.close});
	~main.window = Window.new("Instrument", Rect(400, 400, 510, 900), border: true, scroll: true).front;
	~main.window.view.decorator =  FlowLayout(~main.window.bounds, 0@0);

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
		dur = 0.1, durMin = 0.09, durMax = 0.11,
		pos = 0, posMin = 0, posMax = 1,
		pitchMin = 0.99, pitchMax = 1.01,
		densMin = 20, densMax = 20,
		panMin = -0.5, panMax = 0.5, pan = 0,
		volMin = 0.8, volMax = 1;

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

	mas = Group.new;
	bus = Group.new;
	effect1 = Group.new;
	source = Group.new;

	// ----------------------------------------------------------------------
	//                                  make Player Prototype - Pseudoklasse
	// ----------------------------------------------------------------------
	~m_player = { |m_player, mode|

		m_player = ();
		// ----------------------------------------------------------------------
		//              create a Window for the instrument within the ~main Window
		//              and flexible flow-Layout Layout
		// ----------------------------------------------------------------------
		m_player.createWindow = {

			if(m_player.window != nil, {m_player.window.close});
			m_player.window = CompositeView(~main.window, Rect(0, 0, 500, 300)).front
			.onClose_({m_player.window.free});

			//m_player.window = ~main.window;

			// FlowLayout (flexible layout)
			m_player[\window].decorator =  FlowLayout(m_player.window.bounds);
			m_player.layout = m_player.window.decorator;

			// labeling the window
			m_player.label = CompositeView(m_player.window, Rect(0, 0, 500, 18))
			.background_(Color.grey(0.6));
			m_player.label.decorator = FlowLayout(m_player.label.bounds, 4@0, 0@2);
			m_player.labeltext = StaticText(m_player.label, 180@18)
			.string_(mode)
			.font_(Font("Helvetica-bold", 14))
			.stringColor_(Color.white);
			//.background_(Color.blue);
		};

		m_player.createWindow.value;

		// ----------------------------------------------------------------------
		//                                         make File-Window
		// ----------------------------------------------------------------------
		m_player.createFile = {

			m_player.sfsource = ""; //Array.fill(~instruments, s.sampleRate * 30);
			m_player.bufferlength = 5.0; //bufferlength of 5 seconds
			//m_player.buffer = Buffer.alloc(s, s.sampleRate * 5.0, 1, bufnum: i);  // create a buffer
			m_player.file = false; // for loading a Soundfile
			m_player.soundfile = SoundFile.new; // read a soundfile - create a dummy

			// create a waveform window
			m_player.sfwindow = SoundFileView.new(m_player.window, Rect(10, 8, 500, 80));

		};

		m_player.createFile.value;

		// ----------------------------------------------------------------------
		//                                  create a filebrowser with a Popup - Menue
		// ----------------------------------------------------------------------//

		m_player.createBrowser = {

			m_player.filebrowser = PopUpMenu(m_player.window, Rect(0,0,200,20));
			m_player.folder = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "field/");
			m_player.files = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "field/").files;

			m_player.filenames = Array.fill(m_player.files.size, { |index| m_player.files[index].fileName});
			m_player.filebrowser.items = m_player.filenames;
			m_player.filebrowser.value = 0;

			m_player.sfsource = m_player.files[0].fullPath;
			m_player.buffer = Buffer.readChannel(s, m_player.sfsource, channels: 0);
			m_player.refreshSoundfileView.value();
		};

		m_player.createBrowser.value;

		// ----------------------------- Filebrowser - Action

		m_player.filebrowser.action = { |selection|

			// load Filepath
			m_player.drawSoundfile.stop;
			m_player.sfsource = m_player.files[selection.value].fullPath;
			m_player.file = true; // variable is a file?
			m_player.refreshSoundfileView.value();

		};

		// ----------------------------Button für Folder-Auswahl

		/*	m_player.startbuttonGui1 = Button(m_player.window, Rect(0,0,50,20))
		.states_([["choose folder", Color.black, Color.white]])
		.action_({ |val|
		FileDialog.new({ |path|
		m_player.files = path;
		m_player.createBrowser.value(m_player.files)}, {}, 3, 0, false);
		});*/

		// ----------------------------------------------------------------------
		//                                   create/refresh a SoundfileVie
		// ----------------------------------------------------------------------//

		m_player.refreshSoundfileView = {

			m_player.buffer = Buffer.readChannel(s, m_player.sfsource, channels: 0,
				action: {
					// .............. Sound mit geladenem Buffer (Soundfile) zeichnen
					m_player.soundfile = SoundFile.openRead(m_player.sfsource);

					defer {
						m_player.sfwindow.soundfile = m_player.soundfile;            // set soundfile
						m_player.sfwindow.read(0, m_player.soundfile.numFrames);     // read in the entire file.
						m_player.sfwindow.refresh;  // refresh sfwindow

						"Refresh".postln;
					};

			})

		};

		// -------------- create a SoundfileView while Recording immediatly

		m_player.drawSoundfile =   Task {

			postf("recording file .... \n");
			//m_player.refreshSelection.start;

			loop {
				// Buffer in ein Array laden
				m_player.buffer.loadToFloatArray(0, m_player.buffer.numFrames,
					{ |d| m_player.datas = d } );

				// Array ins File-sfWindow laden
				defer{m_player.sfwindow.data = m_player.datas};

				0.2.yield; // Refresh Rat
			};
		};

		m_player.controls = {

			m_player.startGui = Button(m_player.window, Rect(0,0,50,20))
			.states_([["play", Color.black, Color.white], ["stop", Color.black, Color.grey]])
			.action_({ |val|
				//	m_player.startbutton.value = val.value;
				m_player.startValue = val.value;

				if (m_player.startValue == 1, {
					m_player.[(mode++"On").asSymbol].value;
				}, {
					m_player.[(mode++"Off").asSymbol].value;
				});

				postf("Play %: Status %\n", mode, m_player.startValue);
			});


		};

		// ----------------------------------------------------------------------
		//                                      sampleplayer - Controls
		// ----------------------------------------------------------------------

		// Wenn es einen MVC-erfordert: m_player.startbutton = Bus.control();
		m_player.sampler = {

			m_player.list = [
				'volume', [0, 1, 0.1, 0.5], 'Slider',
				'pan', [0, 2, 0.9, 1], 'Slider',
			];

			// volume slider
			m_player.layout.nextLine;
			m_player.volume = Bus.control(s, 1).value = 0.9;
			m_player.volumeSpec = ControlSpec(0, 2, \lin, step: 0, default: 0);

			m_player.volumeGui =EZSlider(m_player.window, 350@20, "Volume", m_player.volumeSpec,
				{ |val| m_player.volume.set(val.value)}, 0.9);

			// pan slider
			m_player.layout.nextLine;
			m_player.pan = Bus.control(s, 1).value = 0;
			m_player.panSpec = ControlSpec(-1, 1, \lin, step: 0, default: 0);

			m_player.panGui =EZSlider(m_player.window, 350@20, "Panning", m_player.panSpec,
				{ |val| m_player.pan.set(val.value)}, 0.5);
		};

		// ----------------------------------------------------------------------
		//                                       granulator - Controls
		// ----------------------------------------------------------------------

		// Wenn es einen MVC-erfordert: m_player.startbutton = Bus.control();

		m_player.granulator1 = {

			m_player.list = [
				'vol', [0, 2, 0.9, 1], "Ranger",
				'pan', [-1.0, 1.0, -0.5, 0.5], "Ranger",
				'pitch', [0.01, 5.0, 0.99, 1.01], "Ranger",
				'dur', [0.001, 1, 0.2, 0.25], "Ranger",
				'pos', [0, 1.0, 0.1, 0.12], "Ranger",
				'dens', [5, 100, 20, 30], "Ranger",
				'puls', [1, 100, 20], "Slider",
			];

			m_player[\makeGui] = { | values |

				var quant = values.size/3;

				quant.do { |i|
					var name = values[i*3];
					var varis = values[(i*3)+1];
					var type = values[(i*3)+2];

					postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);

					m_player[("set"++type).asSymbol].value(name, varis);
				};
			};

			m_player[\makeGui].value(m_player.list);

			/*
			// volume range
			m_player.layout.nextLine;
			m_player.volMin = Bus.control(s, 1).value = 0.9;
			m_player.volMax = Bus.control(s, 1).value = 1;
			m_player.volSpec = ControlSpec(0, 2, \lin, step: 0, default: 0);

			m_player.volumeGui =EZRanger(m_player.window, 350@20, "Volume", m_player.volSpec,
			{ |val| m_player.volMin.set(val.value[0]); m_player.volMax.set(val.value[1]) }, [0.9, 1.0]);

			// Pan range
			m_player.layout.nextLine;
			m_player.pan = Bus.control(s, 1).value = 0;

			m_player.panMin = Bus.control(s, 1).value = -0.5;
			m_player.panMax = Bus.control(s, 1).value = 0.5;
			m_player.panSpec = ControlSpec(-1.0, 1.0, \lin, step: 0, default: 0);

			m_player.panGui = EZRanger(m_player.window, 350@20, "Pan", m_player.panSpec,
			{ |val| m_player.panMin.set(val.value[0]);	m_player.panMax.set(val.value[1])}, [-0.5,0.5]);

			// Pitch range
			m_player.layout.nextLine;
			m_player.pitch = Bus.control(s, 1).value = 0;

			m_player.pitchMin = Bus.control(s, 1).value = 0.99;
			m_player.pitchMax = Bus.control(s, 1).value = 1.01;
			m_player.pitchSpec = ControlSpec(0.01, 5.0, \lin, step: 0, default: 1);

			m_player.pitchGui = EZRanger(m_player.window, 350@20, "Pitch", m_player.pitchSpec,
			{ |val| m_player.pitchMin.set(val.value[0]);	m_player.pitchMax.set(val.value[1])}, [0.99,1.01]);

			// Duration range
			m_player.layout.nextLine;
			m_player.durMin = Bus.control(s, 1).value = 0.2;
			m_player.durMax = Bus.control(s, 1).value = 0.25;
			m_player.durSpec = ControlSpec(0.001, 1, \lin, step: 0, default: 1);

			m_player.durGui = EZRanger(m_player.window, 350@20, "Duration", m_player.durSpec,
			{ |val| m_player.durMin.set(val.value[0]);	m_player.durMax.set(val.value[1])}, [0.2,0.25]);

			// Position range
			m_player.layout.nextLine;
			m_player.pos = Bus.control(s, 1).value = 0;

			m_player.posMin = Bus.control(s, 1).value = 0.1;
			m_player.posMax = Bus.control(s, 1).value = 0.12;
			m_player.posSpec = ControlSpec(0, 1.0, \lin, step: 0, default: 1);

			m_player.posGui = EZRanger(m_player.window, 350@20, "Position", m_player.posSpec,
			{ |val| m_player.posMin.set(val.value[0]);	m_player.posMax.set(val.value[1])}, [0.1,0.12]);

			// Density range
			m_player.layout.nextLine;
			m_player.dens = Bus.control(s, 1).value = 0;

			m_player.densMin = Bus.control(s, 1).value = 20;
			m_player.densMax = Bus.control(s, 1).value = 30;
			m_player.densSpec = ControlSpec(5, 100, \lin, step: 0, default: 1);

			m_player.densGui = EZRanger(m_player.window, 350@20, "Density", m_player.densSpec,
			{ |val| m_player.densMin.set(val.value[0]);	m_player.densMax.set(val.value[1])}, [20,30]);

			// puls range
			m_player.puls = Bus.control(s, 1).value = 20;
			m_player.pulsSpec = ControlSpec(1, 100, \lin, step: 0, default: 0);
			m_player.layout.nextLine;

			m_player.pulsGui =EZSlider(m_player.window, 350@20, "Puls", m_player.pulsSpec,
			{ |val| m_player.puls.set(val.value)}, 20);

			m_player.layout.nextLine;*/

		};

		m_player[\setRanger] = { |name, values|

			var min = values[0], max = values[1];
			var preMin = values[2], preMax = values [3];

			postf("Parametername: %, Received Values: %\n", name, values);

			m_player.layout.nextLine;


			m_player[(name++"Min").asSymbol] = preMin;
			m_player[(name++"Max").asSymbol] = preMax;

			m_player[(name++"MinBus").asSymbol]= Bus.control(s, 1).value = preMin;
			m_player[(name++"MaxBus").asSymbol] = Bus.control(s, 1).value = preMax;


			m_player[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			m_player[(name++"Gui").asSymbol] = EZRanger(m_player.window, 350@20, name, m_player[(name++"Spec").asSymbol],
				{ |sl|
					m_player[(name++"Control").asSymbol].value(sl.value);

			}, [preMin, preMax]);

			m_player[(name++"Control").asSymbol] = { |val|
				m_player[(name++"MinBus").asSymbol].set(val[0]);
				m_player[(name++"Min").asSymbol] = val[0];

				m_player[(name++"MaxBus").asSymbol].set(val[1]);
				m_player[(name++"Max").asSymbol] = val[1];

				postf("Value: %\n", val);

				if (m_player[(name++"Gui").asSymbol].value != val,
					{ m_player[(name++"Gui").asSymbol].value = val; })
			};

		};

		m_player[\setSlider] = { |name, values|

			var min = values[0], max = values[1], currentVal = values[3];

			postf("Slider Parametername: %, Received Values: %\n", name, values);

			m_player.layout.nextLine;

			m_player[(name++"Val").asSymbol] = currentVal;

			m_player[(name++"Bus").asSymbol]= Bus.control(s, 1).value = currentVal;

			m_player[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			"here".postln;

			m_player[(name++"Gui").asSymbol] = EZSlider(m_player.window, 350@20, name, m_player[(name++"Spec").asSymbol],
				{ |val| m_player[(name++"Control").asSymbol].value(val.value)}, currentVal);

			m_player[(name++"Control").asSymbol] = { |val|
				m_player[(name++"Bus").asSymbol].set(val);
				m_player[(name++"Val").asSymbol] = val;

				postf("Value: %\n", val.value);

				if (m_player[(name++"Gui").asSymbol].value != val,
					{ m_player[(name++"Gui").asSymbol].value = val; })
			}

		};

		/*EZKnob*/

		// ----------------------------------------------------------------------
		//                                       grainplayer - Controls
		// ----------------------------------------------------------------------

		// Wenn es einen MVC-erfordert: m_player.startbutton = Bus.control();

		m_player.granulator2 = {

			m_player.list = [
				'pos', [0, 1, 0.1, 0.5], "Ranger",
				'vol', [0, 2, 0.9, 1], "Ranger",
				'pan', [-1.0, 1.0, -1.0, 1], "Ranger",
				'pitch', [0.01, 5.0, 0.99, 1.01], "Ranger",
				'dur', [0.01, 2, 0.1, 1.25], "Ranger",
				'dens', [0.0001, 0.5, 0.01, 0.05], "Ranger",
			];

			m_player[\makeGui] = { | values |

				var quant = values.size/3;

				quant.do { |i|
					var name = values[i*3];
					var varis = values[(i*3)+1];
					var type = values[(i*3)+2];

					postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);

					m_player[("set"++type).asSymbol].value(name, varis);
				};
			};

			m_player[\makeGui].value(m_player.list);


			// selection range

			/*m_player.posMin  = 0.1;
			m_player.posMax  = 0.5;
			m_player.posSpec = ControlSpec(0, 1, \lin, step: 0, default: 0);

			m_player.layout.nextLine;

			m_player.posGui =EZRanger(m_player.window, 350@20, "Position", m_player.posSpec,
			{ |val|
			m_player.posMin = val.value[0];
			m_player.posMax = val.value[1];
			}, [0.1, 0.5]);

			// volume range

			m_player.volMin = 0.9;
			m_player.volMax = 1;
			m_player.volSpec = ControlSpec(0, 2, \lin, step: 0, default: 0);

			m_player.layout.nextLine;

			m_player.volGui = EZRanger(m_player.window, 350@20, "Volume", m_player.volSpec,
			{ |val|
			m_player.volMin = val.value[0];
			m_player.volMax = val.value[1]
			}, [0.9, 1]);

			// Pan range

			m_player.layout.nextLine;
			m_player.pan = Bus.control(s, 1).value = 0;

			m_player.panMin = -1.0;
			m_player.panMax = 1.0;
			m_player.panSpec = ControlSpec(-1.0, 1.0, \lin, step: 0, default: 0);

			m_player.panGui = EZRanger(m_player.window, 350@20, "Pan", m_player.panSpec,
			{ |val|
			m_player.panMin = val.value[0];
			m_player.panMax = val.value[1]
			}, [-1.0,1]);

			// Pitch range

			m_player.layout.nextLine;
			m_player.pitch = Bus.control(s, 1).value = 0;

			m_player.pitchMin = 0.99;
			m_player.pitchMax = 1.01;
			m_player.pitchSpec = ControlSpec(0.01, 5.0, \lin, step: 0, default: 1);

			m_player.pitchGui = EZRanger(m_player.window, 350@20, "Pitch", m_player.pitchSpec,
			{ |val|
			m_player.pitchMin = val.value[0];
			m_player.pitchMax = val.value[1]
			}, [0.99,1.01]);

			// Duration range

			m_player.layout.nextLine;
			m_player.durMin = 0.1;
			m_player.durMax = 0.15;

			m_player.durSpec = ControlSpec(0.01, 2.0, \lin, step: 0, default: 1);

			m_player.durGui = EZRanger(m_player.window, 350@20, "Duration", m_player.pitchSpec,
			{ |val|
			m_player.durMin = val.value[0];
			m_player.durMax = val.value[1]
			}, [0.1,1.15]);

			// Density Range

			m_player.layout.nextLine;
			m_player.densMin =  0.01;
			m_player.densMax = 0.05;

			m_player.densSpec = ControlSpec(0.0001, 0.5, \lin, step: 0, default: 1);

			m_player.densGui = EZRanger(m_player.window, 350@20, "Density", m_player.densSpec,
			{ |val|
			m_player.densMin = val.value[0];
			m_player.densMax = val.value[1]
			}, [0.01,0.05]);*/

		};

		// -------------------  Soundfile-Player-Start

		m_player.samplerOn= { arg command;

			m_player.track = Synth.head(source, \sfplayer, [\sndbuf, m_player.buffer, \rate, 1, \loop, 0]);
			m_player.track.map(\amp, m_player.volume);
			m_player.track.map(\pan, m_player.pan);
		};

		// -------------------  Soundfile-Player-Stop

		m_player.samplerOff= { arg command;

			m_player.track.release(0.2);
			m_player.track.free;

		};

		// -------------------  Soundfile-Granulator-Start

		m_player.granulator1On= { arg command;


			m_player.track = Synth.head(source, \granulator1, [\sndbuf, m_player.buffer, \envbuf, -1]);
			m_player.track.map(\volMin, m_player.volMinBus);
			m_player.track.map(\volMax, m_player.volMaxBus);
			m_player.track.map(\panMin, m_player.panMinBus);
			m_player.track.map(\panMax, m_player.panMaxBus);
			m_player.track.map(\durMin, m_player.durMinBus);
			m_player.track.map(\durMax, m_player.durMaxBus);
			m_player.track.map(\posMin, m_player.posMinBus);
			m_player.track.map(\posMax, m_player.posMaxBus);
			m_player.track.map(\pitchMin, m_player.pitchMinBus);
			m_player.track.map(\pitchMax, m_player.pitchMaxBus);
			m_player.track.map(\densMin, m_player.densMinBus);
			m_player.track.map(\densMax, m_player.densMaxBus);
			m_player.track.map(\puls, m_player.pulsBus);



		};

		// ------------------- Soundfile-Granulator-Stop

		m_player.granulator1Off= { arg command;

			m_player.track.set(\gate, 0);

			m_player.track.free;

		};

		m_player.granulator1Task1 = Task {

			// Something to do

		};

		m_player.granulator2On= { arg command;

			m_player.granulator2Task.start;

		};

		m_player.granulator2Off= { arg command;

			m_player.granulator2Task.stop;

		};

		m_player.granulator2Task = Task {

			var dur, time;
			var selection, volume, pitch, pan, grainlength;

			loop {

				dur = rrand(m_player[\densMin], m_player[\densMax]);
				time = dur;

				if (time < 0.0001, {time = 0.0001});

				m_player.track = Synth.head(source, \granulator2,
					[\bufnum, m_player.buffer,
						\startPos, m_player[\posMin].rrand(m_player[\posMax]),
						\amp, m_player[\volMin].rrand(m_player[\volMax]),
						\rate, m_player[\pitchMin].rrand(m_player[\pitchMax]),
						\pan, m_player[\panMin].rrand(m_player[\panMax]),
						\sustain, m_player[\durMin].rrand(m_player[\durMax]),
						\channels, ~outChannels
				]);

				time.wait;
			};

		};

		mode.postln;
		m_player.controls.value;
		m_player[mode.asSymbol].value;
		//if (mode == "Granulator", {m_player.createGranulator.value});



		m_player;

	};

	~granulator1 = ~m_player.value(~granulator1, "granulator1");
	~granulator2 = ~m_player.value(~granulator2, "granulator2");
	~sampler = ~m_player.value(~sampler, "sampler");
	//player.start;

})

);

GetFileDialog
FileDialog.new({ |path| path.postln }, {}, 2, 0);
Dialog.openPanel

m = ()
m.test = 1
m[\test]

~granulator1.granulator1Off;
~granulator1[\pulsControl].value(1);

