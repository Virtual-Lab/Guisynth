
// ----------------------------------------------------------------------
//                                  make Player Prototype - Pseudoclass
// ----------------------------------------------------------------------

~m_player = {
	arg object, mode,
	m_window = ~object1, height = 360, width = 500,
	poly = 1, gui = True, bufnum = 0,
	file = False, list = [];

	var slider, instance;

	// ----------------------------------------------------------------------
	//                      Settings of the instrument
	// ----------------------------------------------------------------------

	object = ();
	object.out = Bus.audio(s, ~channelsOut2);

	/* if(~cloud == true, {
	object[\csOut] = Array.newClear(~cs[\clients].size+1);

	~cs[\clients].do { |i|
	object[\csOut][i] = Bus.audio(~cs[\server][i], 2);
	};
	});*/

	// store instrument
	~instruments = ~instruments.add(object);

	// set the bufnum of the sampler/granulator
	object.bufnumber = bufnum;

	if (list.size > 1, { object[\list] = list });

	// ----------------------------------------------------------------------
	//              create a Window for the instrument within the ~main Window
	//              and flexible flow-Layout
	// ----------------------------------------------------------------------
	object.createWindow = {

		if(object.window != nil, {object.window.close});
		object.window = CompositeView(m_window, Rect(0, 0, width, height)).front
		.onClose_({object.window.free});

		//object.window = ~main.window;

		// FlowLayout (flexible layout)
		object[\window].decorator =  FlowLayout(object.window.bounds);
		object.layout = object.window.decorator;

		// labeling the window
		object.label = CompositeView(object.window, Rect(0, 0, 500, 18))
		.background_(Color.grey(0.6));
		object.label.decorator = FlowLayout(object.label.bounds, 4@0, 0@2);
		object.labeltext = StaticText(object.label, 100@18)
		.string_(mode)
		.font_(Font("Helvetica-bold", 14))
		.stringColor_(Color.white);
		//.background_(Color.blue);
	};

	// ----------------------------------------------------------------------
	//                make Soundfile-Window - set default bufferlength
	// ----------------------------------------------------------------------

	if (file != False, {

		//object.sfsource = ""; //Array.fill(~instrument, s.sampleRate * 30);
		object.bufferlength = 5.0; //bufferlength of 5 seconds
		//object.buffer = Buffer.alloc(s, s.sampleRate * 5.0, 1, bufnum: i);  // create a buffer
		//object.soundfile = SoundFile.new; // read a soundfile - create a dummy
		object.buffer = Buffer.readChannel(s, object.sfsource, channels: 0);
		object.file = 1;

	});

	// ******************** setup Inputs

	object.setInput = {

		object.inputs = ~channelsIn;
		object.recChannels = 1;
		object.recBus = Bus.audio(s, object.recChannels);

		object.inputLevel = 0;
		object.inputView = 0;

		object.in = 0;

		object.input = Synth.tail(~input, \levelmeter,
			[\in, object.recBus]);

	}.value;

	object.inputGui = {

		object.inputLevel = LevelIndicator(object.label, 120@18);

		object.inputLevelView = OSCFunc(

			{ |msg, time, cmdname|
				var level, peak, number;

				number = msg[2].value;
				level = (msg[3].value).ampdb.linlin(-80, 0, 0, 1);
				peak = (msg[4].value).ampdb.linlin(-80, 0, 0, 1);

				{
					object[\inputLevel].value = level;
					object[\inputLevel].peakLevel = peak;
				}.defer;
				/*[level, peak].postln;
				postf("OSC Message: %\n", msg);*/
		}, '/levelmeter', s.addr, nil, [object.input.nodeID]);
	};

	// ******************** choose Inputs
	object.chooseInput = {

		object.inputLabel = StaticText(object.label, 50@18)
		.string_("  Inputs: ");

		object.inputNumber = ~channelsIn;
		object.inputButton = Array.fill(~channelsIn, 0);

		object.inputButtonValue = Array.fill(~channelsIn, 0);
		object.inputButtonBus = Array.fill(~channelsIn, 0);
		object.inputButtonMatrix = Array.fill(~channelsIn, {});

		CompositeView(object.label, 5@10); // spacer for Layout

		~channelsIn.do { |k|

			k.postln;
			object.inputButton[k] = CheckBox(object.label, 18@18)
			.string_(k)
			//.states_([["", Color.black, Color.white], ["", Color.black, Color.red]])
			.action_({ |val| object.inputButtonValue[k] = val.value;
				//object.inputButtonValue[k].postln;

				if (object.inputButtonValue[k] == true,
					{object.inputButtonBus[k] = Synth.head(~input, \soundIn,
						[\in, k, \out, object.recBus]);
					}, {
						object.inputButtonBus[k].free;
				});



				postf("Button %: %\n", k, object.inputButtonValue[k]);
			});
		}
	};



	if (gui != False, {

		object.createWindow.value;
		object.inputGui.value;
		object.chooseInput.value;

		// create a waveform window
		object.sfwindow = SoundFileView.new(object.window, Rect(10, 8, 500, 80));

		// ----------------------------------------------------------------------
		//                                  create a filebrowser with a Popup - Menue
		// ----------------------------------------------------------------------//

		object.createBrowser = {

			object.filebrowser = PopUpMenu(object.window, Rect(0,0,200,20));
			object.folder = PathName.new("/sounds/");
			object.files = PathName.new("/sounds/").files;

			object.filenames = Array.fill(object.files.size, { |index| object.files[index].fileName});
			object.filebrowser.items = object.filenames;
			object.filebrowser.value = rand(object[\files].size);

			object.sfsource = object.files[object.filebrowser.value].fullPath;

			object.buffer = Buffer.readChannel(s, object.sfsource, channels: 0);

			object[\cbuff] = ();

			~cs[\server].size.do { |i|

				object[\cbuff][i] = Buffer.readChannel(~cs[\server][i], object.sfsource, channels: 0);

				//object[\cbuff] = ~cs[\cbuf].(object[\cbuff], object[\sfsource], ~cs[\server]);

				object.file = 1;
			};

		};

		object.createBrowser.value;

		// ----------------------------- Filebrowser - Action

		object.filebrowser.action = { |selection|

			// load Filepath
			object.drawSoundfile.stop;
			object.sfsource = object.files[selection.value].fullPath;



			~cs[\server].size.do { |i|

				object[\cbuff][i] = Buffer.readChannel(~cs[\server][i], object.sfsource, channels: 0);

				//object[\cbuff] = ~cs[\cbuf].(object[\cbuff], object[\sfsource], ~cs[\server]);

				object.files[object.filebrowser.value].postln;
				object.sfsource.postln;
				object.refreshSoundfileView.value();

			};

		};

		// ******************** Parameter Gui und Action

		object.sfwindow.action = {
			object.selectionstart  = object.sfwindow.selection(0)[0] / object.buffer.numFrames;
			object.selectionlength = object.sfwindow.selection(0)[1] / object.buffer.numFrames;
			object[\posControl].value(
				[object.selectionstart,(object.selectionstart + object.selectionlength)]);
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

		// ******************** Record - Button
		object.record = Bus.control(s, 1);
		object.bufferlength = 3;
		object.recordValue = 0;

		object.recordSound = {
			//---------------------------------------------------
			//                   Sound - Record
			//---------------------------------------------------
			object[\recordbuffer] = Synth.tail(~synths, \bufferRec,
				[\bufnum, object[\bufnumber], \in, object.recBus ]);

			object[\recordbuffer].map(\rec, object.record); // start rec
			//object[\recordbuffer].map(\inBus, ~instrumentBus[i]);
			// ~record.set(\rec, 0);   // stop rec

			"SoundRecord enabled".postln;
			("Input: " ++ object.recBus).postln;
		}.value;

		object.recordGui = Button(object.window, Rect(0,0,50,20))
		.states_([["record", Color.black, Color.white], ["record", Color.black, Color.red]])
		.action_({ |val|
			object.record.set(val.value);
			object.recordValue = val.value;
			val.value.postln;

			if (val.value == 0, {
				//object.file = true;
				object.drawSoundfile.stop;
				// object.recordbuffer.free;
			}, {
				object.buffer = Buffer.alloc
				(s, s.sampleRate * object.bufferlength, 1,
					{ object.drawSoundfile.start; object.file = 0},
					bufnum: object[\bufnumber];
				);

				"buffer renewed".postln;

				postf("Record: %\n", object.recordValue);

			});

		});


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

	object.bufferGui = NumberBox(object.window, Rect(0,0,55,20));
	object.bufferGui.value = object.bufferlength;
	object.bufferGui.action = { |val| object.bufferlength = val.value;
		if (object.bufferlength < 0.01, {object.bufferlength = 0.01});
		object.buffer = Buffer.alloc(s, s.sampleRate * object.bufferlength, 1);

		object.drawSoundfile.reset;
		object.drawSoundfile.start;
	};

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
			'puls', [1, 100, 1], "Slider",
			'cloud', [0, 1, 0], "Slider",
			'reverb', [0, 1, 0], "Slider",
			'delay', [0, 1, 0], "Slider",
		];

	};



	object.granulator2 = {

		object.list = [
			'pos', [0, 1, 0.1, 0.5], "Ranger",
			'vol', [0, 2, 0.9, 1], "Ranger",
			'pan', [-0.5, 0.5, -1.0, 1], "Ranger",
			'pitch', [0.01, 5.0, 0.99, 1.01], "Ranger",
			'dens', [0.0001, 0.5, 0.01, 0.05], "Ranger",
			'dur', [0.01, 2, 0.1, 1.25], "Ranger",
			'hanning', [0, 3, 0], "Slider",
			'attac', [0, 1, 0.01], "Slider",
			'release', [0, 1, 0.1], "Slider",
			'cloud', [0, 1, 0], "Slider",
			'reverb', [0, 1, 0], "Slider",
			'delay', [0, 1, 0], "Slider",
		];

	};

	/*EZKnob*/

	// ----------------------------------------------------------------------
	//                                       grainplayer - Controls
	// ----------------------------------------------------------------------

	// Wenn es einen MVC-erfordert: object.startbutton = Bus.control();


	// -------------------  Soundfile-Player-Start

	object.samplerOn= { arg command;

		object.track = Synth.head(~synths, \sfplayer,
			[\sndbuf, object.buffer, \rate, 1, \loop, 0, \out, object[\out].index]);
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


		object.track = Synth.head(~synths, \granulator1,
			[\sndbuf, object.buffer, \envbuf, -1, \out, object[\out].index]);
		object.track.map(\vol, object.volBus);
		object.track.map(\pan, object.panBus);
		object.track.map(\dur, object.durBus);
		object.track.map(\pos, object.posBus);
		object.track.map(\pitch, object.pitchBus);
		object.track.map(\dens, object.densBus);
		object.track.map(\puls, object.pulsBus);
		object.track.map(\effect1, object.reverbBus);
		object.track.map(\effect2, object.delayBus);



		object[\ctrack] = ~cs[\synth].(object[\ctrack], \granulator1,
			[\envbuf, -1, \out, 0, \effect1Out, 20, \effect2Out, 40], ~cs[\server]);

		object[\ctrack][\cbuf].(\sndbuf, object[\cbuff]);
		object[\ctrack][\cmap].(\vol, object[\volCBus]);
		object[\ctrack][\cmap].(\pan, object[\panCBus]);
		object[\ctrack][\cmap].(\dur, object[\durCBus]);
		object[\ctrack][\cmap].(\pos, object[\posCBus]);
		object[\ctrack][\cmap].(\pitch, object[\pitchCBus]);
		object[\ctrack][\cmap].(\dens, object[\densCBus]);
		object[\ctrack][\cmap].(\puls, object[\pulsCBus]);
		object[\ctrack][\cmap].(\cloud, object[\cloudCBus]);
		object[\ctrack][\cmap].(\effect1, object[\reverbCBus]);
		object[\ctrack][\cmap].(\effect2, object[\delayCBus]);

	};

	// ------------------- Soundfile-Granulator-Stop

	object.granulator1Off= { arg command;

		object.track.set(\gate, 0);
		object.track.free;


		object[\ctrack].[\cset].(\gate, 0);
		object[\ctrack].cfree;
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

			dur = rrand(object[\densVal][0], object[\densVal][1]);
			time = dur;

			if (time < 0.001, {time = 0.001});

			object.track = Synth.head(~synths, \granulator2,
				[\bufnum, object.buffer,
					\out, object[\out].index,
					\startPos, object[\posVal][0].rrand(object[\posVal][1]),
					\amp, object[\volVal][0].rrand(object[\volVal][1]),
					\rate, object[\pitchVal][0].rrand(object[\pitchVal][1]),
					\pan, object[\panVal][0].rrand(object[\panVal][1]),
					\sustain, object[\durVal][0].rrand(object[\durVal][1]),
					\hanning, object[\hanningVal].floor,
					\attac, object[\attacVal],
					\release, object[\releaseVal],
					\effect1, object[\reverbVal],
					\effect2, object[\delayVal],
			]);


			object[\ctrack] = ~cs[\synth].(object[\ctrack], \granulator2,
				[
					\out, 0, \effect1Out, 20, \effect2Out, 40,
					\startPos, object[\posVal][0].rrand(object[\posVal][1]),
					\amp, object[\volVal][0].rrand(object[\volVal][1]),
					\rate, object[\pitchVal][0].rrand(object[\pitchVal][1]),
					\pan, object[\panVal][0].rrand(object[\panVal][1]),
					\sustain, object[\durVal][0].rrand(object[\durVal][1]),
					\hanning, object[\hanningVal].floor,
					\attac, object[\attacVal],
					\release, object[\releaseVal],
					\effect1, object[\reverbVal],
					\effect2, object[\delayVal],
					\cloud, object[\cloudVal],

			], ~cs[\server], sndbuf: object[\cbuff]);

			//object[\ctrack][\cbuf].(\sndbuf, object[\cbuff]);


			time.wait;
		};

	};




	// ----------------------------------------------------------------------
	//                        Draw Controls and Values
	// ----------------------------------------------------------------------

	object[mode.asSymbol].value;

	// draw the toggles, sliders and rangers

	~controls[\toggle].value(['On', 'Off'], object, mode);

	//object.layout.nextLine;

	object[\makeGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var varis = values[(i*3)+1];
			var type = values[(i*3)+2];

			//postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);
			gui.postln;

			~controls[("set"++type).asSymbol].value(name, varis, object, mode);
		};
	};

	object[\drawGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].start;
			})
		};
	};

	object[\stopGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].start;
			})
		};
	};


	object[\makeGui].value(object.list);

	if (gui != False, {

		object.refreshSoundfileView.value();
		//object[\drawGui].value(object.list);

	});



	object;

};

