(

~cs = ();

//~cs[\ip] = ["localhost"];
// ~cs[\ip] = ["localhost", "zero1", "zero2", "zero3", "zero4"];
//~cs[\ip] = ["10.0.1.7", "10.0.1.8", "10.0.1.9", "10.0.1.10", "zero1", "zero2", "zero3", "zero4"];
//~cs[\ip] = ["10.0.0.17", "10.0.0.18", "10.0.0.19", "10.0.0.20"];
~cs[\ip] = ["10.0.1.17", "10.0.1.18"];


~cs[\vol] = [0.01, 0.01, 0.01, 0.01];
~cs[\clients] = ~cs[\ip].size;
~cs[\server] = Array.newClear(~cs[\clients]);
~cs[\message] = Array.newClear(~cs[\clients]);
~cs[\control] = Array.newClear(~cs[\clients]);
/*~buffers = Array.newClear(~clients);
~keys = Array.newClear(~clients);*/

~cs[\setServer] = { arg ip;
	~cs[\clients].do{ |i|
		~cs[\server][i] = Server("cloud"+i, NetAddr(~cs[\ip][i], 57110));
		~cs[\message][i] = NetAddr(~cs[\ip][i], 57120);
		~cs[\control][i] = NetAddr(~cs[\ip][i], 9000);
		~cs[\server][i].initTree;
	}
};

~cs[\setServer].value(~cs[\ip]);

~cs[\synthdef] = ();
~cs[\effect1] = ();
~cs[\effect2] = ();
~cs[\effect3] = ();
~cs[\effect4] = ();

~cs.clients.do { |i|

	~cs[\effect1][i] = Bus.audio(~cs[\server][i], 2);
	~cs[\effect2][i] = Bus.audio(~cs[\server][i], 2);
	~cs[\effect3][i] = Bus.audio(~cs[\server][i], 2);
	~cs[\effect4][i] = Bus.audio(~cs[\server][i], 2);
};


~cs[\synthdef][0] = SynthDef(\sine, { arg stream1 = 0, freq1=110, freq2=10, volume = 0, out = 0, out2 = 8, xpan = 0, ypan = 0.5;
	var output, array1, array2, sin1;
	sin1 = SinOsc.ar(freq1+BrownNoise.kr(freq2), 0, 0.1);

	output = Pan2.ar(sin1, xpan, 1);

	Out.ar(out, output * volume.lag(0.2));

});

~cs[\synthdef][1] = SynthDef(\brummel, {
	arg out = 0, stream1 = 0,
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

});

~cs[\synthdef][2] = SynthDef(\sfplayer, {
	arg sndbuf, out = 0, effect1 = 0, effect1Out = 0,
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

	var output = Pan2.ar(limiter, pan);

	Out.ar(out, output  * amp);
	Out.ar(effect1Out, output * effect1);

}).add;

~cs[\synthdef][3] = SynthDef(\granulator1, {

	arg out = 0, out2 = 9, channels = 2, speaker = 0,
	effect1 = 0, effect1Out = 0, effect2 = 0, effect2Out,
	gate = 1, puls = 20, width = 2, sndbuf, envbuf, cloud = 0,
	dur = #[0.09, 0.11],
	pos = #[0, 1],
	pitch = #[0.99, 1.01],
	dens = #[20, 20],
	pan = #[-0.5, 0.5],
	ypan = 0.5,
	vol = #[0, 0];

	var env, density, granulator, output, array1, array2, position, panning;

	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1),
		gate: gate,
		levelScale: 1,
		doneAction: 2);

	density = Impulse.kr(WhiteNoise.kr(dens[1], dens[0])+puls);

	granulator = GrainBuf.ar(
		numChannels: 2,
		trigger: density,
		dur: WhiteNoise.kr(1).range(dur[0], dur[1]), // size of the grain
		sndbuf: sndbuf,
		rate: WhiteNoise.kr(1).range(pitch[0], pitch[1]),
		pos: WhiteNoise.kr(1).range(pos[0], pos[1]),
		interp: 2, // pitchshifting interpolation: 1 = no, 2 = linear, 4 = cubic
		pan: WhiteNoise.kr(1).range(pan[0], pan[1]), // depends on number of channels: 1: no panning, 2: -1 to +1
		envbufnum: envbuf) * env * LFNoise2.kr(density).range(vol[0], vol[1]);

	position = pan * pi;

	panning = speaker * pi;

	output = cloud * granulator * (pow(0.5 * (1 + cos(position - panning)), 4));

	Out.ar(out, output);
	Out.ar(effect1Out, output * effect1);
	Out.ar(effect2Out, output * effect2);

});

