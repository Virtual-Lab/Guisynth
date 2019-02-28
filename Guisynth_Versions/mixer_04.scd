(

var mixer, track, effect1, effect2;
var setmono, setstereo,settracks;
var midisetup, audiosetup;
var master, bus, effect, source;

track = Array.newClear(64);
effect1 = Array.newClear(64);
effect2 = Array.newClear(64);

~ctl1 = Bus.control(s, 1);
~ctl2 = Bus.control(s, 1);
~ctl3 = Bus.control(s, 1);
~effect1 = Bus.audio(s, 2);
~effect2 = Bus.audio(s, 2);
~effect3 = Bus.audio(s, 2);

//a = Environment.make{};
//a.push;


MIDIClient.init(2,2);
MIDIIn.connect(0,  MIDIClient.sources.at(3));
MIDIIn.connect(0,  MIDIClient.sources.at(4));
MIDIIn.connect(0,  MIDIClient.sources.at(5));
MIDIIn.connect(0,  MIDIClient.sources.at(6));
MIDIIn.connect(0,  MIDIClient.sources.at(7));

//MIDIOut.connect(0,  MIDIClient.destinations.at(2));
//MIDIIn.connect(0,  MIDIClient.sources.at(8));
//MIDIIn.connect(0,  12);
//MIDIClient.sources;^
/*MIDIClient.getClientID;
MIDIFunc.cc( {|msg, val1, val2, val3 |
	postf("% % % % %\n", msg, val1, val2, val3);
});*/

~m1 = MIDIOut(0);

5.do { |i|
	~m1.connect(i+1);
};

~pisound = Server("pisound", NetAddr("10.0.0.6", 57110));
~pisound.initTree;
//~pisound.startAliveThread;

//o.device = "Fireface 800(AA)";
//o.device = "Soundflower (64ch)";
//o.device = "Soundflower (2ch)";

o = s.options;

o.memSize = 2.pow(20);
o.numAudioBusChannels = 256;
o.numInputBusChannels = 8;
o.numOutputBusChannels = 4;
o.remoteControlVolume = false;
// o.outputStreamsEnabled = "11110000";
o.sampleRate = 44100;
o.maxNodes = 1024*8;


"LividCtl_002.scd".loadRelative;
"LividCtl_002.scd";

"NanoCtl_Live01.scd".loadRelative;
"NanoCtl_01.scd";

"bela_01.scd".loadRelative;
"bela_01.scd";

s.waitForBoot {

	SynthDef(\track, {
		|in = 0, out = 0, effOut1 = 0,  effOut2 = 0, pan = 0, vol = 1, effect1 = 0, effect2 = 0|

		var input = SoundIn.ar(in);
		var output = Pan2.ar(input, (pan*2)-1, 1)  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
	}).add;

	SynthDef(\bus, {
		|in = 50, out = 0, effOut1 = 0, effOut2 = 0, pan = 0.5, vol = 1.0, effect1 = 0, effect2 = 0|
		var input, output;

		input = In.ar(in, 1);
		output = Pan2.ar(input, (pan*2)-1, 1)  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
	}).add;

	SynthDef(\stereo, {
		|in = #[50, 51], out = 0, effOut1 = 0,  effOut2 = 0, vol = 1.0, amp = 1, effect1 = 0, effect2 = 0|

		var input = SoundIn.ar(in, amp);
		var output = input  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
	}).add;

	//  Effekt 1 - Multi-Reverb1 - pre
	SynthDef(\reverbIn, {
		arg out = 0, in = 0, mix = 1, room = 1.5, damp = 0.5, pan = 0, vol = 1;

		var input = SoundIn.ar(in, 1);
		var reverb = FreeVerb.ar(input, mix, room, damp);
		var output = Pan2.ar(reverb, (pan*2)-1, vol);

		Out.ar(out, output);
	}).add;

	// Effekt 1 - Multi-Reverb2 - post
	SynthDef(\reverb, {
		arg out = 0, in = 0, mix = 0.8, room = 0.5, damp = 0.5, vol = 1;

		var input = In.ar(in, 2);
		var output = FreeVerb.ar(input, mix, room, damp, 1);

		Out.ar(out, output*vol);
	}).add;

	// Effekt 2 - Multi-Delay1 -pre
	SynthDef(\delayIn, {
		arg out = 0, in = 0, gain = 1, buffer = 2, deltime = 0.25, decay = 1, vol = 1, pan = 0;
		var input = SoundIn.ar(in, 1) * gain;

		var delay = CombL.ar(input, 2, deltime, decay);

		var output = delay * vol;

		Out.ar(out, output);

	}).add;



	// Effekt 2 - Multi-Delay2 -post
	SynthDef(\delay, {
		arg out = 0, in = 0, gain = 1, buffer = 2, deltime = 0.25, decay = 1, vol = 1;
		var input = In.ar(in, 2) * gain;

		var output = CombL.ar(input, 2, deltime, decay, 1);

		Out.ar(out, output * vol);

	}).add;

	SynthDef(\sine, {
		|freq|

		var osc = SinOsc.ar([freq, freq+5 ], 0, 0.1);

		Out.ar(0,osc);
	}).add;

	SynthDef(\piout, {
		|in = 1, out = 0, amp = 1,
		mix = 0.33, room = 0.5, damp = 0.5,
		deltime = 0.25, decay = 1, vol = 1|

		// input and output variables
		var input = AudioIn.ar([in, in+1], amp);
		var reverb = FreeVerb.ar(input, mix, room*2, damp, 1);
		var delay = CombL.ar(input, 2, deltime, decay, 1);

		var output = reverb * delay * vol;

		Out.ar(out, output);

	}).send(~pisound);

	master = Group.new;
	bus = Group.new;
	effect = Group.new;
	source = Group.new;

	s.sync;

	settracks = {

		8.do { |i|
			~nc.slider[0][i].value = 0;
			~nc.knob[0][i].value = 0.5;
			// ~lv.knob1[1][i].value = 0.2;
			// ~lv.knob2[1][i].value = 0;
		};
/*		~lv.slider[1][0].value = 1;
		~lv.slider[1][1].value = 0.8;
		~lv.slider[1][2].value = 0.5;
		~lv.slider[1][3].value = 1;
		~lv.slider[1][4].value = 1;
		~lv.slider[1][5].value = 0.25;
		~lv.slider[1][6].value = 0.5;
		~lv.slider[1][7].value = 1;*/
	};


	setmono = { |busses, offset|


		busses.do { |i|

			track[i] = Synth.head(master, \track, [\in, i, \effOut1, ~effect1.index,  \vol, 0, \effOut2, ~effect2.index, \out, 0]);
			track[i].map(\vol, ~nc.slider[0][i]);
			track[i].map(\pan, ~nc.knob[0][i]);

			//track[i].map(\effect1, ~lv.knob1[1][i]);
			//track[i].map(\effect2, ~lv.knob2[1][i]);

			postf("Mono Track % enabled\n", i);

		};
	};

	setstereo = { |busses, offset|


		forBy (offset, offset+((busses-1)*2), 2, { |i|

			track[i] = Synth.head(master, \stereo, [\in, [i, i+1], \effOut1, ~effect1.index,  \vol, 0, \effOut2, ~effect2.index, \out, 0]);
			track[i].map(\vol, ~nc.slider[0][i]);
			track[i].map(\pan, ~nc.knob[0][i]);

			//track[i].map(\effect1, ~lv.knob1[1][i]);
			//track[i].map(\effect2, ~lv.knob2[1][i]);

			postf("Stereo Track % enabled\n", i);

		});
	};

	settracks.value;
	setmono.value(4);
	setstereo.value(2, 4);
    ~reverb = Synth.tail(master, \reverb, [\in, ~effect1.index,  \mix,  1, \room,  0.3, \vol, 1]);
	~delay = Synth.tail(master, \delay, [\in, ~effect2.index, \deltime, 0.25, \decay, 1, \vol, 1]);

/*	~reverb.map(\mix, ~lv.slider[1][0]);
	~reverb.map(\room, ~lv.slider[1][1]);
	~reverb.map(\damp, ~lv.slider[1][2]);
	~reverb.map(\vol, ~lv.slider[1][3]);

	~delay.map(\buffer, ~lv.slider[1][4]);
	~delay.map(\deltime, ~lv.slider[1][5]);
	~delay.map(\decay, ~lv.slider[1][6]);
	~delay.map(\vol, ~lv.slider[1][7]);*/

	~piOut = Synth.new("piout", [\in, 1, \out, 0], target:~pisound);

}

)



