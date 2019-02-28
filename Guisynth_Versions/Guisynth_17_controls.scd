
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

		object[(name[0]++"Val").asSymbol] = val;

		//object[(name[0]++"Bus").asSymbol].set(val);
		//object[(name[0]++"CBus").asSymbol] = ();

		/*if(~cloud == true, {
		~cs.clients.do { |i|
		object[(name[0]++"CBus").asSymbol][i].set(val);
		}
		});;*/

		if (object[(name[0]++"Val").asSymbol] == 1, {
			object.[(mode++name[0]).asSymbol].value;
		}, {
			object.[(mode++name[1]).asSymbol].value;
		});

		postf("Play %: Status %\n", mode, object[(name[0]++"Val").asSymbol]);

		postf("Value: %\n", val);

	};

	/*object[(name++"DrawGui").asSymbol] = Task {

	loop {

	object[(name++"Bus").asSymbol].get({ |val|

	object[(name++"Val").asSymbol] = val;



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
	*/
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

	object[(name++"CBus").asSymbol] = ();


	~cs.clients.do { |i|
		object[(name++"CBus").asSymbol][i] = Bus.control(~cs[\server][i], 1).value = currentVal;
	};


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


		~cs.clients.do { |i|
			object[(name++"CBus").asSymbol][i].set(val);
		};


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

	object[(name++"CBus").asSymbol] = ();


	~cs.clients.do { |i|
		object[(name++"CBus").asSymbol][i] = Bus.control(~cs[\server][i], 2).set(preMin, preMax);
	}


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


		~cs.clients.do { |i|
			object[(name++"CBus").asSymbol][i].set(val[0], val[1]);
		};

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

	object[(name++"CBus").asSymbol] = ();


	~cs.clients.do { |i|
		object[(name++"CBus").asSymbol][i] = Bus.control(~cs[\server][i], 1).value = currentVal;
	};


	if (gui != False, {

		object[(name++"Spec").asSymbol] = ControlSpec(min, max, \lin, step: 0, default: 1);

		//"here".postln;

		object[(name++"Gui").asSymbol] = EZKnob(object.window, 50@90, name, object[(name++"Spec").asSymbol],
			{ |val| object[(name++"Control").asSymbol].value(val.value)}, currentVal);
	});

	object[(name++"Control").asSymbol] = { |val|

		object[(name++"Bus").asSymbol].set(val);


		~cs.clients.do { |i|
			object[(name++"CBus").asSymbol][i].set(val);
		};


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

	newObject[(name++"CBus").asSymbol] = ();


	~cs.clients.do { |i|
		newObject[(name++"CBus").asSymbol][i] = Bus.control(~cs[\server][i], 1).value = currentVal;
	};

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


		~cs.clients.do { |i|
			newObject[(name++"CBus").asSymbol][i].set(val);
		};


		//postf("Parameter: %, Value: %\n", name, val.value);

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
