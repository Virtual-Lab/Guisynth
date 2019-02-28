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
~channelsOut = 2;
~channelsIn = 10;
~bufnum = 0;
~instruments = [];

//ServerOptions.devices;
//o.device = "Fireface 800(AA)";
//o.device = "Soundflower (64ch)";
//o.device = "Soundflower (2ch)";
//o.device = "JackRouter";

o.numOutputBusChannels = ~channelsOut;
o.numInputBusChannels = ~channelsIn;
o.memSize = 2.pow(20);
o.numAudioBusChannels = 2048;
o.numControlBusChannels = 16384 * 4;
o.sampleRate = 44100;
o.maxNodes = 1024*12;
s.volume = -8;

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
		~object1 = CompositeView(~main.window, Rect(0, 0, 520, 2000)).front
		.onClose_({~object1.free});
		~object1.decorator =  FlowLayout(~object1.bounds, 0@0);

		// create asynth-Window (Instrument)
		~object2 = CompositeView(~main.window, Rect(520, 0, 520, 2000)).front
		.onClose_({~object2.free});
		~object2.decorator =  FlowLayout(~object1.bounds, 0@0);

		~object3 = CompositeView(~main.window, Rect(1044, 0, 380, 2000)).front
		.onClose_({~object2.free});
		~object3.decorator =  FlowLayout(~object1.bounds, 0@0);
	};


	// -----------------------------------------------------------------------
	//                                                 Synth Definitions
	// -----------------------------------------------------------------------

	~effect1 = Bus.audio(s, ~channelsOut);
	~effect2 = Bus.audio(s, ~channelsOut);
	~effect3 = Bus.audio(s, ~channelsOut);
	~effect4 = Bus.audio(s, ~channelsOut);
	~stream = Bus.audio(s, 2);
	//s.sync;

	SynthDef(\sine, { arg effect1 = 0, effect2 = 0, freq1=110, freq2=10, volume = 0, out = 0, out2 = 8, xpan = 0, ypan = 0.5;
		var output, array1, array2, sin1;
		sin1 = SinOsc.ar(freq1+BrownNoise.kr(freq2), 0, 0.1);

		output = PanAz.ar(~channelsOut, sin1, xpan, 1);

		Out.ar(out, output * volume.lag(0.2));
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
	}).add;

	SynthDef(\brummel, {
		arg out = 0, effect1 = 0, effect2 = 0,
		freq1 = 220, freq2 = 235, width = 0.5, puls1 = 0.8, puls2 = 1,
		attack = 0.01, sustain = 1, release = 0.5, curve = 0, gate = 1, ts = 1, volume = 1;

		var output;

		var env = EnvGen.kr(Env.asr(attack, sustain, release, curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		var pulse = Pulse.kr([puls1.lag(0.01), puls2.lag(0.01)], width, 0.5) * env;

		var synth = SinOsc.ar([freq1.lag(0.01), (freq1+freq2).lag(0.01)], 0, pulse*volume*10).distort *0.1;


		output = Limiter.ar(synth, 1, 0.01);

		Out.ar(out, output * volume.lag(0.2));
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);

	}).add;

	// ------------------- Soundfile Player without envelope

	SynthDef(\sfplayer, {
		arg sndbuf, out = 0, effect1 = 0, effect2 = 0,
		rate = 1, pan = 0,  loop = 0, amp = 0.9, trigger = 1, pos = 0, width = 2;

		var bufnum = sndbuf;
		var rateScale = BufRateScale.kr(bufnum)*rate;

		var sfplayer = PlayBuf.ar(sndbuf.numChannels,
			bufnum,
			rateScale,
			trigger,
			pos*BufFrames.kr(bufnum),
			loop);

		var limiter = Limiter.ar(sfplayer, 1, 0.01);

		var output = PanAz.ar(~channelsOut, limiter, pan, width: width);

		Out.ar(out, output  * amp);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
	}).add;

	// ******************** Granulator

	SynthDef(\granulator1, {
		arg out = 0, out2 = 9, effect1 = 0, effect2 = 0, effect3 = 0,
		gate = 1, puls = 20, width = 2, sndbuf, envbuf,
		dur = #[0.09, 0.11],
		pos = #[0, 1],
		pitch = #[0.99, 1.01],
		dens = #[20, 20],
		pan = #[-0.5, 0.5],
		ypan = 0.5,
		vol = #[0.8, 1];

		var env, density, granulator, output, array1, array2;

		env = EnvGen.kr(
			Env([0, 1, 0], [1, 1], \sin, 1),
			gate: gate,
			levelScale: 1,
			doneAction: 2);

		density = Impulse.kr(WhiteNoise.kr(dens[1], dens[0])+puls);

		granulator = GrainBuf.ar(
			numChannels: ~channelsOut,
			trigger: density,
			dur: WhiteNoise.kr(1).range(dur[0], dur[1]), // size of the grain
			sndbuf: sndbuf,
			rate: WhiteNoise.kr(1).range(pitch[0], pitch[1]),
			pos: WhiteNoise.kr(1).range(pos[0], pos[1]),
			interp: 2, // pitchshifting interpolation: 1 = no, 2 = linear, 4 = cubic
			pan: WhiteNoise.kr(1).range(pan[0], pan[1]), // depends on number of channels: 1: no panning, 2: -1 to +1
			envbufnum: envbuf) * env * LFNoise2.kr(density).range(vol[0], vol[1]);

		output = granulator;

		Out.ar(out, output);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
		Out.ar(~effect3, output * effect3);

	}).add;


	// ******************** Granulator2

	SynthDef(\granulator2, {
		|out = 0, out2 = 8, effect1 = 0.2, effect2 = 0, effect3 = 0, bufnum, startPos, rate = 1, sustain = 0.02, ts = 1, attac = 0.01, release = 0.1, curve = 1, amp = 0.2, pan = 0.5, ypan = 0.5, width = 2, hanning = 0|

		var env1 = EnvGen.ar(Env.sine(sustain, 1), timeScale: ts, doneAction: 2);
		var env2 = EnvGen.ar(Env.perc(attac, release, 1, curve), timeScale: ts, doneAction: 2);
		var env3 = EnvGen.ar(Env.triangle(sustain, 1), timeScale: ts, doneAction: 2);
		var env4 = EnvGen.ar(Env.asr(attac, sustain, release, curve), timeScale: ts, gate: 1, doneAction: 2);

		var granulator = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, 1, BufFrames.ir(bufnum)*startPos, 0);

		var grain = granulator * Select.kr(hanning, [env1, env2, env3, env4]);

		var output = PanAz.ar(~channelsOut, grain, pan, width: width);

		Out.ar(out, output * amp);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
		Out.ar(~effect3, output * effect3);

	}, \ir.dup(5)).add;

	// ******************** Record into Buffer
	SynthDef(\bufferRec, {
		| bufnum, rec = 0, in = 0|
		var input = In.ar(in, 1);

		RecordBuf.ar(input, bufnum, 0, 1, run: rec, trigger: Changed.kr(rec), loop: 1);

	}).add;


	// ******************** Levelmeters
	SynthDef(\levelmeter, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = In.ar(in) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/levelmeter', [levelmeter, peaklevel], in);


	}).add;

	// ******************** Levelmeter for Sound Input

	SynthDef(\soundIn, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = SoundIn.ar(in) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/soundinput', [levelmeter, peaklevel], in);

		Out.ar(out, output);

	}).add;


	// Synth Multichannel - Definition - Additiver Synth mit zufälligen Obertönen – Frequenz und Ampl. Contr.

	SynthDef(\glocke1, {
		arg out = 0, out2 = 8, effect1 = 0, effect2 = 0, effect3 = 0,
		volume = 0, freq = 200, spread = 0.1,
		ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, release = 0.4, curve = -4,
		pan = 0, xpan = 0, ypan = 0.5, width = 2, gate = 1;

		var n = 5, synth, output, array1, array2, random;

		var env = EnvGen.kr(Env.adsr(attack, decay, sustain, release, curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		synth = Mix.fill(n, {|i|
			random = (freq.lag(0.2)  * Rand(1-spread,(1+spread)) * (i+1));
			SinOsc.ar(random, 0, 1/n)})
		* volume * env;

		output = PanAz.ar(~channelsOut, synth, xpan, 2);

		Out.ar(out, output);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
		Out.ar(~effect3, output * effect3);

	}).add;

	// Synth Multichannel - Definition - Additiver Synth mit zufälligen Obertönen – Frequenz und Ampl. Contr.
	SynthDef(\glocke2, {
		arg out = 0, out2 = 8, volume = 0, freq = 200, spread = 0.1,
		ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, hold = 1, release = 0.4, curve = -4,
		pan = 0, xpan = 0, ypan = 0.5, gate = 1, effect1 = 0, effect2 = 0, effect3 = 0;

		var n = 5, synth, output, array1, array2, random;

		var env = EnvGen.kr(Env([0, 1, sustain, sustain, 0], [attack, decay, hold, release], curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		synth = Mix.fill(n, {|i|
			random = (freq * Rand(1-spread,(1+spread)) * (i+1));
			SinOsc.ar(random, 0, 1/n)})
		* volume * env;

		output = PanAz.ar(~channelsOut, synth, xpan, 1);

		Out.ar(out, output);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);
		Out.ar(~effect3, output * effect3);

	}).add;

	SynthDef(\ampMod, { arg out = ~volumeBus, rate = 1, volume = 0.2, ampl = 0.3, lag = 0.5;
		var output = Pulse.kr(rate, 0.5, ampl, volume).lag(lag/rate);
		Out.kr(out, output);
	}).add;

	SynthDef(\freqMod, { |out = 0, rate = 0.1, mul = 100, add = 200|
		var output = SinOsc.kr(rate, 0, mul, add);

		Out.kr(out, output);
	}).add;


	SynthDef(\reverb, {
		arg out = 0, in = 0, gain = 1, mix = 1, room = 0.5, damp = 0.5, volume = 1;

		var input = In.ar(in, ~channelsOut) * gain;
		var output = FreeVerb.ar(input, mix, room, damp, volume);

		Out.ar(out, output);
	}).add;

	SynthDef(\delay, {
		arg out = 0, in = 0, gain = 1, buffer = 2, deltime = 0.25, decay = 1, volume = 1;
		var input = In.ar(in, ~channelsOut) * gain;

		var output = CombL.ar(input, 2, deltime, decay, volume);

		Out.ar(out, output);

	}).add;

	SynthDef(\distort, {
		arg out = 0, in = 0, gain = 1, freq = 2400, amount = 0.99, volume = 1;

		var input = In.ar(in, ~channelsOut) * gain;

		var filter = HPF.ar(input, 400)*5;

		var amCoef= 2*amount/(1-amount);

		var output = MidEQ.ar(
			LPF.ar((1+amCoef)*filter/(1+(amCoef*filter.abs)), freq)
			*0.5, 120, 0.7, 0, volume/5);

		Out.ar(out, output);

	}).add;

	SynthDef(\monoIn, {
		|in = 0, out = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, pan = 0.5, vol = 1,
		effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = SoundIn.ar(in);
		var output = PanAz.ar(~channelsOut, input, pan-1, vol, width);

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
		Out.ar(effOut3, output * effect3);
	}).add;

	SynthDef(\stereoIn, {
		|in = #[50, 51], out = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, pan = 0,
		vol = 1.0, amp = 1, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = SoundIn.ar(in, amp);
		var output = PanAz.ar(~channelsOut, input, pan-1, vol, width);

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
		Out.ar(effOut3, output * effect3);

	}).add;

	SynthDef(\monoTrack, {
		|in = 0, out = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, pan = 0.5, vol = 1,
		effect1 = 0, effect2 = 0, effect3 = 0|

		var input = In.ar(in, 1);
		var output = input  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
		Out.ar(effOut3, output * effect3);

	}).add;

	SynthDef(\stereoTrack, {
		|in = 0, out = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, pan = 0,
		vol = 1.0, amp = 1, effect1 = 0, effect2 = 0, effect3 = 0|

		var input = In.ar(in, 2);
		var output = input  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
		Out.ar(effOut3, output * effect3);

	}).add;

	SynthDef(\multiTrack, {
		|in = 0, out = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, pan = 0,
		vol = 1.0, amp = 1, effect1 = 0, effect2 = 0, effect3 = 0|

		var input = In.ar(in, ~channelsOut);
		var output = input  * vol;

		Out.ar(out, output);
		Out.ar(effOut1, output * effect1);
		Out.ar(effOut2, output * effect2);
		Out.ar(effOut3, output * effect3);

	}).add;

	SynthDef(\diskout, {
		arg bufnums = #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
		DiskOut.ar(bufnums[0],  In.ar(0,1));
		DiskOut.ar(bufnums[1],  In.ar(1,1));
		DiskOut.ar(bufnums[2],  In.ar(2,1));
		DiskOut.ar(bufnums[3],  In.ar(3,1));
		DiskOut.ar(bufnums[4],  In.ar(4,1));
		DiskOut.ar(bufnums[5],  In.ar(5,1));
		DiskOut.ar(bufnums[6],  In.ar(6,1));
		DiskOut.ar(bufnums[7],  In.ar(7,1));
		DiskOut.ar(bufnums[8],  In.ar(8,1));
		DiskOut.ar(bufnums[9],  In.ar(9,1));
		DiskOut.ar(bufnums[10], In.ar(10,1));
		DiskOut.ar(bufnums[11], In.ar(11,1));
		DiskOut.ar(bufnums[12], In.ar(12,1));
		DiskOut.ar(bufnums[13], In.ar(13,1));
		DiskOut.ar(bufnums[14], In.ar(14,1));
		DiskOut.ar(bufnums[15], In.ar(15, 1));
	}).add;

	// Gruppen definieren

	~master = Group.new;
	~busses = Group.new;
	~effects = Group.new;
	~synths = Group.new;
	~input = Group.new;
	~remote = Group.new;


	// Drawing the Gui
	~controls = ();

	~controls[\toggle] = { |name, object, mode, gui, guiWindow|

		if (guiWindow == object.label, {}, {guiWindow = object.window});

		if (gui != False, {

			defer {

				object[(name[0]++"Gui").asSymbol] = Button(guiWindow, Rect(0,0,50,20))
				.states_([[name[0], Color.black, Color.white], [name[1], Color.black, Color.grey]])
				.action_({ |val|
					//	object.startbutton.value = val.value;
					object[(name[0]++"Control").asSymbol].value(val.value);


				})
			};
		});

		object[(name[0]++"Control").asSymbol] = { |val|

			if (gui != False, {
				if (object[(name[0]++"Gui").asSymbol].value != val,
					{ defer {object[(name[0]++"Gui").asSymbol].value = val} })
			});

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

					if (gui != False, {

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					})
				});

				0.1.wait;
			}
		};

	};

	~controls[\setTrigger] = { |name, values, object, mode, gui|

		var min = values[0], max = values[1], currentVal = values[2];

		if (gui != False, {

			defer {

				object[(name++"Gui").asSymbol] = Button(object.window, Rect(0,0,50,20))
				.states_([[name, Color.black, Color.white], [name, Color.black, Color.white]])
				.action_({ |val|
					//	object.startbutton.value = val.value;
					object[(name++"Control").asSymbol].value(val.value);
				});
			};

			// labeling the Number Box

			object[(name++"LabelBox").asSymbol] = CompositeView(object.window, Rect(0, 0, 40, 20))
			.background_(Color.grey(0.6));

			object[(name++"LabelText").asSymbol] = StaticText(object[(name++"LabelBox").asSymbol], Rect(5, 0, 35, 20))
			.string_("time")
			.font_(Font("Helvetica-bold", 12))
			.stringColor_(Color.white)
			.background(Color.grey(0.6));

			// Numberbox for time parameter

			object[(name++"TimeSetGui").asSymbol] = NumberBox(object.window, 35@20)
			.action = { |val| object[(name++"Time").asSymbol] = val.value};

			object[(name++"TimeSetGui").asSymbol].clipLo = 0;
			object[(name++"TimeSetGui").asSymbol].value  = currentVal;


			object.layout.nextLine;
		});

		object[(name++"Control").asSymbol] = { |val|

			object[(mode++name).asSymbol].start;

		};

		object[(name++"Time").asSymbol] = currentVal;

	};

	~controls[\setSlider] = { |name, values, object, mode, gui|

		var min = values[0], max = values[1], currentVal = values[2], instance = True;

		//postf("Slider Parametername: %, Received Values: %\n", name, values);

		object[(name++"Val").asSymbol] = currentVal;

		object[(name++"Bus").asSymbol] = Bus.control(s, 1).value = currentVal;

		// set the slider of an synth-array

		if (gui != False, {

			"Yes, WE DRAW GUI!!!".postln;
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

		});

		object[(name++"Control").asSymbol] = { |val|

			object[(name++"Bus").asSymbol].set(val);
			object[(name++"Val").asSymbol] = val;

			//if (object[\instance] = instance[(mode).asSymbol], {
			if (gui != False, {

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val });
				};
			});

			//postf("Value: %\n", val.value)

		};

		object[(name++"DrawGui").asSymbol] = Task {

			loop {

				object[(name++"Bus").asSymbol].get({ |val|

					object[(name++"Val").asSymbol] = val;

					//postf("Change value Parameter: %, Value: %\n", name, val);
					if (gui != False, {

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					})
				});

				0.1.wait;
			}
		};

		if (gui != False, {object.layout.nextLine});
	};


	~controls[\setRanger] = { |name, values, object, mode, gui|

		var min = values[0], max = values[1];
		var preMin = values[2], preMax = values[3];

		//postf("Parametername: %, Received Values: %\n", name, values);

		object[(name++"Val").asSymbol] = [preMin, preMax];

		object[(name++"Bus").asSymbol] = Bus.control(s, 2).set(preMin, preMax);

		if (gui != False, {

			object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			object[(name++"Gui").asSymbol] = EZRanger(object.window, 350@20, name, object[(name++"Spec").asSymbol],
				{ |sl|
					object[(name++"Control").asSymbol].value(sl.value);

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

		});

		object[(name++"Control").asSymbol] = { |val|

			if (val.size < 2, { val = [val, val] });

			object[(name++"Bus").asSymbol].set(val[0], val[1]);
			object[(name++"Val").asSymbol] = val;

			if (gui != False, {

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val });
				};
			});

			//postf("name: %, Value: %\n", name, val);
		};

		//object[(name++"drawGuiClock")] = AppClock.new;

		object[(name++"DrawGui").asSymbol] = Task {

			loop {

				object[(name++"Bus").asSymbol].get({ |val|

					object[(name++"Val").asSymbol] = val;

					//postf("Change value Parameter: %, Value: %\n", name, val);
					if (gui != False, {

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					})
				});

				0.1.wait;
			}
		};

		if (gui != False, {object.layout.nextLine});


		//AppClock.play(object[(name++"DrawGui")]);

	};

	~controls[\setKnob] = { |name, values, object, mode, gui|

		var min = values[0], max = values[1], currentVal = values[2];

		//postf("Slider Parametername: %, Received Values: %\n", name, values);

		object[(name++"Val").asSymbol] = currentVal;

		object[(name++"Bus").asSymbol]= Bus.control(s, 1).value = currentVal;

		if (gui != False, {

			object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			//"here".postln;

			object[(name++"Gui").asSymbol] = EZKnob(object.window, 50@90, name, object[(name++"Spec").asSymbol],
				{ |val| object[(name++"Control").asSymbol].value(val.value)}, currentVal);
		});

		object[(name++"Control").asSymbol] = { |val|
			object[(name++"Bus").asSymbol].set(val);
			object[(name++"Val").asSymbol] = val;

			//postf("Value: %\n", val.value);

			if (gui == True, {

				defer {

					if (object[(name++"Gui").asSymbol].value != val,
						{ object[(name++"Gui").asSymbol].value = val; })
				}
			})

		};

		object[(name++"DrawGui").asSymbol] = Task {

			loop {

				object[(name++"Bus").asSymbol].get({ |val|

					object[(name++"Val").asSymbol] = val;

					//postf("Change value Parameter: %, Value: %\n", name, val);
					if (gui != False, {

						defer {

							if (object[(name++"Gui").asSymbol].value != val, {
								object[(name++"Gui").asSymbol].value = val })
						}
					})
				});

				0.1.wait;
			}
		};


	};

	~controls[\setMixer] = { |name, values, object, newObject, mode, gui|

		var min = values[0], max = values[1], currentVal = values[2];

		//postf("Slider Parametername: %, Received Values: %\n", name, values);

		newObject[(name++"Val").asSymbol] = currentVal;

		newObject[(name++"Bus").asSymbol] = Bus.control(s, 1).value = currentVal;

		if (gui != False, {

			//newObject[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

			//"here".postln;

			newObject[(name++"Gui").asSymbol] = Knob.new(object.window, 40@40);

			newObject[(name++"Gui").asSymbol].action_({ |val| newObject[(name++"Control").asSymbol].value(val.value)});
			newObject[(name++"Gui").asSymbol].valueAction_(currentVal);
		});

		newObject[(name++"Control").asSymbol] = { |val|
			newObject[(name++"Bus").asSymbol].set(val);
			newObject[(name++"Val").asSymbol] = val;

			postf("Parameter: %, Value: %\n", name, val.value);

			if (gui == True, {

				defer {

					if (newObject[(name++"Gui").asSymbol].value != val,
						{ newObject[(name++"Gui").asSymbol].valueAction_(val); })
				}
			})

		};

		newObject[(name++"DrawGui").asSymbol] = Task {

			loop {

				newObject[(name++"Bus").asSymbol].get({ |val|

					newObject[(name++"Val").asSymbol] = val;

					//postf("Change value Parameter: %, Value: %\n", name, val);
					if (gui != False, {

						defer {

							if (newObject[(name++"Gui").asSymbol].value != val, {
								newObject[(name++"Gui").asSymbol].valueAction_(val) })
						}
					})
				});

				0.1.wait;
			}
		};


	};


	// ----------------------------------------------------------------------
	//                                  make Player Prototype - Pseudoclass
	// ----------------------------------------------------------------------
	~m_player = {
		arg object, mode,
		m_window = ~oject1, height = 300, width = 500,
		poly = 1, gui = True, bufnum = 0,
		file = False, list = [];

		var slider, instance;

		// ----------------------------------------------------------------------
		//                      Settings of the instrument
		// ----------------------------------------------------------------------

		object = ();
		object.out = Bus.audio(s, ~channelsOut);

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
				object.folder = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "sounds/");
				object.files = PathName.new(thisProcess.nowExecutingPath.dirname +/+ "sounds/").files;

				object.filenames = Array.fill(object.files.size, { |index| object.files[index].fileName});
				object.filebrowser.items = object.filenames;
				object.filebrowser.value = rand(object[\files].size);

				object.sfsource = object.files[object.filebrowser.value].fullPath;
				object.buffer = Buffer.readChannel(s, object.sfsource, channels: 0);
				object.file = 1;
			};

			object.createBrowser.value;

			// ----------------------------- Filebrowser - Action

			object.filebrowser.action = { |selection|

				// load Filepath
				object.drawSoundfile.stop;
				object.sfsource = object.files[selection.value].fullPath;
				object.refreshSoundfileView.value();

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
				'puls', [1, 100, 20], "Slider",
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

			object.track = Synth.head(~synths, \sfplayer, [\sndbuf, object.buffer, \rate, 1, \loop, 0, \out, object[\out].index]);
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


			object.track = Synth.head(~synths, \granulator1, [\sndbuf, object.buffer, \envbuf, -1, \out, object[\out].index]);
			object.track.map(\vol, object.volBus);
			object.track.map(\pan, object.panBus);
			object.track.map(\dur, object.durBus);
			object.track.map(\pos, object.posBus);
			object.track.map(\pitch, object.pitchBus);
			object.track.map(\dens, object.densBus);
			object.track.map(\puls, object.pulsBus);
			object.track.map(\effect1, object.reverbBus);
			object.track.map(\effect2, object.delayBus);




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
						//\channels, ~outChannels
				]);

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
		object.out = Bus.audio(s, ~channelsOut);

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
				'freq', [20, 8000, 220], "Knob",
				'xpan', [-0.5, 0.5, 0], "Knob",
				'attack', [0, 5.0, 0.01], "Knob",
				'decay', [0, 2, 0.1], "Knob",
				'sustain', [0, 1, 0.6], "Knob",
				'release', [0, 10, 0.2], "Knob",
				'ts', [0.01, 10, 1], "Knob",
				'curve', [-5, 5, -4], "Slider",
				'reverb', [0, 1, 0.2], "Slider",
				'delay', [0, 1, 0], "Slider",
				'distort', [0, 1, 0], "Slider",
				//'dur', [0, 20, 0.5], "Slider",
			];

		};

		object.glocke2 = {

			object.list = [
				'trigger', [0, 20, 0.2], "Trigger",
				'volume', [0, 2, 0.5, 1], "Ranger",
				'freq', [20, 8000, 220, 225], "Ranger",
				'xpan', [-0.5, 0.5, -0.5, 0.5], "Ranger",
				'hold', [0, 10, 0.01, 0.1], "Ranger",
				'dens', [0.0001, 0.5, 0.01, 0.05], "Ranger",
				'reverb', [0, 1, 0.2], "Slider",
				'delay', [0, 1, 0], "Slider",
				'attack', [0, 5.0, 0.01], "Knob",
				'decay', [0, 2, 0.1], "Knob",
				'sustain', [0, 1, 0.6], "Knob",
				'release', [0, 10, 0.2], "Knob",
				'ts', [0.01, 10, 1], "Knob",
				'curve', [-5, 5, -4], "Knob",
				'spread', [-5, 5, -4], "Knob",
				'distort', [0, 1, 0], "Knob",
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
				'reverb', [0, 1, 0.8], "Slider"
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
			object.track.map(\curve, object.curveBus);
			object.track.map(\effect1, object.reverbBus);
			object.track.map(\effect2, object.delayBus);
			object.track.map(\effect3, object.distortBus);

		};

		object.glocke1trigger = Task { arg command;

			object.track = Synth.head(~synths, \glocke1, [\gate, 1, \out, object[\out].index]);
			object.track.set(\volume, object.volumeVal);
			object.track.set(\freq, object.freqVal);
			object.track.set(\xpan, object.xpanVal);
			object.track.set(\attack, object.attackVal);
			object.track.set(\decay, object.decayVal);
			object.track.set(\sustain, object.sustainVal);
			object.track.set(\release, object.releaseVal);
			object.track.set(\ts, object.tsVal);
			object.track.set(\curve, object.curveVal);
			object.track.set(\effect1, object.reverbVal);
			object.track.set(\effect2, object.delayVal);
			object.track.set(\effect3, object.distortVal);

			object[\triggerTime].wait;

			object.track.release;


		};

		// -------------------  Soundfile-Player-Stop

		object.glocke1Off= { arg command;

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
			var densMin, densMax, volMin, volMax, freqMin, freqMax, xpanMin, xpanMax, holdMin, holdMax;

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
						\effect2, object[\delayVal],
						\effect3, object[\distortVal],
				]);

				time.wait;
			};
			/*loop {

			time = object[\densVal][0].rrand(object[\densVal][1]);

			if (time < 0.0001, {time = 0.0001});

			object.track = Synth.head(~synths, \glocke2,
			[\out, 0,
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
			\effect2, object[\delayVal],
			]);

			time.wait;
			};*/

		};

		object.glocke2trigger = Task { arg command;

			object.track = Synth.head(~synths, \glocke2, [\gate, 1, \out, object[\out].index]);
			object.track.set(\volume, object.volumeVal);
			object.track.set(\freq, object.freqVal);
			object.track.set(\xpan, object.xpanVal);
			object.track.set(\attack, object.attackVal);
			object.track.set(\decay, object.decayVal);
			object.track.set(\sustain, object.sustainVal);
			object.track.set(\release, object.releaseVal);
			object.track.set(\ts, object.tsVal);
			object.track.set(\curve, object.curveVal);
			object.track.set(\effect1, object.reverbVal);
			object.track.set(\effect2, object.delayVal);
			object.track.set(\effect3, object.distortVal);

			object[\triggerTime].wait;

			object.track.free;


		};

		object.brummelOn= { arg command;

			object.track = Synth.head(~synths, \brummel, [\volume, 1, \out, object[\out].index]);
			object.track.map(\freq1, object.freq1Bus);
			object.track.map(\freq2, object.freq2Bus);
			object.track.map(\width, object.widthBus);
			object.track.map(\puls1, object.puls1Bus);
			object.track.map(\puls2, object.puls2Bus);
			object.track.map(\volume, object.volumeBus);
			object.track.map(\effect1, object.reverbBus);

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
				object.track.set(\effect1, object.reverbVal);

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
		//mono = nil, stereo = nil;
		list = [];

		var slider, instance, busses;

		object = ();

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
				/*'distort', [0, 1, 0], "Mixer",*/
				'vol', [0, 1, 0], "Mixer",
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

		};

		object.reverbOff= { arg command;

			//object.track1.release(0.5);
			object.track1.free;
		};

		object.delayOn= { arg command;

			object.track1 = Synth.head(~effects, \delay, [\in, ~effect2, \out, 0]);
			object.track1.map(\gain, object.gainBus);
			object.track1.map(\buffer, object.bufferBus);
			object.track1.map(\deltime, object.deltimeBus);
			object.track1.map(\volume, object.volumeBus);

		};

		object.delayOff= { arg command;

			//object.track1.release(0.5);
			object.track1.free;

		};

		object.distortOn= { arg command;

			object.track1 = Synth.head(~effects, \distort, [\in, ~effect3, \out, 0]);
			object.track1.map(\gain, object.gainBus);
			object.track1.map(\freq, object.freqBus);
			object.track1.map(\amount, object.amountBus);
			object.track1.map(\volume, object.volumeBus);

		};

		object.distortOff= { arg command;

			//object.track1.release(0.5);
			object.track1.free;

		};

		object.mixerOn= { arg command;

			//var busses = monoIn + stereoIn + multi;

			object.track = ();

			if (monoIn != nil, {

				monoIn.do { |i|

					object[\track][i] = Synth.tail(~synths, \monoIn, [\in, i, \vol, 0.8, \out, 0, \pan, 0.8,
						\effOut1, ~effect1.index, \effOut2, ~effect2.index, \effOut3, ~effect3.index
					]);
					object[\track][i].map(\pan, object[\pan][i][\panBus]);
					object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
					object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
					/*object[\track][i].map(\effect3, object[\distort][i][\distortBus]);*/
					object[\track][i].map(\vol, object[\vol][i][\volBus]);

				}
			});

			if (stereoIn != 0, {

				forBy (monoIn, (monoIn + stereoIn - 1), 2, { |i|

					object[\track][i] = Synth.head(~effects, \stereoIn, [
						\in, [i, i+1], \vol, 0, \out, 0, \effOut1, ~effect1.index,
						\effOut2, ~effect2.index, \effOut3, ~effect3.index
					]);

					//object[\track][i].map(\pan, object[\pan][i][\panBus]);
					object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
					object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
					//object[\track][i].map(\effect3, object[\distort][i][\distortBus]);
					object[\track][i].map(\vol, object[\vol][i][\volBus]);

				})
			});

			if (multi != 0, {

				var counter = 0;

				for (monoIn + stereoIn, monoIn + stereoIn + multi - 1, { |i|

					postf("i = %, counter = %\n", i, counter);

					object[\track][i] = Synth.head(~effects, \multiTrack,
						[\in, ~instruments[counter][\out].index, \vol, 0, \out, 0,
						\effOut1, ~effect1.index, \effOut2, ~effect2.index,
							\effOut3, ~effect3.index]);
					//object[\track][i].map(\pan, object[i].panBus);
					object[\track][i].map(\effect1, object[\reverb][i][\reverbBus]);
					object[\track][i].map(\effect2, object[\delay][i][\delayBus]);
					//object[\track][i].map(\effect3, object[\distort][i][\distortBus]);
					object[\track][i].map(\vol, object[\vol][i][\volBus]);

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
					//var busses = mono[0] + stereo[0];

					//postf("Set Slider: %, Parameter: %, Values: %\n", type, name, varis);
					object.labelparam = StaticText(object.window, 50@35)
					.string_(name)
					.align_(\right)
					.font_(Font("Helvetica-bold", 12))
					.stringColor_(Color.black);

					object[name.asSymbol] = Array.newClear(busses+1);

					busses.do { |k|
						object[name.asSymbol][k] = ();
						~controls[("set"++type).asSymbol].value(name, varis, object, object[name.asSymbol][k], mode, gui);
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

	~main.interface;

	ServerMeterView.new(s, ~object3, 0@0, 8, 2);

	~granulator1 = ~m_player.value(~granulator1, "granulator1", ~object1, height: 360, bufnum: 0);
	~granulator2 = ~m_player.value(~granulator2, "granulator2", ~object1, height: 400, bufnum: 1);
	~glocke1 = ~m_synth.value(~glocke1, "glocke1", ~object2, height: 240);
	~glocke2 = ~m_synth.value(~glocke2, "glocke2", ~object2, height: 320);
	//~mixerIn = ~m_synth.value(~mixerIn, "mixerIn", ~object2, height: 340, mono: [4, 0], stereo: [2, 4]);
	//~brummel = ~m_synth.value(~brummel, "brummel", ~object2, gui: false, height: 220);
	//~sampler = ~m_player.value(~sampler, "sampler", ~object1, height: 220);
	~reverb = ~m_mixer.value(~reverb, "reverb", ~object3, height: 120);
	~delay = ~m_mixer.value(~delay, "delay", ~object3, height: 120);
	~distort = ~m_mixer.value(~distort, "distort", ~object3, height: 120);
	~mixer = ~m_mixer.value(~mixer, "mixer", ~object2, height: 280, width: 500, monoIn: 4, multi: 4);

	//player.start;
	~mixer[\OnControl].value(1);
	~reverb[\OnControl].value(1);

})

)

~instruments[3][\out].index