~cs[\synthdef][4] =	SynthDef(\granulator2, {
	|out = 0, out2 = 8, effect1 = 0, effect1Out = 20, effect2 = 0, effect2Out = 40,
	cloud = 0, speaker = 0,
	bufnum, startPos, rate = 1, sustain = 0.02, ts = 1, attac = 0.01, release = 0.1, curve = 1, amp = 0.2, pan = 0.5, ypan = 0.5, width = 2, hanning = 0|

	var env1 = EnvGen.ar(Env.sine(sustain, 1), timeScale: ts, doneAction: 2);
	var env2 = EnvGen.ar(Env.perc(attac, release, 1, curve), timeScale: ts, doneAction: 2);
	var env3 = EnvGen.ar(Env.triangle(sustain, 1), timeScale: ts, doneAction: 2);
	var env4 = EnvGen.ar(Env.asr(attac, sustain, release, curve), timeScale: ts, gate: 1, doneAction: 2);

	var granulator = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, 1, BufFrames.ir(bufnum)*startPos, 0);

	var grain = granulator * Select.kr(hanning, [env1, env2, env3, env4]);

	var position = pan * pi;

	var panning = speaker * pi;

	var output = cloud * grain * (pow(0.5 * (1 + cos(position - panning)), 4));

	Out.ar(out, output * amp);
	Out.ar(effect1Out, output * effect1);
	Out.ar(effect2Out, output * effect2);

}, \ir.dup(5));

~cs[\synthdef][5] =	SynthDef(\glocke1, {
	arg out = 0, speaker = 0,
	volume = 0, freq = 200, spread = 0.1,
	ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, release = 0.4, curve = -4,
	pan = 0, xpan = 0, ypan = 0.5, width = 2, gate = 1;

	var n = 5, synth, output, position, panning, random;

	var env = EnvGen.kr(Env.adsr(attack, decay, sustain, release, curve: curve),
		gate: gate,
		timeScale: ts,
		doneAction: 2);

	synth = Mix.fill(n, {|i|
		random = (freq.lag(0.2)  * Rand(1-spread,(1+spread)) * (i+1));
		SinOsc.ar(random, 0, 1/n)})
	* env;

	position = xpan * pi;

	panning = speaker * pi;

	output = volume * synth * (pow(0.5 * (1 + cos(position - panning)), 4));

	Out.ar(out, output);

});

~cs[\synthdef][6] = SynthDef(\glocke2, {
	arg out = 0, speaker = 0, effect1 = 0, effect1Out = 0,  effect2 = 0, effect2Out = 0,
	volume = 0, freq = 200, spread = 0.1, ts = 1,
	attack = 0.01, decay = 0.1, sustain = 0.8, hold = 1, release = 0.4, curve = -4,
	pan = 0, xpan = 0, ypan = 0.5, gate = 1, stream1 = 0;

	var n = 5, synth, output, position, panning, random;

	var env = EnvGen.kr(Env([0, 1, sustain, sustain, 0], [attack, decay, hold, release], curve: curve),
		gate: gate,
		timeScale: ts,
		doneAction: 2);

	synth = Mix.fill(n, {|i|
		random = (freq * Rand(1-spread,(1+spread)) * (i+1));
		SinOsc.ar(random, 0, 1/n)})
	* volume * env;

	position = xpan * pi;

	panning = speaker * pi;

	output = volume * synth * (pow(0.5 * (1 + cos(position - panning)), 4));

	Out.ar(out, output);
	Out.ar(effect1Out, output * effect1);
	Out.ar(effect2Out, output * effect2);

});

~cs[\synthdef][7] = SynthDef(\ampMod, { arg out = 0, rate = 1, volume = 0.2, ampl = 0.3, lag = 0.5;
	var output = Pulse.kr(rate, 0.5, ampl, volume).lag(lag/rate);
	Out.kr(out, output);
}).add;

~cs[\synthdef][8] = SynthDef(\freqMod, { |out = 0, rate = 0.1, mul = 100, add = 200|
	var output = SinOsc.kr(rate, 0, mul, add);

	Out.kr(out, output);
});

~cs[\synthdef][9] = SynthDef(\reverb, {
	arg out = 0, in = 20, speaker = 0, gain = 1, mix = 1, room = 0.5, damp = 0.5, volume = 1;

	var input = In.ar(in, 2) * gain;
	var output = FreeVerb.ar(input, mix, room, damp, volume);

	Out.ar(out, output);
});

~cs[\synthdef][10] = SynthDef(\delay, {
	arg out = 0, in = 40, speaker = 0, gain = 1, buffer = 2, deltime = 0.25, decay = 1, volume = 1;
	var input = In.ar(in, 2) * gain;

	var output = CombL.ar(input, 2, deltime, decay, volume);

	Out.ar(out, output);

});

~cs[\synthdef][11] = SynthDef(\distort, {
	arg out = 0, in = 60, speaker = 0, gain = 1, freq = 2400, amount = 0.99, volume = 1;

	var input = In.ar(in, 2) * gain;

	var filter = HPF.ar(input, 400)*5;

	var amCoef= 2*amount/(1-amount);

	var output = MidEQ.ar(
		LPF.ar((1+amCoef)*filter/(1+(amCoef*filter.abs)), freq)
		*0.5, 120, 0.7, 0, volume/5);

	Out.ar(out, output);

});

