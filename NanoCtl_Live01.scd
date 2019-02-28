// -------------------------------------------------------------------------
// Controller Midi und Controller GUI - Zugeschnitten auf Korg Nanocontrol 1
// -------------------------------------------------------------------------
	~nc = ();

    // Arrays der  und Knobs
    // Midiprogrammnumbers der Sliders
	~nc.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];
	~nc.knobNumbers = [33, 34, 35, 36, 37, 38, 39, 40];

    // Midichannel der Sliders, Anzahl der Sliders und Channels
	~nc.sliderChannels = [0];
	~nc.sliderRows = ~nc.sliderChannels.size;
	~nc.sliderColums = ~nc.sliderNumbers.size;

	~nc.button1Numbers = Array.fill([~nc.sliderRows, ~nc.sliderColums], 100.rand);
	~nc.button1Numbers[0] = [48, 49, 50, 51, 52, 53, 54, 55];

	~nc.button2Numbers = Array.fill([~nc.sliderRows, ~nc.sliderColums], 100.rand);
	~nc.button2Numbers[0] = [64, 65, 66, 67, 68, 69, 70, 71];

	~nc.button3Numbers = Array.fill([~nc.sliderRows, ~nc.sliderColums], 100.rand);
	~nc.button3Numbers[0] = [72, 73, 74, 75, 76, 77, 78, 79];


	// Array der controlbusses und -Values
	~nc.slider = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });
    ~nc.knob = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });
    ~nc.button1 = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });
    ~nc.button2 = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });
	~nc.button3 = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });

    ~nc.relative = Array.fill([~nc.sliderRows, ~nc.sliderColums], { Bus.control() });

	~nc.sliderValue = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);
    ~nc.knobValue = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);
    ~nc.button1Value = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);
    ~nc.button2Value = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);
	~nc.button3Value = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);

    ~nc.knobMax = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);
    ~nc.knobMin = Array.fill([~nc.sliderRows, ~nc.sliderColums], 0);


// -------------------------------------------------------------------------
//                         Steuerung ueber die MIDI
// -------------------------------------------------------------------------

//MIDIIn.connectAll;

MIDIFunc.cc( {| val, num, ch |

		//postf("controller: % % % \n", ch, num, val/127);

~nc.sliderRows.do{ |u|

	~nc.sliderColums.do {|i|

		var slider = ~nc.sliderNumbers[i];
		var knob = ~nc.knobNumbers[i];
		var button1 = ~nc.button1Numbers[u][i];
		var button1state = 0;
		var button2 = ~nc.button2Numbers[u][i];
		var button3 = ~nc.button3Numbers[u][i];

		// Slidersteuerung ueber die MIDI
		if(slider == num
			and: {ch == ~nc.sliderChannels[u]}
				and: {(val - (~nc.sliderValue[u][i]*127)).abs < 15},

				{
					~nc.slider[u][i].value = (val/127);
					// postf("Slider: % % % %\n", ch, num, val/127, (val - ~sliderValue[u][i]).abs);
					~nc.sliderValue[u][i] = (val/127);

				}
			);

		// Knobsteuerung ueber die MIDI
		if(knob == num
			and: {ch == ~nc.sliderChannels[u]}
				and: {(val - (~nc.knobValue[u][i]*127)).abs < 15},

				{
					~nc.knob[u][i].value = (val/127);
					// postf("Slider: % % % %\n", ch, num, val/127, (val - ~knobValue[u][i]).abs);
					~nc.knobValue[u][i] = (val/127);

				}
			);

		// ButtonSteuerung ueber Midi - Button 1: on/off
		if(button1 == num
			and: {ch == ~nc.sliderChannels[u]},

				{
					if (val.value > 120,
							{ button1state = 1},
							{ button1state = 0});

				~nc.button1[u][i].value = button1state;
				~nc.button1Value[u][i] = button1state;

				}
		);

		// ButtonSteuerung ueber Midi - Button 2: push
		if(button2 == num
			and: {ch == ~nc.sliderChannels[u]},

			{
				~nc.button2[u][i].value = val/127;
				~nc.button2Value[u][i] = val/127;
			}
		);

				// ButtonSteuerung ueber Midi - Button 2: push
		if(button3 == num
			and: {ch == ~nc.sliderChannels[u]},

			{
				~nc.button3[u][i].value = val/127;
				~nc.button3Value[u][i] = val/127;
			}
		);



	};
}
}, scrID: 490653604/*1572864*/);


/*MIDIFunc.cc( {| val, num, ch, srcID |

		postf("controller: % % % %\n", ch, num, val/127, srcID);
})*/

"NanoControl enabled".postln;
// Ende Controllerauswertung