~m_synth = {
	arg object, mode,
	m_window = ~object2, height = 300, width = 500,
	poly = 1, gui = True,
	mono = [4, 0], stereo = [2, 4],
	list = [];

	var slider, instance;

	// ----------------------------------------------------------------------
	//                      Settings of the instrument
	// ----------------------------------------------------------------------

	object = ();
	object.out = Bus.audio(s, ~channelsOut2);
	object[\csOut] = ();

	~cs[\clients].do { |i|
		object[\csOut][i] = Bus.audio(~cs[\server][i], 2);
	};

	// store instrument
	~instruments = ~instruments.add(object);

	// ----------------------------------------------------------------------
	//              create a Window for the instrument within the ~main Window
	//              and flexible flow-Layout
	// ----------------------------------------------------------------------
	object.createWindow = {

		if(object.window != nil, {object.window.close});
		object.window = CompositeView(m_window, Rect(0, 0, width, height)).front
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

	if (gui !=False, { object.createWindow.value });

	// ----------------------------------------------------------------------
	//                      Controls
	// ----------------------------------------------------------------------

	// presettings of Synth Defs, ...;

	object.glocke1 = {

		object.list = [
			'trigger', [0, 20, 0.2], "Trigger",
			'volume', [0, 2, 0.5], "Knob",
			'freq', [40, 2000, 220], "Knob",
			'xpan', [-0.5, 0.5, 0], "Knob",
			'attack', [0, 5.0, 0.01], "Knob",
			'decay', [0, 2, 0.1], "Knob",
			'sustain', [0, 1, 0.6], "Knob",
			'release', [0, 10, 0.2], "Knob",
			'cloud', [0, 1, 0], "Knob",
			//'curve', [-5, 5, -4], "Slider",
			//'stream1', [0, 1, 0.2], "Slider",
			//'distort', [0, 1, 0], "Slider",
			//'dur', [0, 20, 0.5], "Slider",
		];

	};

	object.glocke2 = {

		object.list = [
			'trigger', [0, 20, 0.2], "Trigger",
			'volume', [0, 2, 0.5, 1], "Ranger",
			'freq', [40, 1000, 220, 222], "Ranger",
			'xpan', [-0.5, 0.5, -0.1, 0.1], "Ranger",
			'hold', [0, 10, 0.04, 0.1], "Ranger",
			'dens', [0.0001, 0.5, 0.15, 0.2], "Ranger",
			'stream1', [0, 1, 0.2], "Slider",
			'cloud', [0, 1, 0.2], "Slider",
			'attack', [0, 5.0, 0], "Knob",
			'decay', [0, 2, 0.05], "Knob",
			'sustain', [0, 1, 0.6], "Knob",
			'release', [0, 10, 0.4], "Knob",
			'ts', [0.01, 10, 1], "Knob",
			'curve', [-5, 5, -4], "Knob",
			'spread', [-5, 5, -0.5], "Knob",
			'reverb', [0, 1, 0], "Knob",
		];

	};

	object.brummel = {

		object.list = [
			'trigger', [0, 20, 5], "Trigger",
			'freq1', [20, 8000, 220], "Slider",
			'freq2', [0, 50, 15], "Slider",
			'width', [0, 1, 0.5], "Slider",
			'puls1', [0, 5.0, 0.8], "Slider",
			'puls2', [0, 5, 1], "Slider",
			'volume', [0, 1, 0.6], "Slider",
			//'stream1', [0, 1, 0.8], "Slider"
		];

	};

	// ----------------------------------------------------------------------
	//                        Synth Player Controls
	// ----------------------------------------------------------------------


	// -------------------  Glockensynth-Start

	object.glocke1On= { arg command;

		object.track = Synth.head(~synths, \glocke1, [\gate, 1, \out, object[\out].index]);
		object.track.map(\volume, object.volumeBus);
		object.track.map(\freq, object.freqBus);
		object.track.map(\xpan, object.xpanBus);
		object.track.map(\attack, object.attackBus);
		object.track.map(\decay, object.decayBus);
		object.track.map(\sustain, object.sustainBus);
		object.track.map(\release, object.releaseBus);
		object.track.map(\ts, object.tsBus);
		//object.track.map(\curve, object.curveBus);
		object.track.map(\effect1, object.reverbBus);


		object[\cloudsynth1] = ~cs[\synth].(object[\cloudsynth1], \glocke1,
			[\gate, 1, \out, 0, \effect1Out, 20], ~cs[\server]);

		object[\cloudsynth1][\cmap].(\volume, object[\cloudCBus]);
		object[\cloudsynth1][\cmap].(\freq, object[\freqCBus]);
		object[\cloudsynth1][\cmap].(\xpan, object[\xpanCBus]);
		object[\cloudsynth1][\cmap].(\attack, object[\attackCBus]);
		object[\cloudsynth1][\cmap].(\decay, object[\decayCBus]);
		object[\cloudsynth1][\cmap].(\sustain, object[\sustainCBus]);
		object[\cloudsynth1][\cmap].(\release, object[\releaseCBus]);
		//object[\cloudsynth1][\cmap].(\ts, object[\tsCBus]);
		//object[\track].map(\curve, object[\curveCBus]);
		//object[\cloudsynth1][\cmap].(\effect1, object[\reverbCBus]);


	};

	object.glocke1trigger = Task { arg command;

		"Synth1 triggered!".postln;

		object.track2 = Synth.head(~synths, \glocke1, [\gate, 1, \out, object[\out].index]);
		object.track2.set(\volume, object.cloudVal);
		object.track2.set(\freq, object.freqVal);
		object.track2.set(\xpan, object.xpanVal);
		object.track2.set(\attack, object.attackVal);
		object.track2.set(\decay, object.decayVal);
		object.track2.set(\sustain, object.sustainVal);
		object.track2.set(\release, object.releaseVal);
		object.track2.set(\ts, object.tsVal);
		//object.track2.set(\curve, object.curveVal);
		object.track2.set(\effect1, object.reverbVal);



		object[\cloudsynth12] = ~cs[\synth].(object[\cloudsynth12], \glocke1,
			[\gate, 1, \out, 0, \volume, 0, \effect1Out, 20], ~cs[\server]);

		//object[\cloudsynth12].cbus.(\effect1Out, ~cs[\effect1]);
		object[\cloudsynth12][\cset].(\volume, object.cloudVal);
		object[\cloudsynth12][\cset].(\freq, object.freqVal);
		object[\cloudsynth12][\cset].(\xpan, object.xpanVal);
		object[\cloudsynth12][\cset].(\attack, object.attackVal);
		object[\cloudsynth12][\cset].(\decay, object.decayVal);
		object[\cloudsynth12][\cset].(\sustain, object.sustainVal);
		object[\cloudsynth12][\cset].(\release, object.releaseVal);
		//object[\cloudsynth12][\cset].(\ts, object.tsVal);
		//object.track.set(\curve, object.curveVal);
		//object[\cloudsynth12][\cset].(\effect1, object.reverbVal);




		object[\triggerTime].wait;

		object.track2.release;



		object[\cloudsynth12].crelease;





	};

	// -------------------  Soundfile-Player-Stop

	object.glocke1Off= { arg command;

		object.track.release;
		//object.track.free;



		object[\cloudsynth1].crelease;




	};

	object.glocke2On= { arg command;

		object.glocke2Task.start;

	};

	object.glocke2Off= { arg command;

		object.glocke2Task.stop;

	};

	object.glocke2Task = Task {

		var dur, time;
		var densMin, densMax, volMin, volMax, freqMin, freqMax, xpanMin, xpanMax, holdMin, holdMax;

		//object[\cloudsynth2] = ();

		loop {
			/*densMin = object[\densBus].getn(2, {|val| val[0]});
			densMax = object[\densBus].getn(2, {|val| val[1]});*/

			time = object[\densVal][0].rrand(object[\densVal][1]);

			if (time < 0.001, {time = 0.001});

			object.track = Synth.head(~synths, \glocke2,
				[\out, object[\out].index,
					\volume, object[\volumeVal][0].rrand(object[\volumeVal][1]),
					\freq, object[\freqVal][0].rrand(object[\freqVal][1]),
					\xpan, object[\xpanVal][0].rrand(object[\xpanVal][1]),
					\hold, object[\holdVal][0].rrand(object[\holdVal][1]),
					\attack, object[\attackVal],
					\decay, object[\decayVal],
					\sustain, object[\sustainVal],
					\release, object[\releaseVal],
					\curve, object[\curveVal],
					\ts, object[\tsVal],
					\spread, object[\spreadVal],
					\effect1, object[\reverbVal],
			]);



			object[\cloudsynth2] = ~cs[\synth].(object[\cloudsynth2], \glocke2,
				[
					\volume, object[\volumeVal][0].rrand(object[\volumeVal][1])*object[\cloudVal],
					\xpan, object[\xpanVal][0].rrand(object[\xpanVal][1]),
					\freq, object[\freqVal][0].rrand(object[\freqVal][1]),
					\hold, object[\holdVal][0].rrand(object[\holdVal][1]),
					\attack, object[\attackVal],
					\decay, object[\decayVal],
					\sustain, object[\sustainVal],
					\release, object[\releaseVal],
					\curve, object[\curveVal],
					\ts, object[\tsVal],
					\spread, object[\spreadVal],
					\effect1, object[\reverbVal],
			], ~cs[\server]);

			/*object[\cloudsynth2][\cpan].(
			object[\xpanVal][0].rrand(object[\xpanVal][1],
			object[\volumeVal][0].rrand(object[\volumeVal][1])*object[\cloudVal]));*/


			time.wait;
		};

	};

	object.glocke2trigger = Task { arg command;

		object.track2 = Synth.head(~synths, \glocke2, [\gate, 1, \out, object[\out].index]);
		object.track2.set(\volume, object.volumeVal);
		object.track2.set(\freq, object.freqVal);
		object.track2.set(\xpan, object.xpanVal);
		object.track2.set(\attack, object.attackVal);
		object.track2.set(\decay, object.decayVal);
		object.track2.set(\sustain, object.sustainVal);
		object.track2.set(\release, object.releaseVal);
		object.track2.set(\ts, object.tsVal);
		object.track2.set(\curve, object.curveVal);
		object.track2.set(\effect1, object.reverbVal);



		object[\cloudsynth2] = ~cs[\synth].(object[\cloudsynth2], \glocke2,
			[\gate, 1, \out, 0, \effect1Out, 20], targets:~cs[\server]);

		object[\cloudsynth2][\cset].(\volume, object.cloudVal);
		object[\cloudsynth2][\cset].(\freq, object.freqVal);
		object[\cloudsynth2][\cset].(\xpan, object.xpanVal);
		object[\cloudsynth2][\cset].(\attack, object.attackVal);
		object[\cloudsynth2][\cset].(\decay, object.decayVal);
		object[\cloudsynth2][\cset].(\sustain, object.sustainVal);
		object[\cloudsynth2][\cset].(\release, object.releaseVal);
		object[\cloudsynth2][\cset].(\ts, object.tsVal);
		object[\cloudsynth2][\cset].(\curve, object.curveVal);
		object[\cloudsynth2][\cset].(\effect1, object.reverbVal);



		object[\triggerTime].wait;

		object[\track2].free;



		object[\cloudsynth2].[\cset].(\gate, 0);
		object[\cloudsynth2].crelease;



	};

	object.brummelOn= { arg command;

		object.track = Synth.head(~synths, \brummel, [\volume, 1, \out, object[\out].index]);
		object.track.map(\freq1, object.freq1Bus);
		object.track.map(\freq2, object.freq2Bus);
		object.track.map(\width, object.widthBus);
		object.track.map(\puls1, object.puls1Bus);
		object.track.map(\puls2, object.puls2Bus);
		object.track.map(\volume, object.volumeBus);

	};

	object.brummelOff= { arg command;

		object.track.free;

	};

	object.brummeltrigger = Task { arg command;

		1.do {

			object.track = Synth.head(~synths, \brummel, [\volume, 1, \out, object[\out].index]);
			object.track.set(\freq1, object.freq1Val);
			object.track.set(\freq2, object.freq2Val);
			object.track.set(\width, object.widthVal);
			object.track.set(\puls1, object.puls1Val);
			object.track.set(\puls2, object.puls2Val);
			object.track.set(\volume, object.volumeVal);

			object[\triggerTime].wait;

			object.track.release;
		};
	};

	// ----------------------------------------------------------------------
	//                        Draw Controls and Values
	// ----------------------------------------------------------------------

	object[mode.asSymbol].value;

	// draw the toggles, sliders and rangers

	~controls[\toggle].value(['On', 'Off'], object, mode, gui, object.label);

	//object.layout.nextLine;

	object[\makeGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var varis = values[(i*3)+1];
			var type = values[(i*3)+2];

			//postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);
			gui.postln;

			~controls[("set"++type).asSymbol].value(name, varis, object, mode, gui);
		}
	};

	object[\makeGui].value(object.list);

	object[\drawGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].start;
			})
		};
	};

	object[\stopGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];

			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].stop;
			})
		}
	};


	if (gui != False, {

		//object[\drawGui].value(object.list);

	});

	object;

};

