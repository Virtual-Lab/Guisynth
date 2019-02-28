(

// -------------------------------------------------------------------------
// Controller Midi und Controller GUI - Zugeschnitten auf Livid - Alias 8
// -------------------------------------------------------------------------


// Arrays der  und Knobs
// Midiprogrammnumbers der Sliders
~sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];
~knob1Numbers = [9, 10, 11, 12, 13, 14, 15, 16];
~knob2Numbers = [17, 18, 19, 20, 21, 22, 23, 24];

// Midichannel der Sliders, Anzahl der Sliders und Channels
~sliderChannels = [0, 1, 2, 3, 4, 5, 6, 7];
~sliderRows = ~sliderChannels.size;
~sliderColums = ~sliderNumbers.size;

~masterfadernumber = 25;
~masterctlnumber = 42;

MIDIIn.connectAll;
// MIDIIn.connect("nanoKONTROL", "SLIDER/KNOB");

MIDIFunc.cc( {| midi, num, ch, x|

	var val = (midi.value)/127;
	var buttonstatus = 0;

	//postf("controller: % % % % %\n", ch, num, midi/127, x, y);


	~instruments.do { |i|

		// Steuerungen der Instrument GUI ------------------

		if(num == ~sliderNumbers[0]
			and: {ch == ~sliderChannels[i]},
			{
				/*if (~instr[i].densityRange.map(val) + ~instr[i].densityValue[1] - ~instr[i].densityValue[0]
				<= ~instr[i].densityRange.map(1), {*/

				defer {
					~instr[i].densityGui.valueAction_(
						[~instr[i].densityRange.map(val),
							~instr[i].densityRange.map(val) +
							~instr[i].densityValue[1] - ~instr[i].densityValue[0]]);

			}}
		);

		if(num == ~knob1Numbers[0]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].densityGui.valueAction_(
					[~instr[i].densityValue[0],
						(~instr[i].densityValue[0] +
							~instr[i].densityRange.map(val))]);

			}}
		);

		if(num == ~sliderNumbers[1]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].grainlengthGui.valueAction_(
					[~instr[i].grainlengthRange.map(val),
						~instr[i].grainlengthRange.map(val) +
						~instr[i].grainlengthValue[1] - ~instr[i].grainlengthValue[0]]);

			}}
		);

		if(num == ~knob1Numbers[1]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].grainlengthGui.valueAction_(
					[~instr[i].grainlengthValue[0],
						~instr[i].grainlengthValue[0] +
						~instr[i].grainlengthRange.map(val)]);

			}}
		);

		if(num == ~sliderNumbers[2]
			and: {ch == ~sliderChannels[i]},
			{
				/*if (~instr[i].pitchRange.map(val) + (~instr[i].pitchValue[1] - ~instr[i].pitchValue[0])
				<=  ~instr[i].pitchRange.map(1), {*/

				defer {~instr[i].pitchGui.valueAction_(
					[~instr[i].pitchRange.map(val),
						~instr[i].pitchRange.map(val) +
						(~instr[i].pitchValue[1] - ~instr[i].pitchValue[0])]);

			}}
		);

		if(num == ~knob1Numbers[2]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].pitchGui.valueAction_(
					[~instr[i].pitchValue[0],
						~instr[i].pitchValue[0] +
						~instr[i].pitchRange.map(val)]);

			}}
		);

		if(num == ~knob2Numbers[6]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].effect1Gui.valueAction_(val);

			}}
		);

		if(num == ~knob2Numbers[7]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].effect2Gui.valueAction_(val);

			}}
		);

		if(num == ~sliderNumbers[5]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].panGui.valueAction_(
					[~instr[i].panRange.map(val),
						~instr[i].panRange.map(val) +
						~instr[i].panValue[1]  - ~instr[i].panValue[0]]);

			}}
		);

		/*if(num == ~knob1Numbers[5]
		and: {ch == ~sliderChannels[i]},
		{
		defer {~instr[i].panGui.valueAction_(
		[~instr[i].panValue(0),
		~instr[i].panValue[0] +
		(~instr[i].panRange.map(val))]);

		}}
		);*/

		if(num == ~sliderNumbers[6]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].volumeGui.valueAction_(
					[~instr[i].volumeRange.map(val),
						~instr[i].volumeRange.map(val) +
						~instr[i].volumeValue[1] - ~instr[i].volumeValue[0]]);

			}}
		);

		if(num == ~knob1Numbers[6]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].volumeGui.valueAction_(
					[~instr[i].volumeValue[0],
						~instr[i].volumeValue[0] +
						~instr[i].volumeRange.map(val) ]);

			}}
		);

		if(num == ~sliderNumbers[7]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].selectionGui.valueAction_(
					[val, val + ~instr[i].selection[1] - ~instr[i].selection[0]]);

			}}
		);

		if(num == ~knob1Numbers[7]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].selectionGui.valueAction_(
					[~instr[i].selection[0], ~instr[i].selection[0] + val]);

			}}
		);

	};
},srcID: -462854042);