~cs[\synthdef][12] = SynthDef(\cloud, {

	|in = 50, out = 0, cloud = 1.0, level = 1, speaker = 0|
	var input, position, panning, output;

	input = In.ar(in, 2);
	//output = input * cloud;

	output = Limiter.ar(input*cloud, level, 0.01);

	Out.ar(out, output);
});

~cs[\synthdef][12] = SynthDef(\master, {

	|in = 50, out = 0, volume = 1.0, level = 1, speaker = 0|
	var input, output;

	input = In.ar(in, 2);
	//output = input * cloud;

	output = Limiter.ar(input*volume, level, 0.01);

	Out.ar(out, output);
});

~cs[\synthdef][13] = SynthDef(\noisetest, { arg out = 0, vol = 0.2;
	var osc, env;
	env = EnvGen.kr(Env.perc(0.01, 1), doneAction: 2);
	osc = WhiteNoise.ar(vol) *env; // 800 Hz sine oscillator

	Out.ar(out, osc); // send output to audio bus zero.
});

~cs[\synthdef][14] = SynthDef(\sinetest, { arg out = 0, freq = 220, vol = 0.2;
	var osc, env;
	env = EnvGen.kr(Env.sine(0.5, 1), doneAction: 2);
	osc = SinOsc.ar(freq, 0, vol) *env; // 800 Hz sine oscillator

	Out.ar(out, osc); // send output to audio bus zero.
});

~cs.clients.do { |i|

	~cs[\synthdef].do { |k|
		k.postln;
		k.send(~cs[\server][i]);
	};

	/*	~master = Group.new(~cs[\server][i]);
	~effects = Group.new(~cs[\server][i]);
	~busses = Group.new(~cs[\server][i]);
	~synths = Group.new(~cs[\server][i]);
	~input = Group.new(~cs[\server][i]);
	~remote = Group.new(~cs[\server][i]);*/
};

~cs[\synth] = { |object, synth, args, targets, sndbuf = nil, addAction = 'addToHead'|

	var speakers = targets.size;

	object = ();

	args = args.insert(0, 'speaker');
	args = args.insert(1, 1);

	if (sndbuf != nil, { args = args.insert(2, 'bufnum'); args = args.insert(3, sndbuf) });

	speakers.do {|i|

		var speaker = i/(speakers);

		args.put(1, speaker);
		if (sndbuf != nil, { args.put(3, sndbuf[i])});


		//postf("Parameters: %, Iteration: %, speaker: % \n", args, i, speaker);

		object[i] = Synth.new(synth, args, target: targets[i], addAction: addAction);
	};

	object.cmap = {|param, bus|

		targets.size.do {|i|

			object[i].map(param, bus[i]);
		}
	};

	object.cbus = {|param, bus|

		targets.size.do {|i|

			object[i].map(param, bus[i].index);
		}
	};

	object.cset = {|param, value|

		targets.size.do {|i|

			object[i].set(param, value);
		}
	};

	object.cbuf = {|param, buff|

		targets.size.do {|i|

			object[i].set(param, buff[i]);
		}
	};

	object.cfree = {

		targets.size.do {|i|

			object[i].free;
		}
	};

	object.crelease = {|value = 0|

		targets.size.do {|i|

			object[i].release;
		}
	};

	object.cpan = { |panning, vol|

		/*speakers.do {|i|
		var position = panning * pi;
		var speaker = 2*pi/speakers*i;

		var output = vol * (pow(0.5 * (1 + cos(speaker - position)), 2));

		object[i].set(\volume, output);

		};*/
	};
};

~cs[\cbuf] = {|object, sfpath, targets|

	var speakers = targets.size;

	object = ();

	speakers.size.do {|i|

		object[i] = Buffer.readChannel(speakers[i], sfpath, channels: 0);
	};
};

~cs.test1 = Task {
	loop {

		~cs.server.size.do { |i|

			x = Synth.new(\noisetest, [\out, 0], ~cs.server[i]);

			1.wait;
		};

	}
};

~cs.test2 = Task {
	loop {

		~cs.server.size.do { |i|

			x = Synth.new(\sinetest, [\out, 0, \vol, 0.1], ~cs.server[i]);

			1.wait;
		};

	}
};

~cs[\test] = ();

~cs[\test].on = { |test|

	~cs.test1.play;

};

~cs[\test].off = { |test|

	~cs.test1.stop;

};




~cs.freeAll = {
	~cs.clients.do { |i|
		~cs.server[i].freeAll;
	}
};



// x = Synth.new(\sine, [\volume, 0.5, \freq1, 220, \freq2, 40], target: ~cs.server[2], addAction: 'addToHead');
// x.free;


// x = Synth.new(\sine, [\volume, 0.01, \freq1, 220, \freq2, 40], target: ~cs.server[0], addAction: 'addToHead');
// x.free;
//~cs.freeAll;
)