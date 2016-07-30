//QUNEO class
//pad Notes: 36  to  51
//padXYZ: [24, 25, 23]  to [69,70, 68]
//slider Notes: 0  to  10
//sliderXZ [0, 12]  to  [10, 22]

QuNeo {
	var <midiUID, <midiOUT, <midiON, <midiOFF, <midiCC;
	var <padBus, <sliderBus, padXYZ;
	var <>padFunc, <>sliderFunc;  //noteON and noteOFF
	var <>padXFunc, <>padYFunc, <>padZFunc;
	var <>sliderXFunc, <>sliderZFunc;
	var <>post = 0;

	*new{arg midiPort = "QUNEO";
		MIDIClient.init;
		MIDIIn.connectAll;
		^super.new.init(midiPort);
		/*		padNotes = Array.fill(16, {arg i; i+36});
		padXYZ = Array.fill(16, {arg i; i = i*3; [i+24, i+25, i+23] });
		sliderNotes = Array.fill(11, {arg i; i });
		sliderXZ = Array.fill(11, {arg i; [i, i+12] }); */
	}

	init{arg midiPort;
		padBus = Array.fill(16, {  Bus.control(Server.default, 3)  });     //x, y, z
		sliderBus = Array.fill(11, { Bus.control(Server.default, 2) });   //y, z

		padFunc = Array.fill(16, nil);
		padXFunc = Array.fill(16, nil);
		padYFunc = Array.fill(16, nil);
		padZFunc = Array.fill(16, nil);

		sliderFunc = Array.fill(11, nil);
		sliderXFunc = Array.fill(11, nil);
		sliderZFunc = Array.fill(11, nil);

		midiUID = MIDIIn.findPort("QUNEO", "QUNEO").uid;
		// midiOUT = MIDIOUT.newByName(midiPort, midiPort);

		midiON = MIDIFunc.noteOn({arg ...msg;
			msg[0] = msg[0] / 127;
			case
			{(msg[1] >= 36) && (msg[1] <= 51)} {
				msg[1] = msg[1] - 36;
				if (padFunc[msg[1]].notNil) {
					padBus[msg[1]].get({arg xyz;
						padFunc[msg[1]].(xyz);
					});
				};
			}
			{(msg[1] >= 0) && (msg[1] <= 10)} {
				if (sliderFunc[msg[1]].notNil) {   sliderFunc[msg[1]].(msg[0]);   };
			};
			if (post > 0) { msg.postln };
		}, srcID: midiUID);

		midiOFF = MIDIFunc.noteOff({arg ...msg;
			msg[0] = msg[0] / 127;
			case
			{(msg[1] >= 36) && (msg[1] <= 51)} {
				msg[1] = msg[1] - 36;
				if (padFunc[msg[1]].notNil) {
					padBus[msg[1]].get({arg xyz;
						xyz[2] = 0;
						padFunc[msg[1]].(xyz);
					});
				};
			}
			{(msg[1] >= 0) && (msg[1] <= 10)} {
				if (sliderFunc[msg[1]].notNil) {   sliderFunc[msg[1]].(msg[0]);   };
			};
			if (post > 0) { msg.postln };
		}, srcID: midiUID);



		midiCC = MIDIFunc.cc({arg ...msg;
			msg[0] = msg[0]/127;

			case
			{(msg[1] >= 0) && (msg[1] <= 10)} {
				sliderBus[msg[1]].setAt(0, msg[0]);
				if (sliderXFunc[msg[1]].notNil) {  sliderXFunc[msg[1]].(msg[0]); };
			}    // position
			{(msg[1] >= 12) && (msg[1] <= 22)} {
				sliderBus[msg[1]-12].setAt(1, msg[0]);
				if (sliderZFunc[msg[1]].notNil) {  sliderZFunc[msg[1]].(msg[0]); };
			}  //  pressure

			{(msg[1] >= 23) && (msg[1] <= 70)} {
				var id = ((msg[1] - 23)/3).asInteger;
				var xyz = ((msg[1]-23)+2)%3;

				padBus[id].setAt(xyz, msg[0]);

				case
				{xyz == 0} {
					if (padXFunc[id].notNil) {  padXFunc[msg[1]].(msg[0]); };
				}
				{xyz == 1} {
					if (padYFunc[id].notNil) {  padXFunc[msg[1]].(msg[0]); };
				}
				{xyz == 2} {
					if (padZFunc[id].notNil) {  padXFunc[msg[1]].(msg[0]); };
				}
			}
			;
			if (post > 0) { msg.postln };
		}, srcID: midiUID);
	}


}