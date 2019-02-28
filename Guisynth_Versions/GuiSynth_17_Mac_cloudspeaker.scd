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
var slider = (), ranger = (), knob = ();

//~guiClock = AppClock.new;

// Server Settings
o = Server.local.options;
~channelsOut1 = 12;
~channelsOut2 = 12;
~channelsStream = 2;
~channelsIn = 4;
~bufnum = 0;
~instruments = [];
~cloud = true;
~pistream = true;

//ServerOptions.devices;
//o.device = "Fireface 800(AA)";
//o.device = "Soundflower (64ch)";
//o.device = "Soundflower (2ch)";
o.device = "JackRouter";
//o.device = "MOTU Traveller";

o.numOutputBusChannels = ~channelsOut1+~channelsOut2+~channelsStream;
o.numInputBusChannels = ~channelsIn;
o.memSize = 2.pow(20);
o.numAudioBusChannels = 4096*2;
o.numControlBusChannels = 16384 * 5;
o.sampleRate = 44100;
o.maxNodes = 1024*12;
s.volume = -8;

//"Cloudsynth1.scd".loadRelative;
//"piset.scd".loadRelative;

s.waitForBoot ({

	// create an objects (~main)
	//~main.interface;

	~main = ~main ? ();

	~main.interface = {
		// create a ~main-Window (Instrument)
		if(~main.window != nil, {~main.window.close});
		~main.window = Window.new("Instrument", Rect(0, 400, 1440, 900), border: true, scroll: true).front;
		~main.window.view.decorator =  FlowLayout(~main.window.bounds, 0@0);

		// create sampler-Window (Instrument)
		~object1 = CompositeView(~main.window, Rect(0, 0, 440, 2000)).front
		.onClose_({~object1.free});
		~object1.decorator =  FlowLayout(~object1.bounds, 0@0);

		// create asynth-Window (Instrument)
		~object2 = CompositeView(~main.window, Rect(520, 0, 440, 2000)).front
		.onClose_({~object2.free});
		~object2.decorator =  FlowLayout(~object2.bounds, 0@0);

		~object3 = CompositeView(~main.window, Rect(1044, 0, 540, 2000)).front
		.onClose_({~object3.free});
		~object3.decorator =  FlowLayout(~object3.bounds, 0@0);
	};


	// -----------------------------------------------------------------------
	//                                                 Synth Definitions
	// -----------------------------------------------------------------------

	~effect1 = Bus.audio(s, ~channelsOut2);
	~effect2 = Bus.audio(s, ~channelsOut2);
	~effect3 = Bus.audio(s, ~channelsOut2);
	~effect4 = Bus.audio(s, ~channelsOut2);
	~out1 = Bus.audio(s, ~channelsOut1);
	~out2 = Bus.audio(s, ~channelsOut2);
	~stream1 = Bus.audio(s, ~channelsStream);

	//s.sync;

	"Guisynth_17_synthdef.scd".loadRelative;
	"Guisynth_17_controls.scd".loadRelative;
	"Guisynth_17_instruments.scd".loadRelative;

	//loadRelative("NanoCtl_Fox01-Mac.scd");
	"Cloudsynth1.scd".loadRelative;
	//"piset.scd".loadRelative;

	~piSet.value;

	~main.interface;

	~granulator1 = ~m_player.value(~granulator1, "granulator1", ~object1, height: 380, bufnum: 0);
	~granulator2 = ~m_player.value(~granulator2, "granulator2", ~object1, height: 420, bufnum: 1);
	~glocke1 = ~m_synth.value(~glocke1, "glocke1", ~object2, height: 150);
	~glocke2 = ~m_synth.value(~glocke2, "glocke2", ~object2, height: 320);

	//~brummel = ~m_synth.value(~brummel, "brummel", ~object2, gui: false, height: 220);
	//~sampler = ~m_player.value(~sampler, "sampler", ~object1, height: 220);

	~reverb = ~m_mixer.value(~reverb, "reverb", ~object3, height: 120, width: 250);
	~delay = ~m_mixer.value(~delay, "delay", ~object3, height: 120, width: 250);
	//~distort = ~m_mixer.value(~distort, "distort", ~object3, height: 120);

	~stream = ~m_mixer.value(~stream, "stream", ~object3, height: 120, width: 250, stream: 1);
	~mbus = ~m_mixer.value(~mbus, "mbus", ~object3, height: 120, width: 250, stream: 1);
	~master = ~m_mixer.value(~master, "master", ~object3, height: 120, width: 250);
	~mixer = ~m_mixer.value(~mixer, "mixer", ~object2, height: 330, width: 480, monoIn: 4, multi: 4);

	//player.start;
	~mixer[\OnControl].value(1);
	~reverb[\OnControl].value(1);
	~delay[\OnControl].value(1);
	//~distort[\OnControl].value(0);
	~stream[\OnControl].value(1);
	~mbus[\OnControl].value(1);

	//if(w != nil, {w.close});
	//w = Window.new("levels", Rect(800, 600, 650, 250));//, Rect(800, 400, 800, 500));
	ServerMeterView.new(s, w, 0@0, o.numInputBusChannels, o.numOutputBusChannels);
	ServerMeterView.new(s, ~object3, 0@0, o.numInputBusChannels, o.numOutputBusChannels);
	//w.front;


	//ServerMeterView.new(~pisound, w, 0@250, 2, 2);
	//ServerMeterView.new(~cs[0], w, 0@250, 2, 2);

})

)

/*~instruments[3][\out].index
~cs.clients.do{ |i|
	~cs[\server][i].freeAll;
};

~cs[0]*/