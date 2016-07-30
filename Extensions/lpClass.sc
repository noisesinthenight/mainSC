//launchpad CLASS
//use xSize and ySize to create arrays???

//mapping sections

LaunchPad {
	// classvar <>mode;
	var <mode, <modeSize;
	var <midiUID, <midiOUT, <midiON, <midiOFF, <midiCC;
	var <ledState, <ledColor, <ledStateCC, <ledColorCC;
	var <>funcDict, <>funcDictCC;
	var <>post = 0;

	*new { arg xSize, ySize, zSize = 3, midiPort = "Launchpad Mini";
		MIDIClient.init;
		MIDIIn.connectAll;
		^super.new.init(xSize, ySize, zSize, midiPort);
	}

	init { arg xSize, ySize, zSize, midiPort;
		mode = 0;
		modeSize = zSize;
		//create dictionaries
		ledColor = Array.fill(modeSize, {Array.fill(127, { arg i; [0, 120]} )} );
		ledColorCC = Array.fill(modeSize, {Array.fill(127, { arg i; [0, 120]} )} );
		ledState = Array.fill(modeSize, {Array.fill(127, {0} )} );
		ledStateCC = Array.fill(modeSize, {Array.fill(8, {0} )} );
		funcDict = Array.fill(modeSize, { Dictionary.new() });
		funcDictCC = Array.fill(modeSize, { Dictionary.new() });

		//x y cordinates ???
/*		funcDict = Array.fill(modeSize, {
			Array.fill(xSize, { Array.newClear(ySize) });
		});*/


		//create midi mappings
		midiUID = MIDIIn.findPort("Launchpad Mini", "Launchpad Mini").uid;
		midiOUT = MIDIOut.newByName(midiPort, midiPort);

		midiON = MIDIFunc.noteOn({
			arg ...msg;
			if (funcDict[mode][msg[1]].notNil) {
				funcDict[mode][msg[1]].value(msg[1], msg[0]/127);
			};
			if (post > 0) { msg.postln };
		}, srcID: 	midiUID	);
		midiOFF = MIDIFunc.noteOff({
			arg ...msg;
			if (funcDict[mode][msg[1]].notNil) {
				funcDict[mode][msg[1]].value(msg[1], msg[0]/127);
			};
			if (post > 0) { msg.postln };
		}, srcID: 	midiUID	);
		midiCC = MIDIFunc.cc({
			arg ...msg;
			//set mode
			if ((msg[1] >= 104) && (msg[1] <= (104+(modeSize-1))) && (msg[0] > 0)) {
				this.setMode(msg[1] -104);
			} {
				//recall functions for top row
				if (funcDictCC.notNil) {
					funcDictCC[mode][msg[1]].value(msg[1], msg[0]/127);
				};
			};
			if (post > 0) { msg.postln };
		}, srcID: 	midiUID	);


		this.setMode(mode);


	}



	setFunc { arg index, func, mode_;
		//use current mode if not specified in args
		if (mode_.isNil) {mode_ = mode};
		//free old function
		if (funcDict[mode_][index].notNil) {
			funcDict[mode_][index].free
		};
		//add new function
		funcDict[mode_][index] = func;
	}

	setFuncCC { arg index, func, mode_;
		//use current mode if not specified in args
		if (mode_.isNil) {mode_ = mode};
		//free old function
		if (funcDictCC[mode_][index].notNil) {
			funcDictCC[mode_][index].free
		};
		//add new function
		funcDictCC[mode_][index] = func;
	}

	setMode { arg index;
		mode = index.wrap(0, modeSize-1);
		//clear all leds
		127.do{ arg i; midiOUT.noteOff(0, i, 0)}; //matrix + side
		8.do{ arg i; midiOUT.control(0, i+104, 0)}; //top row
		//refresh mode led
		midiOUT.control(0, mode+104, 10);
		//recall leds for selected mode
		ledState[mode].do{ arg val, i;
			midiOUT.noteOn(0, i, ledColor[mode][i][val]);
		};
	}

	setColor { arg index, onVal, offVal, mode_;
		if (mode_.isNil) {mode_ = mode};
		if (offVal.notNil) {
			ledColor[mode_][index][0] = offVal;
		} {
			ledColor[mode_][index][0] = 0;
		};
		ledColor[mode_][index][1] = onVal;
	}

	setColorCC { arg index, onVal, offVal, mode_;
		if (mode_.isNil) {mode_ = mode};
		if (offVal.notNil) {
			ledColorCC[mode_][index][0] = offVal;
		} {
			ledColorCC[mode_][index][0] = 0;
		};
		ledColorCC[mode_][index][1] = onVal;
	}

	setState { arg index, val, mode_;
		if (mode_.isNil) {mode_ = mode};
		if (val.notNil) {
			//set state
			val = val.clip(0, 1);
			ledState[mode_][index] = val;
			if (mode_ == mode) { midiOUT.noteOn(0, index, ledColor[mode_][index][val]) };
		} {
			//invert state
			ledState[mode_][index] = (1 - ledState[mode_][index]).clip(0, 1);
			if (mode_ == mode) { midiOUT.noteOn(0, index, ledColor[mode_][index][ledState[mode_][index]]) };
		}
	}

	setStateCC { arg index, val, mode_;
		var nIndex = index - 104;
		if (mode_.isNil) {mode_ = mode};
		if (val.notNil) {
			//set state
			ledStateCC[mode_][nIndex] = val;
			midiOUT.control(0, index, val * 100);
		} {
			//invert state
			ledStateCC[mode_][nIndex] = (1 - ledStateCC[mode_][nIndex]).clip(0, 1);
			midiOUT.control(0, index, ledStateCC[mode_][nIndex]*100);
		}
	}

	setLed { arg index, val;
		midiOUT.noteOn(0, index, val);
	}

	getState { arg index, mode_;
		if (mode_.isNil) {mode_ = mode};
		^ledState[mode_][index];
	}

	getStateCC { arg index, mode_;
		if (mode_.isNil) {mode_ = mode};
		^ledStateCC[mode_][index];
	}

	clearLeds {
		ledState[mode]  = Array.fill(127, 0); //clear states
		127.do{arg i; midiOUT.noteOff(0, i, 0)}; //matrix + side
		8.do{arg i; midiOUT.control(0, i+104, 0)}; // top
		//current mode led
		midiOUT.control(0, mode+104, 10);
	}

	//reset mode
	//
}



/*
s.boot
~lp = LaunchPad.new(0,0, 3, "Launchpad Mini")
~lp.setMode(1)

~lp.setColor(0, 100)
~lp.setState(0)
~lp.setState(0, 1)
~lp.setCC(108, 1) //for top row!

//set led directly
~lp.setLed(0, 10)
~lp.clearLeds


//set single function
~lp.setFunc(0, {"test".postln})
//set single function for mode 1
~lp.setFunc(0, {"test".postln}, 1)

//set all / multiple functions
(
127.do{ arg i;
	~lp.setFunc(i, {
		arg pitch, vel;
		i.postln;
~lp.setState(i, vel/127);
	});
}
)

//set functions for top row (cc104 - cc111)
~lp.setFuncCC(108, { arg p, v; [p,v].postln; ~lp.setStateCC(p, v) })
~lp.setStateCC(108)


//getState
~lp.ledColor[0][0] // [mode][index]
~lp.ledState[0][0] // [mode][index]
//get Function
~lp.funcDict[0][0] // [mode][index]
~lp.funcDictCC[0][0] // [mode][index]
//get current mode
~lp.mode
//get mode maximum
~lp.modeSize
*/
