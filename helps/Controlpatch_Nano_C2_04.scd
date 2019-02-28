(

// -------------------------------------------------------------------------
// Controller Midi und Controller GUI - Zugeschnitten auf Korg Nanocontrol 1
// -------------------------------------------------------------------------


// Arrays der  und Knobs
// Midiprogrammnumbers der Sliders
~sliderNumbers = [2, 3, 4, 5, 6, 8, 9, 12, 13];
~knobNumbers = [14, 15, 16, 17, 18, 19, 20, 21, 22];

~slider2Numbers = (1 .. 8);
~knob2Numbers = (17 .. 24);

// Midichannel der Sliders, Anzahl der Sliders und Channels
~sliderChannels = [10, 11, 12, 13];
~sliderRows = ~sliderChannels.size;
~sliderColums = ~sliderNumbers.size;

~button1Numbers = Array.fill([~sliderRows, ~sliderColums], 100.rand);
~button1Numbers[0] = [23, 24, 25, 26, 27, 28, 29, 30, 31];
~button1Numbers[1] = [67, 68, 69, 70, 71, 72, 73, 74, 75];
~button1Numbers[2] = [76, 77, 78, 79, 80, 81, 82, 83, 84];
~button1Numbers[3] = [85, 86, 87, 88, 89, 90, 91, 92, 93];

~button2Numbers = Array.fill([~sliderRows, ~sliderColums], 100.rand);
~button2Numbers[0] = [33, 34, 35, 36, 37, 38, 39, 40, 41];
~button2Numbers[1] = [33, 34, 35, 36, 37, 38, 39, 40, 41];
~button2Numbers[2] = [33, 34, 35, 36, 37, 38, 39, 40, 41];
~button2Numbers[3] = [33, 34, 35, 36, 37, 38, 39, 40, 41];

// Array der controlbusses und -Values
~sliders = Array.fill([~sliderRows, ~sliderColums], { Bus.control() });
~knobs = Array.fill([~sliderRows, ~sliderColums], { Bus.control() });
~button1 = Array.fill([~sliderRows, ~sliderColums], { Bus.control() });
~button2 = Array.fill([~sliderRows, ~sliderColums], { Bus.control() });

~relative = Array.fill([~sliderRows, ~sliderColums], { Bus.control() });

~sliderValue = Array.fill([~sliderRows, ~sliderColums], 0);
~knobValue = Array.fill([~sliderRows, ~sliderColums], 0);
~button1Value = Array.fill([~sliderRows, ~sliderColums], 0);
~button2Value = Array.fill([~sliderRows, ~sliderColums], 0);
~knobMax = Array.fill([~sliderRows, ~sliderColums], 0);
~knobMin = Array.fill([~sliderRows, ~sliderColums], 0);

//---------------------------------------------------------------------------
//               controlpatch - Indexierung
//---------------------------------------------------------------------------

MIDIIn.connectAll;
//MIDIIn.connect("nanoKONTROL", "SLIDER/KNOB");

MIDIFunc.cc( {| midi, num, ch |


	var val = (midi.value)/127;
	var buttonstatus = 0;

	//postf("controller: % % % \n", ch, num, midi/127);
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

		if(num == ~knobNumbers[0]
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
				/*if (~instr[i].pitchRange.map(val) + (~instr[i].pitchValue[1] - ~instr[i].pitchValue[0])
				<=  ~instr[i].pitchRange.map(1), {*/

				defer {~instr[i].pitchGui.valueAction_(
					[~instr[i].pitchRange.map(val),
						~instr[i].pitchRange.map(val) +
						(~instr[i].pitchValue[1] - ~instr[i].pitchValue[0])]);

			}}
		);

		if(num == ~knobNumbers[1]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].pitchGui.valueAction_(
					[~instr[i].pitchValue[0],
						~instr[i].pitchValue[0] +
						~instr[i].pitchRange.map(val)]);

			}}
		);

		if(num == ~sliderNumbers[2]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].grainlengthGui.valueAction_(
					[~instr[i].grainlengthRange.map(val),
						~instr[i].grainlengthRange.map(val) +
						~instr[i].grainlengthValue[1] - ~instr[i].grainlengthValue[0]]);

			}}
		);

		if(num == ~knobNumbers[2]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].grainlengthGui.valueAction_(
					[~instr[i].grainlengthValue[0],
						~instr[i].grainlengthValue[0] +
						~instr[i].grainlengthRange.map(val)]);

			}}
		);

		if(num == ~sliderNumbers[4]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].effect1Gui.valueAction_(val);

			}}
		);

		if(num == ~sliderNumbers[5]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].effect2Gui.valueAction_(val);

			}}
		);

		if(num == ~sliderNumbers[6]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].panGui.valueAction_(
					[~instr[i].panRange.map(val),
						~instr[i].panRange.map(val) +
						~instr[i].panValue[1]  - ~instr[i].panValue[0]]);

			}}
		);

		if(num == ~knobNumbers[6]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].panGui.valueAction_(
					[~instr[i].panValue[0],
						~instr[i].panValue[0] +
						~instr[i].panRange.map(val)]);

			}}
		);

		if(num == ~sliderNumbers[7]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].volumeGui.valueAction_(
					[~instr[i].volumeRange.map(val),
						~instr[i].volumeRange.map(val) +
						~instr[i].volumeValue[1] - ~instr[i].volumeValue[0]]);

			}}
		);

		if(num == ~knobNumbers[7]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].volumeGui.valueAction_(
					[~instr[i].volumeValue[0],
						~instr[i].volumeValue[0] +
						~instr[i].volumeRange.map(val) ]);

			}}
		);

		if(num == ~sliderNumbers[8]
			and: {ch == ~sliderChannels[i]},
			{

				defer {~instr[i].selectionGui.valueAction_(
					[val, val + ~instr[i].selection[1] - ~instr[i].selection[0]]);

			}}
		);

		if(num == ~knobNumbers[8]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].selectionGui.valueAction_(
					[~instr[i].selection[0], ~instr[i].selection[0] + val]);

			}}
		);

		if(num == ~button1Numbers[i][0]
			and: {ch == ~sliderChannels[i]}
			and: {val == 1},
			{
				if (~instr[i].startbuttonValue == 0, {
					~instr[i].startbuttonValue = 1;
					defer {~instr[i].startbuttonGui.valueAction_(1)}
					}, {
						~instr[i].startbuttonValue = 0;
						defer {~instr[i].startbuttonGui.valueAction_(0)}
				})
		});


		if(num == ~button1Numbers[i][1]
			and: {ch == ~sliderChannels[i]},
			{
				defer {~instr[i].recordGui.valueAction_(val)};

			}
		);

		if(num == ~button1Numbers[i][5]
			and: {ch == ~sliderChannels[i]}
			and: {val == 1},
			{
				if (~instr[i].effect1Buttonstate == 0, {
					~instr[i].effect1Buttonstate = 1;
					defer {~instr[i].effect1Button.valueAction_(1)}
					}, {
						~instr[i].effect1Buttonstate = 0;
						defer {~instr[i].effect1Button.valueAction_(0)};
				})


			}
		);

		if(num == ~button1Numbers[i][6]
			and: {ch == ~sliderChannels[i]}
			and: {val == 1},
			{
				if (~instr[i].effect2Buttonstate == 0, {
					~instr[i].effect2Buttonstate = 1;
					defer {~instr[i].effect2Button.valueAction_(1)}
					}, {
						~instr[i].effect2Buttonstate = 0;
						defer {~instr[i].effect2Button.valueAction_(0)};
				})

			}
		);

		~inputs.do { |k|

			if(num == ~button2Numbers[i][k]
				and: {ch == ~sliderChannels[i]}
				and: {val == 1},
				{
					if (~io.matrixstate[i][k] == 0, {
						~io.matrixstate[i][k] = 1;
						defer {~io.matrix[i][k].valueAction_(1)}
						}, {
							~io.matrixstate[i][k] = 0;
							defer {~io.matrix[i][k].valueAction_(0)}
					})
				}
			);
		};




	};
}, srcID: 214394786);

MIDIFunc.cc( {| midi, num, ch, x |

	var val = (midi.value)/127;

	//postf("controller: % % % % \n", ch, num, midi/127, x, y);

	(~outputs+~outbusses).do { |i|

		if(num == ~slider2Numbers[i]
			and: {ch == 9}, {

				defer {
					~io.outVol[i].valueAction_(
						~io.outVolRange.map(val.value));
				};
		});
	};

	~inputs.do { |i|

		if(num == ~knob2Numbers[i]
			and: {ch == 9}, {

				defer {
					~io.gain[i].valueAction_(val.value)
				};
		});
	};

}, srcID: -2136708848);

MIDIFunc.cc( {| midi, num, ch, x |

	var val = (midi.value)/127;

	postf("controller: % % % % \n", ch, num, midi/127, x, y);

	~io.effect2keys.do{ |assign, i|

		var key = assign;

		if(num == 10
			and: {ch == 9}, {

				defer {
					~io.effect2Knob[key].valueAction_(
						~io.effect2Spec[key].map(val.value));
				};
		});
	};

}, /*srcID: -693592348*/);



"control patch enabled";
)