// ----------------------------------------------------------------------
//                              Mixer Section
// ----------------------------------------------------------------------

~m_mixer = {
	arg object, mode,
	m_window = ~object3, height = 300, width = 360,
	poly = 1, gui = True,
	monoIn = 4, stereoIn = 0, multi = 4,
	stream = 1,
	//mono = nil, stereo = nil;
	list = [];

	var slider, instance, inBusses, busses;

	object = ();

	inBusses = monoIn + stereoIn;
	busses = monoIn + stereoIn + multi;

	// ----------------------------------------------------------------------
	//              create a Window for the instrument within the ~main Window
	//              and flexible flow-Layout
	// ----------------------------------------------------------------------
	object.createWindow = {

		if(object.window != nil, {object.window.close});
		object.window = CompositeView(m_window, Rect(0, 0, width, height)).front
		.onClose_({object.window.free});

		//object.window = ~main.window;

		// FlowLayout (flexible layout)
		object[\window].decorator =  FlowLayout(object.window.bounds);
		object.layout = object.window.decorator;

		// labeling the window
		object.label = CompositeView(object.window, Rect(0, 0, width, 18))
		.background_(Color.grey(0.6));
		object.label.decorator = FlowLayout(object.label.bounds, 4@0, 0@2);
		object.labeltext = StaticText(object.label, 60@18)
		.string_(mode)
		.font_(Font("Helvetica-bold", 14))
		.stringColor_(Color.white);
		//.background_(Color.blue);
	};

	if (gui !=False, { object.createWindow.value });

	// ----------------------------------------------------------------------
	//                      Presets
	// ----------------------------------------------------------------------

	// presettings of Synth Defs, ...;


	object.reverb = {
		object.list = [
			'gain', [0, 2, 1], "Knob",
			'room', [0, 1, 0.7], "Knob",
			'damp', [0, 1, 0.5], "Knob",
			'volume', [0, 2, 1], "Knob"
		];
	};

	object.delay = {
		object.list = [
			'gain', [0, 2, 1], "Knob",
			'buffer', [0.2, 2, 2], "Knob",
			'deltime', [0.001, 2, 0.25], "Knob",
			'volume', [0, 2, 1], "Knob"
		];
	};

	object.distort = {
		object.list = [
			'gain', [0, 2, 1], "Knob",
			'freq', [50, 5000, 2400], "Knob",
			'amount', [0.95, 0.999, 0.99], "Knob",
			'volume', [0, 2, 1], "Knob"
		];
	};

	object.mixer = {
		object.list = [
			'pan', [0, 1, 0.5], "Mixer",
			'reverb', [0, 1, 0.2], "Mixer",
			'delay', [0, 1, 0], "Mixer",
			'distort', [0, 1, 0], "Mixer",
			'cloud', [0, 1, 0], "Mixer",
			'stream', [0, 1, 0], "Mixer",
			'vol1', [0, 1, 0], "Mixer",
			'vol2', [0, 1, 0], "Mixer",
		];
	};

	object.stream = {
		object.list = [
			'volume', [0, 2, 1], "Knob",
			'tresh', [0.01, 1, 0.5], "Knob",
			'gate', [1, 5, 1], "Knob",
			'comp', [0.5, 10, 1], "Knob",
			//'cloud', [0, 2, 1], "Knob",
		];
	};

	object.master = {
		object.list = [
			'volume1', [0, 2, 1], "Knob",
			'volume2', [0, 2, 1], "Knob",
			'volume3', [1, 5, 1], "Knob",
			'volume4', [1, 5, 1], "Knob",
			//'cloud', [0, 2, 1], "Knob",
		];
	};

	object.mbus = {
		object.list = [
			'out1', [0, 2, 1], "Knob",
			'out2', [0, 2, 1], "Knob",
			'cloud', [0, 2, 1], "Knob",
			'level', [0, 1, 1], "Knob",
			//'cloud', [0, 2, 1], "Knob",
		];
	};


	// ----------------------------------------------------------------------
	//                       Effect and Mixer Controls
	// ----------------------------------------------------------------------


	object.reverbOn= { arg command;

		object.track1 = Synth.head(~effects, \reverb, [\in, ~effect1, \mix, 1, \out, 0]);
		object.track1.map(\gain, object.gainBus);
		object.track1.map(\room, object.roomBus);
		object.track1.map(\damp, object.dampBus);
		object.track1.map(\volume, object.volumeBus);



		object[\csReverb] = ~cs[\synth].(object[\csReverb], \reverb,
			[\in, 20, \mix, 1, \out, 0], targets: ~cs[\server], addAction: 'addToTail');

		object[\csReverb][\cmap].(\gain, object[\gainCBus]);
		object[\csReverb][\cmap].(\room, object[\roomCBus]);
		object[\csReverb][\cmap].(\damp, object[\dampCBus]);
		object[\csReverb][\cmap].(\volume, object[\volumeCBus]);



	};

	object.reverbOff= { arg command;

		//object.track1.release(0.5);
		object.track1.free;

		object[\csReverb].cfree;
	};

	object.delayOn= { arg command;

		object.track1 = Synth.head(~effects, \delay, [\in, ~effect2, \out, 0]);
		object.track1.map(\gain, object.gainBus);
		object.track1.map(\buffer, object.bufferBus);
		object.track1.map(\deltime, object.deltimeBus);
		object.track1.map(\volume, object.volumeBus);


		object[\csDelay] = ~cs[\synth].(object[\csDelay], \delay,
			[\in, 40, \out, 0], targets: ~cs[\server], addAction: 'addToTail');

		object[\csDelay][\cmap].(\gain, object[\gainCBus]);
		object[\csDelay][\cmap].(\buffer, object[\bufferCBus]);
		object[\csDelay][\cmap].(\deltime, object[\deltimeCBus]);
		object[\csDelay][\cmap].(\volume, object[\volumeCBus]);



	};

	object.delayOff= { arg command;

		//object.track1.release(0.5);
		object.track1.free;

		object[\csDelay].cfree;

	};

	object.distortOn= { arg command;

		object.track1 = Synth.head(~effects, \distort, [\in, ~effect3, \out, 0]);
		object.track1.map(\gain, object.gainBus);
		object.track1.map(\freq, object.freqBus);
		object.track1.map(\amount, object.amountBus);
		object.track1.map(\volume, object.volumeBus);


		object[\csDistort] = ~cs[\synth].(object[\csDistort], \distort,
			[\in, 60, \out, 0], targets: ~cs[\server], addAction: 'addToTail');

		object[\csDistort][\cmap].(\gain, object.gainCBus);
		object[\csDistort][\cmap].(\freq, object.freqCBus);
		object[\csDistort][\cmap].(\amount, object.amountCBus);
		object[\csDistort][\cmap].(\volume, object.volumeCBus);


	};

	object.distortOff= { arg command;

		//object.track1.release(0.5);
		object.track1.free;

		object[\csDistort].cfree;

	};

	object.streamOn= { arg command;

		object.track1 = Synth.head(~masterBus, \stream,
			[\in, ~stream1, \out, ~channelsOut1+~channelsOut2]);
		object.track1.map(\volume, object.volumeBus);
		object.track1.map(\tresh, object.treshBus);
		object.track1.map(\gate, object.gateBus);
		object.track1.map(\comp, object.compBus);
		//object.track1.map(\cloud, object.cloudBus);
		"stream activated!".postln;
	};

	object.streamOff= { arg command;

		//object.track1.release(0.5);
		object.track1.free;
		//object.track2.free;

	};

	/*object.cloudOn= { arg command;

	object.track1 = Synth.head(~masterBus, \cloud,
	[\in, ~out1, \out, ~channelsOut1]);
	object.track1.map(\cloud, object.cloudBus);
	};

	object.cloudOff= { arg command;

	object.track1.free;

	};*/

	object.mbusOn= { arg command;

		object.track1 = Synth.head(~masterBus, \master,
			[\in, ~out1.index, \out, ~channelsOut1]);
		object.track1.map(\master, object.out1Bus);

		object.track2 = Synth.head(~masterBus, \master,
			[\in, ~out2.index, \out, 0]);
		object.track2.map(\master, object.out2Bus);
	};

	object.mbusOff= { arg command;

		object.track1.free;
		object.track2.free;

	};



	object.mixerOn= { arg command;

		//var busses = monoIn + stereoIn + multi;

		object.track = ();

		if (monoIn != nil, {

			monoIn.do { |i|

				object[\track][i] = Synth.tail(~synths, \monoIn, [\in, i, \vol1, 0,
					\out1, ~out1.index, \out2, ~out2.index, \pan, 0.8,
					\effOut1, ~effect1.index, \effOut2, ~effect2.index, \effOut3, ~effect3.index
				]);
				object[\track][i].map(\pan, object[\pan][i][\panBus]);
				object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
				object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
				object[\track][i].map(\effect3, object[\distort][i][\distortBus]);
				object[\track][i].map(\cloud, object[\cloud][i][\cloudBus]);
				object[\track][i].map(\stream, object[\stream][i][\streamBus]);
				object[\track][i].map(\vol1, object[\vol1][i][\vol1Bus]);
				object[\track][i].map(\vol2, object[\vol2][i][\vol2Bus]);

			}
		});

		if (stereoIn != 0, {

			forBy (monoIn, (monoIn + stereoIn - 1), 2, { |i|

				object[\track][i] = Synth.head(~busses, \stereoIn, [
					\in, [i, i+1], \vol1, 0, \out1, ~out1.index, \out2, ~out2.index,
					\effOut1, ~effect1.index,\effOut2, ~effect2.index, \effOut3, ~effect3.index
				]);

				//object[\track][i].map(\pan, object[\pan][i][\panBus]);
				object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
				object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
				object[\track][i].map(\effect3, object[\distort][i][\distortBus]);
				object[\track][i].map(\cloud, object[\cloud][i][\cloudBus]);
				object[\track][i].map(\stream, object[\stream][i][\streamBus]);
				object[\track][i].map(\vol1, object[\vol1][i][\vol1Bus]);
				object[\track][i].map(\vol2, object[\vol2][i][\vol2Bus]);

			})
		});

		if (multi != 0, {

			var counter = 0;

			for (monoIn + stereoIn, monoIn + stereoIn + multi - 1, { |i|

				postf("i = %, counter = %\n", i, counter);

				object[\track][i] = Synth.head(~busses, \multiTrack,
					[\in, ~instruments[counter][\out].index, \out1, ~out1.index, \out2, ~out2.index,
						\effOut1, ~effect1.index, \effOut2, ~effect2.index,
						\streamOut, ~stream1.index]);
				//object[\track][i].map(\pan, object[i].panBus);
				object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
				object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
				object[\track][i].map(\effect3, object[\distort][i][\distortBus]);
				object[\track][i].map(\cloud, object[\cloud][i][\cloudBus]);
				object[\track][i].map(\stream, object[\stream][i][\streamBus]);
				object[\track][i].map(\vol1, object[\vol1][i][\vol1Bus]);
				object[\track][i].map(\vol2, object[\vol2][i][\vol2Bus]);

				counter = counter + 1;
			})
		});
	};

	object.mixerOff= { arg command;

		//var busses = monoIn[0]+stereoIn[0]+multi[0];

		busses.do {|i|

			//object.track1.release(0.5);
			object[\track][i].free;
		};

	};


	// ----------------------------------------------------------------------
	//                        Draw Controls and Values
	// ----------------------------------------------------------------------

	object[mode.asSymbol].value;

	// draw the toggles, sliders and rangers

	~controls[\toggle].value(['On', 'Off'], object, mode, gui, object.label);
	//object.layout.nextLine;


	object[\makeGui] = { | values |

		var quant = values.size/3;

		if (mode == "mixer", {

			quant.do { |i|
				var name = values[i*3];
				var varis = values[(i*3)+1];
				var type = values[(i*3)+2];
				var modeVar, nameVar;
				//var inBusses = monoIn + stereoIn;

				//postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);
				object.labelparam = StaticText(object.window, 50@35)
				.string_(name)
				.align_(\right)
				.font_(Font("Helvetica-bold", 12))
				.stringColor_(Color.black);

				object[name.asSymbol] = Array.newClear(busses+1);
				inBusses.do { |k|
					object[name.asSymbol][k] = ();
					~controls[("set"++type).asSymbol].value(name, varis, object, object[name.asSymbol][k], mode, gui);
				};

				object.spacer = StaticText(object.window, 2@38)
				.background_(Color.grey(0.6));


				multi.do { |k|

					var count = inBusses+k;
					object[name.asSymbol][count] = ();
					~controls[("set"++type).asSymbol].value(name, varis, object, object[name.asSymbol][count], mode, gui);
				};

				object.layout.nextLine;

				//gui.postln;
			}

		}, {


			quant.do { |i|
				var name = values[i*3];
				var varis = values[(i*3)+1];
				var type = values[(i*3)+2];

				//postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);
				gui.postln;

				~controls[("set"++type).asSymbol].value(name, varis, object, mode, gui);
			}
		});
	};

	object[\makeGui].value(object.list);

	object[\drawGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];
			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].start;
			})
		};
	};

	object[\stopGui] = { | values |

		var quant = values.size/3;

		quant.do { |i|
			var name = values[i*3];

			var type = values[(i*3)+2];
			if (type != "Trigger", {
				object[(name ++ "DrawGui").asSymbol].stop;
			})
		}
	};


	if (gui != False, {

		//object[\drawGui].value(object.list);

	});

	object;

};