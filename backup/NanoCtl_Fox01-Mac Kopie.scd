(
MIDIClient.init;
MIDIClient.destinations;

MIDIIn.connectAll;
//MIDIIn.connect("nanoKONTROL", "SLIDER/KNOB");
//MIDIIn.connect("nanoKONTROL2", "CTRL");
//~m1 = MIDIOut(4);
~m1 = MIDIOut.newByName("nanoKONTROL", "CTRL");
//~m1.control(10, 33, 100);

~m2 = MIDIOut.newByName("Faderfox PC44", "Faderfox PC44");
//~m2 = MIDIOut(3);
//~m2.control(0, 48, 0);
// -------------------------------------------------------------------------
// Controller Midi und Controller GUI - Zugeschnitten auf Korg Nanocontrol 1
// -------------------------------------------------------------------------
~ffx = ();

// Arrays der  und Knobs
// Midiprogrammnumbers der Sliders
~ffx.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];

// Midichannel der Sliders, Anzahl der Sliders und Channels
~ffx.sliderChannels = [0];
~ffx.sliderRows = 8;
~ffx.sliderColums = ~ffx.sliderNumbers.size;

~ffx.button1Numbers = [71, 72, 73, 74, 75, 76, 77, 78];

// Array der controlbusses und -Values
~ffx.slider = Array.fill([~ffx.sliderRows, ~ffx.sliderColums], { Bus.control() });
~ffx.button1 = Array.fill(~ffx.sliderColums, { Bus.control() });

~ffx.sliderValue = Array.fill([~ffx.sliderRows, ~ffx.sliderColums], 0);
~ffx.button1Value = Array.fill(~ffx.sliderColums, 0);


~nc1 = ();

// Midiprogrammnumbers der Sliders
~nc1.sliderNumbers = [2, 3, 4, 5, 6, 8, 9, 12, 13];
~nc1.knobNumbers = [14, 15, 16, 17, 18, 19, 20, 21, 22];

// Midichannel der Sliders, Anzahl der Sliders und Channels
~nc1.sliderChannels = [10, 11, 12, 13];
~nc1.sliderRows = ~nc1.sliderChannels.size;
~nc1.sliderColums = ~nc1.sliderNumbers.size;

~nc1.button1Numbers = Array.fill(~nc1.sliderColums, 100.rand);
~nc1.button1Numbers = [23, 24, 25, 26, 27, 28, 29, 30, 31];

~nc1.button2Numbers = Array.fill(~nc1.sliderColums, 100.rand);
~nc1.button2Numbers = [33, 34, 35, 36, 37, 38, 39, 40, 41];

~nc1.button3Numbers = Array.fill(3, 100.rand);
~nc1.button3Numbers = [45,44,46];


// Array der controlbusses und -Values
~nc1.slider = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });
~nc1.knob = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });
~nc1.button1 = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });
~nc1.button2 = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });
~nc1.button3 = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });

~nc1.relative = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], { Bus.control() });

~nc1.sliderValue = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);
~nc1.knobValue = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);
~nc1.button1Value = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);
~nc1.button2Value = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);
~nc1.button3Value = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);

~nc1.knobMax = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);
~nc1.knobMin = Array.fill([~nc1.sliderRows, ~nc1.sliderColums], 0);

// -------------------------------------------------------------------------
//                         Steuerung ueber die MIDI
// -------------------------------------------------------------------------

//MIDIIn.connectAll;