MIDIFunc.noteOn({ |midi, num, ch, x|
	//postf("Note On: % % % %\n", ch, num, midi, x);

	~instruments.do { |i|

		if(num == 0
			and: {ch == ~sliderChannels[i]},
			{
				if (~instr[i].startbuttonValue == 0, {
					~instr[i].startbuttonValue = 1;
					defer {~instr[i].startbuttonGui.valueAction_(1)}
					}, {
						~instr[i].startbuttonValue = 0;
						defer {~instr[i].startbuttonGui.valueAction_(0)}
				})
		});



		if(num == 1
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].recordGui.valueAction_(1)};

			}
		);
	};

}, srcID: -462854042);

MIDIFunc.noteOff({ |midi, num, ch, x|
	//postf("Note Off: % % % %\n", ch, num, midi, x);

	~instruments.do { |i|

		if(num == 1
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].recordGui.valueAction_(0)};

			}
		);
	};

}, srcID: -462854042);

"control patch enabled";
)

/*	(
MIDIIn.connect;    // init for one port midi interface
// register functions:
~noteOff = { arg src, chan, num, vel;    [chan,num,vel / 127].postln; };
~noteOn = { arg src, chan, num, vel;    [chan,num,vel / 127].postln; };
~polytouch = { arg src, chan, num, vel;    [chan,num,vel / 127].postln; };
~control = { arg src, chan, num, val;    [chan,num,val].postln; };
~program = { arg src, chan, prog;        [chan,prog].postln; };
~touch = { arg src, chan, pressure;    [chan,pressure].postln; };
~bend = { arg src, chan, bend;        [chan,bend - 8192].postln; };
~sysex = { arg src, sysex;        sysex.postln; };
~sysrt = { arg src, chan, val;        [chan,val].postln; };
~smpte = { arg src, chan, val;        [chan,val].postln; };
MIDIIn.addFuncTo(\noteOn, ~noteOn);
MIDIIn.addFuncTo(\noteOff, ~noteOff);
MIDIIn.addFuncTo(\polytouch, ~polytouch);
MIDIIn.addFuncTo(\control, ~control);
MIDIIn.addFuncTo(\program, ~program);
MIDIIn.addFuncTo(\touch, ~touch);
MIDIIn.addFuncTo(\bend, ~bend);
MIDIIn.addFuncTo(\sysex, ~sysex);
MIDIIn.addFuncTo(\sysrt, ~sysrt);
MIDIIn.addFuncTo(\smpte, ~smpte);
)

//cleanup
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOn);
MIDIIn.removeFuncFrom(\noteOff, ~noteOff);
MIDIIn.removeFuncFrom(\polytouch, ~polytouch);
MIDIIn.removeFuncFrom(\control, ~control);
MIDIIn.removeFuncFrom(\program, ~program);
MIDIIn.removeFuncFrom(\touch, ~touch);
MIDIIn.removeFuncFrom(\bend, ~bend);
MIDIIn.removeFuncFrom(\sysex, ~sysex);
MIDIIn.removeFuncFrom(\sysrt, ~sysrt);
MIDIIn.removeFuncFrom(\smpte, ~smpte);
)*/