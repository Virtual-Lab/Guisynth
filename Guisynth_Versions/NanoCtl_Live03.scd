(
MIDIClient.init;
MIDIClient.destinations;

MIDIIn.connectAll;
//MIDIIn.connect("nanoKONTROL", "SLIDER/KNOB");
//MIDIIn.connect("nanoKONTROL2", "CTRL");
//~m1 = MIDIOut(4);
~m1 = MIDIOut.newByName("nanoKONTROL", "CTRL");
//~m1.control(10, 33, 100);

~m2 = MIDIOut.newByName("nanoKONTROL2", "CTRL");
//~m2 = MIDIOut(3);
//~m2.control(0, 48, 0);
// -------------------------------------------------------------------------
// Controller Midi und Controller GUI - Zugeschnitten auf Korg Nanocontrol 1
// -------------------------------------------------------------------------
~nc2 = ();

// Arrays der  und Knobs
// Midiprogrammnumbers der Sliders
~nc2.sliderNumbers = [1, 2, 3, 4, 5, 6, 7, 8];
~nc2.knobNumbers = [33, 34, 35, 36, 37, 38, 39, 40];

// Midichannel der Sliders, Anzahl der Sliders und Channels
~nc2.sliderChannels = [0];
~nc2.sliderRows = ~nc2.sliderChannels.size;
~nc2.sliderColums = ~nc2.sliderNumbers.size;

~nc2.button1Numbers = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 100.rand);
~nc2.button1Numbers[0] = [48, 49, 50, 51, 52, 53, 54, 55];

~nc2.button2Numbers = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 100.rand);
~nc2.button2Numbers[0] = [64, 65, 66, 67, 68, 69, 70, 71];

~nc2.button3Numbers = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 100.rand);
~nc2.button3Numbers[0] = [72, 73, 74, 75, 76, 77, 78, 79];


// Array der controlbusses und -Values
~nc2.slider = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });
~nc2.knob = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });
~nc2.button1 = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });
~nc2.button2 = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });
~nc2.button3 = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });

~nc2.relative = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], { Bus.control() });

~nc2.sliderValue = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);
~nc2.knobValue = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);
~nc2.button1Value = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);
~nc2.button2Value = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);
~nc2.button3Value = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);