MIDIFunc.cc( {| val, num, ch |

	//postf("controller: % % % \n", ch, num, val/127);

	8.do {|i|

		var slider = ~ffx.sliderNumbers[i];
		var button1 = ~ffx.button1Numbers[i];
		var button1state = 0;

		// Slidersteuerung ueber die MIDI
		if(ch == 0, {

			if (num == slider, { ~mixer[\pan][i][\panControl].value(val/127);
				~instruments[i-4][\panControl].value((val/127*2)-1) });
			if (num == (slider+8), { ~mixer[\reverb][i][\reverbControl].value(val/127) });
			if (num == (slider+16), { ~mixer[\delay][i][\delayControl].value(val/127) });
			if (num == (slider+24), { ~mixer[\distort][i][\distortControl].value(val/127) });
			if (num == (slider+32), { ~mixer[\cloud][i][\cloudControl].value(val/127);
				~instruments[i-4][\cloudControl].value(val/127) });
			if (num == (slider+40), { ~mixer[\stream][i][\streamControl].value(val/127) });
			if (num == (slider+48), { ~mixer[\vol1][i][\vol1Control].value(val/127) });
			if (num == (slider+56), { ~mixer[\vol2][i][\vol2Control].value(val/127) });

			// ButtonSteuerung ueber Midi - Button 1: on/off
			/*if(button1 == num
			{
			if (val.value > 120,
			{ button1state = 1},
			{ button1state = 0});

			~ffx.button1[i].value = button1state;
			~ffx.button1Value[i] = button1state;
			~m2.control(0, num,  val);

			}
			);*/

		});

	};

	u = 0;

	[3, 4, 5, 6, 7, 8].do {|i|

		//var knob, min, max, param;

		if(~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.sliderValue[u][i]*127)).abs < 15},

			{
				var name, slider, min, max, param;

				name = case
				{ i == 3} { "dens" }
				{ i == 4} { "pos" }
				{ i == 5} { "dur" }
				{ i == 6} { "pitch" }
				{ i == 7} { "pan" }
				{ i == 8} { "vol" };

				min = ~granulator1[(name++"Spec").asSymbol].map(val/127);
				max = min+(~granulator1[(name++"Val").asSymbol][1]-~granulator1[(name++"Val").asSymbol][0]);

				~granulator1[(name++"Control").asSymbol].value([min, max]);

			}
		);
	};

	[3, 4, 5, 6, 7, 8].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, min, max;

				//~ffx.knob[u][i].value = (val/127);
				// postf("Slider: % % % %\n", ch, num, val/127, (val - (~ffx.knobValue[u][i]*127)).abs);
				//~nc1.knobValue[u][i] = (val/127);

				name = case
				{ i == 3} { "dens" }
				{ i == 4} { "pos" }
				{ i == 5} { "dur" }
				{ i == 6} { "pitch" }
				{ i == 7} { "pan" }
				{ i == 8} { "vol" };

				min = ~granulator1[(name++"Val").asSymbol][0];
				max = min + ~granulator1[(name++"Spec").asSymbol].map(val/127);

				~granulator1[(name++"Control").asSymbol].value([min, max]);


			}
		);



	};

	[2].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "delay" }
				{ i == 1} { "reverb" }
				{ i == 2} { "puls" };

				param = ~granulator1[(name++"Spec").asSymbol].map(val/127);



				~granulator1[(name++"Control").asSymbol].value(param);

			}
		);



	};

	[0, 1].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "reverb" }
				{ i == 1} { "delay" };

				param = ~granulator1[(name++"Spec").asSymbol].map(val/127);



				~granulator1[(name++"Control").asSymbol].value(param);

			}
		);
	};

	[0, 1].do {|i|
		// ButtonSteuerung ueber Midi - Button 1: on/off
		if(~nc1.button1Numbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},

			{
				var name, param;

				~nc1.button1Value[u][i] = (~nc1.button1Value[u][i]+2)%1;

				param = ~nc1.button1Value[u][i];

				if(i == 0, {
					defer {
						~granulator1[\onControl].value(param);
					};
					}, {
					~granulator1[\recordGui].valueAction_(param)
				});

				~m1.control(ch, num,  param * 127);
				postf("Steuerung, button value: %", param);

			}
		)
	};


	// granluator2

	u = 1;

	[3, 4, 5, 6, 7, 8].do {|i|

		//var knob, min, max, param;

		if(~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.sliderValue[u][i]*127)).abs < 15},

			{
				var name, slider, min, max, param;

				name = case
				{ i == 3} { "dens" }
				{ i == 4} { "pos" }
				{ i == 5} { "dur" }
				{ i == 6} { "pitch" }
				{ i == 7} { "pan" }
				{ i == 8} { "vol" };

				min = ~granulator2[(name++"Spec").asSymbol].map(val/127);
				max = min+(~granulator2[(name++"Val").asSymbol][1]-~granulator2[(name++"Val").asSymbol][0]);

				~granulator2[(name++"Control").asSymbol].value([min, max]);

			}
		);
	};

	[3, 4, 5, 6, 7, 8].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, min, max;

				//~ffx.knob[u][i].value = (val/127);
				// postf("Slider: % % % %\n", ch, num, val/127, (val - (~ffx.knobValue[u][i]*127)).abs);
				//~nc1.knobValue[u][i] = (val/127);

				name = case
				{ i == 3} { "dens" }
				{ i == 4} { "pos" }
				{ i == 5} { "dur" }
				{ i == 6} { "pitch" }
				{ i == 7} { "pan" }
				{ i == 8} { "vol" };

				min = ~granulator2[(name++"Val").asSymbol][0];
				max = min + ~granulator2[(name++"Spec").asSymbol].map(val/127);

				~granulator2[(name++"Control").asSymbol].value([min, max]);


			}
		);



	};

	[0, 1, 2].do {|i|


		// Slidersteuerung ueber die MIDI
		if( ~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "release" }
				{ i == 1} { "attac" }
				{ i == 2} { "hanning" };

				param = ~granulator2[(name++"Spec").asSymbol].map(val/127);



				~granulator2[(name++"Control").asSymbol].value(param);

			}
		);



	};

	[0, 1].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "reverb" }
				{ i == 1} { "delay" };

				param = ~granulator2[(name++"Spec").asSymbol].map(val/127);



				~granulator2[(name++"Control").asSymbol].value(param);

			}
		);



	};

	[0, 1].do {|i|
		// ButtonSteuerung ueber Midi - Button 1: on/off
		if(~nc1.button1Numbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},

			{
				var name, param;

				~nc1.button1Value[u][i] = (~nc1.button1Value[u][i]+1)%1;

				param = ~nc1.button1Value[u][i];

				name = case
				{ i == 0} { "On" }
				{ i == 1} { "record" };

				defer {
						~granulator2[(name++"Control").asSymbol].value(val);
				};

				~m1.control(ch, num,  val);

			}
		)
	};

	// glocke1

	u = 2;

	[0, 1, 2, 3, 4, 5, 6, 7].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "volume" }
				{ i == 1} { "freq" }
				{ i == 2} { "xpan" }
				{ i == 3} { "attack" }
				{ i == 4} { "decay" }
				{ i == 5} { "sustain" }
				{ i == 6} { "release" }
				{ i == 7} { "cloud" };

				param = ~glocke1[(name++"Spec").asSymbol].map(val/127);

				~glocke1[(name++"Control").asSymbol].value(param);

			}
		);

	};

	/*[1, 2, 3, 4].do {|i|


	// Slidersteuerung ueber die MIDI
	if( ~nc1.sliderNumbers[i] == num
	and: {ch == ~nc1.sliderChannels[u]},
	// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

	{
	var name, param;

	name = case
	{ i == 0} { "curve" }
	{ i == 1} { "reverb" }
	{ i == 2} { "delay" }
	{ i == 2} { "distort" };

	param = ~glocke1[(name++"Spec").asSymbol].map(val/127);



	~glocke1[(name++"Control").asSymbol].value(param);

	}
	);

	};*/

	[0, 1].do {|i|
		// ButtonSteuerung ueber Midi - Button 1: on/off
		if(~nc1.button1Numbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},

			{
				var name, param;

				if (~nc1.button1Value[u][i] == 1,
					{ param = 0 }, { param = 1});

				name = case
				{ i == 0} { defer { ~glocke1[\OnControl].value(param) } }
				{ i == 1} { defer { ~glocke1[\triggerControl].value(param) } };

				//param = val;

				~m1.control(ch, num,  param*127);

				~nc1.button1[u][i].value = param;
				~nc1.button1Value[u][i] = param;
			}
		)
	};

	// Glockensynth 2

	u = 3;

	[0, 1, 2, 3].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "attack" }
				{ i == 1} { "decay" }
				{ i == 2} { "sustain" }
				{ i == 3} { "release" };


				param = ~glocke2[(name++"Spec").asSymbol].map(val/127);

				~glocke2[(name++"Control").asSymbol].value(param);

			}
		);

	};

	[0, 1].do {|i|


		// Slidersteuerung ueber die MIDI
		if( ~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, param;

				name = case
				{ i == 0} { "reverb" }
				{ i == 1} { "delay" };

				param = ~glocke2[(name++"Spec").asSymbol].map(val/127);



				~glocke2[(name++"Control").asSymbol].value(param);

			}
		);

	};

	[4, 5, 6, 7, 8].do {|i|

		//var knob, min, max, param;

		if(~nc1.sliderNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.sliderValue[u][i]*127)).abs < 15},

			{
				var name, slider, min, max, param;

				name = case
				{ i == 4} { "dens" }
				{ i == 5} { "hold" }
				{ i == 6} { "xpan" }
				{ i == 7} { "freq" }
				{ i == 8} { "volume" };

				min = ~glocke2[(name++"Spec").asSymbol].map(val/127);
				max = min+(~glocke2[(name++"Val").asSymbol][1]-~glocke2[(name++"Val").asSymbol][0]);

				~glocke2[(name++"Control").asSymbol].value([min, max]);

			}
		);
	};

	[4, 5, 6, 7, 8].do {|i|


		// Knobsteuerung ueber die MIDI
		if( ~nc1.knobNumbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},
			// and: {(val - (~nc1.knobValue[u][i]*127)).abs < 15},

			{
				var name, min, max;

				name = case
				{ i == 4} { "dens" }
				{ i == 5} { "hold" }
				{ i == 6} { "xpan" }
				{ i == 7} { "freq" }
				{ i == 8} { "volume" };

				min = ~glocke2[(name++"Val").asSymbol][0];
				max = min + ~glocke2[(name++"Spec").asSymbol].map(val/127);

				~glocke2[(name++"Control").asSymbol].value([min, max]);


			}
		);



	};

	[0, 1].do {|i|
		// ButtonSteuerung ueber Midi - Button 1: on/off
		if(~nc1.button1Numbers[i] == num
			and: {ch == ~nc1.sliderChannels[u]},

			{
				var name, param;

				if (~nc1.button1Value[u][i] == 1,
					{ param = 0 }, { param = 1});

				name = case
				{ i == 0} { defer { ~glocke2[\OnControl].value(param) } }
				{ i == 1} { defer { ~glocke2[\triggerControl].value(param) } };

				//param = val;

				~m1.control(ch, num,  param*127);

				~nc1.button1[u][i].value = param;
				~nc1.button1Value[u][i] = param;
			}
		)
	};





}, /*scrID: 1572864*/);


/*MIDIFunc.cc( {| val, num, ch, srcID |

postf("controller: % % % %\n", ch, num, val/127, srcID);
});*/

"NanoControl enabled".postln;
// Ende Controllerauswertung

)
