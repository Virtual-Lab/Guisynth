~piSet = {

	~pisound = Server("pisound", NetAddr("stream", 57110));
	~pisound.initTree;

	~piOut = SynthDef(\piout, {
		|in = 0, out = 0, amp = 1, pan = 0|

		// input and output variables
		var input = SoundIn.ar([in, in+1], amp);

		Out.ar(out, input);

	});

	~piSynth = SynthDef(\sine, { arg stream1 = 0, freq1=110, freq2=10, volume = 0, out = 0, out2 = 8, xpan = 0, ypan = 0.5;
		var output, array1, array2, sin1;
		sin1 = SinOsc.ar(freq1+BrownNoise.kr(freq2), 0, 0.1);

		output = Pan2.ar(sin1, xpan, 1);

		Out.ar(out, output * volume.lag(0.2));

	});

	~piOut.send(~pisound);
	~piSynth.send(~pisound);

	~piHeadphone = Synth.new(\piout, target: ~pisound);
	// ~piSynthTest = Synth.new(\sine, [\volume, 0.2], target: ~pisound);
	// ~piSynthTest.free;
	// ~piHeadphone.free;
	// ~pisound.freeAll;
};