~nc2.knobMax = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);
~nc2.knobMin = Array.fill([~nc2.sliderRows, ~nc2.sliderColums], 0);

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

	~nc2.sliderRows.do{ |u|

		~nc2.sliderColums.do {|i|

			var slider = ~nc2.sliderNumbers[i];
			var knob = ~nc2.knobNumbers[i];
			var button1 = ~nc2.button1Numbers[u][i];
			var button1state = 0;
			var	button2state = 0;
			var	button3state = 0;
			var button2 = ~nc2.button2Numbers[u][i];
			var button3 = ~nc2.button3Numbers[u][i];

			// Slidersteuerung ueber die MIDI
			if(slider == num
				and: {ch == ~nc2.sliderChannels[u]}
				and: {(val - (~nc2.sliderValue[u][i]*127)).abs < 15},

				{
					~nc2.slider[u][i].value = (val/127);
					//postf("Slider: % % % %\n", ch, num, val/127, (val - (~nc2.sliderValue[u][i]*127)).abs);
					~nc2.sliderValue[u][i] = (val/127);
					~mixer[\vol][i][\volControl].value(val/127)}, {
					if (~nc2.button1Value[0][i] == 1, {
						~mixer[\stream][i][\streamControl].value(val/127)
					});
				}
			);

			// Knobsteuerung ueber die MIDI
			if(knob == num
				and: {ch == ~nc2.sliderChannels[u]}
				and: {(val - (~nc2.knobValue[u][i]*127)).abs < 15},

				{
					//~nc2.knob[u][i].value = (val/127);
					// postf("Slider: % % % %\n", ch, num, val/127, (val - (~nc2.knobValue[u][i]*127)).abs);
					~nc2.knobValue[u][i] = (val/127);

					if (~nc2.button1Value[0][i] == 1, {~mixer[\reverb][i][\reverbControl].value(val/127)},
						{if (~nc2.button2Value[0][i] == 1, {~mixer[\delay][i][\delayControl].value(val/127)},
							{~mixer[\pan][i][\panControl].value(val/127)})}
					);


				}
			);

			// ButtonSteuerung ueber Midi - Button 1: on/off
			if(button1 == num
				and: {ch == ~nc2.sliderChannels[u]},

				{
					if (val.value > 120,
						{ button1state = 1},
						{ button1state = 0});

					~nc2.button1[u][i].value = button1state;
					~nc2.button1Value[u][i] = button1state;
					~m2.control(0, num,  val);

				}
			);

			// ButtonSteuerung ueber Midi - Button 2: push
			if(button2 == num
				and: {ch == ~nc2.sliderChannels[u]}, {

					if (val.value > 120,
						{ button2state = 1},
						{ button2state = 0});

					~nc2.button2[u][i].value = val/127;
					~nc2.button2Value[u][i] = val/127;
					~m2.control(0, num,  val);
				}
			);

			// ButtonSteuerung ueber Midi - Button 2: push
			if(button3 == num
				and: {ch == ~nc2.sliderChannels[u]},

				{
					if (val.value > 120,
						{ button3state = 1},
						{ button3state = 0});

					~nc2.button3[u][i].value = val/127;
					~nc2.button3Value[u][i] = val/127;
					~m2.control(0, num,  val);
				}
			);



		};

	};

	u = 0;
	i = 4;

	if(~nc2.knobNumbers[i] == num
		and: {(val - (~nc2.knobValue[u][i]*127)).abs < 15},
		{
			~granulator1[\panControl].value(val/127-0.5);
	});

	i = 5;

	if(~nc2.knobNumbers[i] == num
		and: {(val - (~nc2.knobValue[u][i]*127)).abs < 15},
		{
			~granulator2[\panControl].value(val/127-0.5);
	});

	i = 6;

	if(~nc2.knobNumbers[i] == num
		and: {(val - (~nc2.knobValue[u][i]*127)).abs < 15},
		{
			~glocke1[\xpanControl].value(val/127-0.5);
	});

	i = 7;

	if(~nc2.knobNumbers[i] == num
		and: {(val - (~nc2.knobValue[u][i]*127)).abs < 15},
		{
			~glocke2[\xpanControl].value(val/127-0.5);
	});

}, srcID: 490653604);

MIDIFunc.cc( {| val, num, ch |

	/*var slider = ~nc1.sliderNumbers[i];
	var knob = ~nc1.knobNumbers[i];
	var button1 = ~nc1.button1Numbers[u][i];
	var button2 = ~nc1.button2Numbers[u][i];
	var button3 = ~nc1.button3Numbers[u][i];*/

	// granluator1
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

				//~nc2.knob[u][i].value = (val/127);
				// postf("Slider: % % % %\n", ch, num, val/127, (val - (~nc2.knobValue[u][i]*127)).abs);
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

				name = case
				{ i == 0} { "On" }
				{ i == 1} { "Record" };

				param = val;
				defer {
					~granulator1[(name++"Control").asSymbol].value(val);
				};
				~m1.control(ch, num,  val);

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

				//~nc2.knob[u][i].value = (val/127);
				// postf("Slider: % % % %\n", ch, num, val/127, (val - (~nc2.knobValue[u][i]*127)).abs);
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

				name = case
				{ i == 0} { "On" }
				{ i == 1} { "record" };

				param = val;

				defer { ~granulator2[(name++"Control").asSymbol].value(param) };
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





}, srcID: 214394786);


/*~testController = MIDIFunc.cc( {| val, num, ch, srcID |

postf("controller: % % % %\n", ch, num, val/127, srcID);
});*/


//~testController.free;

"NanoControl enabled".postln;
// Ende Controllerauswertung

)
