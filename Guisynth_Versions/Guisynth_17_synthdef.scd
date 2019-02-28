	SynthDef(\sine, { arg stream1 = 0, freq1=110, freq2=10, volume = 0, out = 0, out2 = 8, xpan = 0, ypan = 0.5;
		var output, array1, array2, sin1;
		sin1 = SinOsc.ar(freq1+BrownNoise.kr(freq2), 0, 0.1);

		output = PanAz.ar(~channelsOut2, sin1, xpan, 1);

		Out.ar(out, output * volume.lag(0.2));

	}).add;

	SynthDef(\brummel, {
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

	}).add;

	// ------------------- Soundfile Player without envelope

	SynthDef(\sfplayer, {
		arg sndbuf, out = 0, effect1 = 0,
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

		var output = PanAz.ar(~channelsOut2, limiter, pan, width: width);

		Out.ar(out, output  * amp);
		Out.ar(~effect1, output * effect1);

	}).add;

	// ******************** Granulator

	SynthDef(\granulator1, {
		arg out = 0, out2 = 9, effect1 = 0, effect2,
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
			numChannels: ~channelsOut2,
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
		Out.ar(~effect2, output * effect1);

	}).add;

	// ******************** Granulator2

	SynthDef(\granulator2, {
		|out = 0, out2 = 8, effect1 = 0, effect2 = 0, bufnum, startPos, rate = 1, sustain = 0.02, ts = 1, attac = 0.01, release = 0.1, curve = 1, amp = 0.2, pan = 0.5, ypan = 0.5, width = 2, hanning = 0|

		var env1 = EnvGen.ar(Env.sine(sustain, 1), timeScale: ts, doneAction: 2);
		var env2 = EnvGen.ar(Env.perc(attac, release, 1, curve), timeScale: ts, doneAction: 2);
		var env3 = EnvGen.ar(Env.triangle(sustain, 1), timeScale: ts, doneAction: 2);
		var env4 = EnvGen.ar(Env.asr(attac, sustain, release, curve), timeScale: ts, gate: 1, doneAction: 2);

		var granulator = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, 1, BufFrames.ir(bufnum)*startPos, 0);

		var grain = granulator * Select.kr(hanning, [env1, env2, env3, env4]);

		var output = PanAz.ar(~channelsOut2, grain, pan, width: width);

		Out.ar(out, output * amp);
		Out.ar(~effect1, output * effect1);
		Out.ar(~effect2, output * effect2);


	}, \ir.dup(5)).add;

	// ******************** Record into Buffer
	SynthDef(\bufferRec, {
		| bufnum, rec = 0, in = 0|
		var input = In.ar(in, 1);

		RecordBuf.ar(input, bufnum, 0, 1, run: rec, trigger: Changed.kr(rec), loop: 1);

	}).add;


	// ******************** Record into Buffer
	SynthDef(\bufferRec, {
		| bufnum, rec = 0, in = 0|
		var input = In.ar(in, 1);

		RecordBuf.ar(input, bufnum, 0, 1, run: rec, trigger: Changed.kr(rec), loop: 1);

	}).add;


	// ******************** Levelmeters for output
	SynthDef(\levelmeter, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = In.ar(in, ~channelsOut2) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/levelmeter', [levelmeter, peaklevel], in);

	}).add;

	// ******************** Levelmeters for output
	SynthDef(\levelout, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = In.ar(in, ~channelsOut2) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/levelOut', [levelmeter, peaklevel], in);

	}).add;

	// ******************** Levelmeter for stream
	SynthDef(\levelstream, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = In.ar(in, ~channelsStream) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/levelStream', [levelmeter, peaklevel], in);

	}).add;

	// ******************** Levelmeter for stream
	SynthDef(\levelcloud, {

		|in = 0, out = 100, volume = 1.0|
		var input, output, levelmeter, peaklevel, impuls;

		impuls = Impulse.kr(20);
		output = In.ar(in, ~channelsOut1) * volume;
		levelmeter = Amplitude.kr(output);
		peaklevel = K2A.ar(Peak.ar(output, Delay1.kr(impuls)).lag(0, 3));

		SendReply.kr(impuls, '/levelCloud', [levelmeter, peaklevel], in);

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
		arg out = 0, out2 = 8,
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

		output = PanAz.ar(~channelsOut2, synth, xpan, 2);

		Out.ar(out, output);

	}).add;


	// Synth Multichannel - Definition - Additiver Synth mit zufälligen Obertönen – Frequenz und Ampl. Contr.
	SynthDef(\glocke2, {
		arg out = 0, out2 = 8, effect1= 0, volume = 0, freq = 200, spread = 0.1,
		ts = 1, attack = 0.01, decay = 0.1, sustain = 0.8, hold = 1, release = 0.4, curve = -4,
		pan = 0, xpan = 0, ypan = 0.5, gate = 1, stream1 = 0;

		var n = 5, synth, output, array1, array2, random;

		var env = EnvGen.kr(Env([0, 1, sustain, sustain, 0], [attack, decay, hold, release], curve: curve),
			gate: gate,
			timeScale: ts,
			doneAction: 2);

		synth = Mix.fill(n, {|i|
			random = (freq * Rand(1-spread,(1+spread)) * (i+1));
			SinOsc.ar(random, 0, 1/n)})
		* volume * env;

		output = PanAz.ar(~channelsOut2, synth, xpan, 1);

		Out.ar(out, output);
		Out.ar(~effect1, output * effect1);

	}).add;

	SynthDef(\ampMod, { arg out = 0, rate = 1, volume = 0.2, ampl = 0.3, lag = 0.5;
		var output = Pulse.kr(rate, 0.5, ampl, volume).lag(lag/rate);
		Out.kr(out, output);
	}).add;

	SynthDef(\freqMod, { |out = 0, rate = 0.1, mul = 100, add = 200|
		var output = SinOsc.kr(rate, 0, mul, add);

		Out.kr(out, output);
	}).add;


	SynthDef(\reverb, {
		arg out = 0, in = 0, gain = 1, mix = 1, room = 0.5, damp = 0.5, volume = 1;

		var input = In.ar(in, ~channelsOut2) * gain;
		var output = FreeVerb.ar(input, mix, room, damp, volume);

		Out.ar(out, output);
	}).add;

	SynthDef(\delay, {
		arg out = 0, in = 0, gain = 1, buffer = 2, deltime = 0.25, decay = 1, volume = 1;
		var input = In.ar(in, ~channelsOut2) * gain;

		var output = CombL.ar(input, 2, deltime, decay, volume);

		Out.ar(out, output);

	}).add;

	SynthDef(\distort, {
		arg out = 0, in = 0, gain = 1, freq = 2400, amount = 0.99, volume = 1;

		var input = In.ar(in, ~channelsOut2) * gain;

		var filter = HPF.ar(input, 400)*5;

		var amCoef= 2*amount/(1-amount);

		var output = MidEQ.ar(
			LPF.ar((1+amCoef)*filter/(1+(amCoef*filter.abs)), freq)
			*0.5, 120, 0.7, 0, volume/5);

		Out.ar(out, output);

	}).add;

	SynthDef(\monoIn, {
		|in = 0, out1 = 0, out2 = 50, effOut1 = 0,  effOut2 = 0, effOut3 = 0, stream = 0,
		vol1 = 0, pan = 0.5, vol2 = 0, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = SoundIn.ar(in);
		var output1 = PanAz.ar(~channelsOut1, input, pan-1, vol1, width);
		var output2 = PanAz.ar(~channelsOut2, input, pan-1, vol2, width);
		var outstream = PanAz.ar(~channelsStream, input, pan-1, stream, width);

		Out.ar(out1, output1);
		Out.ar(out2, output2);
		Out.ar(effOut1, output2 * effect1);
		Out.ar(effOut2, output2 * effect2);
		Out.ar(effOut3, output2 * effect3);
		Out.ar(~stream1, outstream);

	}).add;

	SynthDef(\stereoIn, {
		|in = #[50, 51], out1 = 0, out2 = 50, effOut1 = 0,  effOut2 = 0, effOut3 = 0, stream = 0,
		vol1 = 0, pan = 0, vol2 = 0, amp = 1, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = SoundIn.ar(in, amp);
		var output1 = PanAz.ar(~channelsOut1, Mix.ar(input), pan-1, vol1, width);
		var output2 = PanAz.ar(~channelsOut2, Mix.ar(input), pan-1, vol2, width);
		var outstream = PanAz.ar(~channelsStream, Mix.ar(input), pan-1, stream, width);

		Out.ar(out1, output1);
		Out.ar(out2, output2);
		Out.ar(effOut1, output2 * effect1);
		Out.ar(effOut2, output2 * effect2);
		Out.ar(effOut3, output2 * effect3);
		Out.ar(~stream1, outstream);

	}).add;

	SynthDef(\monoTrack, {
		|in = 0, out1 = 0, out2 = 50, effOut1 = 0,  effOut2 = 0, effOut3 = 0, stream = 0,
		vol1 = 0, pan = 0.5, vol2 = 0, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = In.ar(in, 1);
		var output1 = PanAz.ar(~channelsOut1, input, pan-1, vol1, width);
		var output2 = PanAz.ar(~channelsOut2, input, pan-1, vol2, width);
		var outstream = PanAz.ar(~channelsStream, input, pan-1, stream, width);

		Out.ar(out1, output1);
		Out.ar(out2, output2);
		Out.ar(effOut1, output2 * effect1);
		Out.ar(effOut2, output2 * effect2);
		Out.ar(effOut3, output2 * effect3);
		Out.ar(~stream1, outstream);


	}).add;

	SynthDef(\stereoTrack, {
		|in = 0, out1 = 0, out2 = 50, effOut1 = 0,  effOut2 = 0, effOut3 = 0, stream = 0,
		vol1 = 0, pan = 0, vol2 = 1.0, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = In.ar(in, 2);
		var output1 = PanAz.ar(~channelsOut2, Mix.ar(input), pan-1, vol1, width);
		var output2 = PanAz.ar(~channelsOut1, Mix.ar(input), pan-1, vol2, width);
		var outstream = PanAz.ar(~channelsStream, input, pan-1, stream, width);

		Out.ar(out1, output1);
		Out.ar(out2, output2);
		Out.ar(effOut1, output2 * effect1);
		Out.ar(effOut2, output2 * effect2);
		Out.ar(effOut3, output2 * effect3);
		Out.ar(~stream1, outstream);


	}).add;

	SynthDef(\multiTrack, {
		|in = 0, out1 = 0, out2 = 0, effOut1 = 0,  effOut2 = 0, effOut3 = 0, streamOut = 0,
		stream = 0, vol1 = 0, pan = 0,
		vol2 = 1.0, amp = 1, effect1 = 0, effect2 = 0, effect3 = 0, width = 2|

		var input = In.ar(in, ~channelsOut2);
		var output1 = input  * vol1;
		var output2 = input  * vol2;
		var outstream = PanAz.ar(~channelsStream, Mix.ar(input), pan-1, stream, width);


		Out.ar(out1, output1);
		Out.ar(out2, output2);
		Out.ar(effOut1, output2 * effect1);
		Out.ar(effOut2, output2 * effect2);
		Out.ar(effOut3, output2 * effect3);
		Out.ar(streamOut, outstream);


	}).add;

	SynthDef(\stream, {

		|in = 50, out = 0,
		volume = 1.0, gate = 1, level = 1, comp = 1, tresh = 0.5 |
		var input, output;

		input = In.ar(in, ~channelsStream);
		output = Limiter.ar(Compander.ar(input, input, tresh, slopeBelow: gate, slopeAbove: comp, mul: volume), level, 0.01);
		//output = input * volume;

		Out.ar(out, output);

	}).add;

	SynthDef(\cloud, {

		|in = 50, out = 0, cloud = 1.0, level = 1|
		var input, output;

		input = In.ar(in, ~channelsOut1);
		//output = input * cloud;

		output = Limiter.ar(input*cloud, level, 0.01);

		Out.ar(out, output);
	}).add;

	SynthDef(\master, {

		|in = 50, out = 0, master = 1.0, level = 1|
		var input, output;

		input = In.ar(in, ~channelsOut2);
		//output = input * cloud;

		output = Limiter.ar(input*master, level, 0.01);

		Out.ar(out, output);
	}).add;

	SynthDef(\diskout, {
		arg bufnums = #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
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
		DiskOut.ar(bufnums[15], In.ar(15, 1));
		DiskOut.ar(bufnums[15], In.ar(15, 1));
		DiskOut.ar(bufnums[15], In.ar(15, 1));
	}).add;

	// Gruppen definieren

	~masterBus = Group.new;
	~effects = Group.new;
	~busses = Group.new;
	~synths = Group.new;
	~input = Group.new;
	~remote = Group.new;