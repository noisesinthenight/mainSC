//
/*
~qn  = QuNeo.new("QUNEO")
~qn.post_(1)
~qn.padBus[0] //x,y,z
~qn.sliderBus[0] //y, z
~qn.padFunc
~qn.sliderFunc

~qn.padFunc[0] = {arg xyz; xyz.postln}
*/

(

//SLIDERS
var n = 3, len = 0.01, dur = 0.6, skew = 0.5;
	~qn  = QuNeo.new();


	4.do{arg i;
		i = i+6;
		~qn.sliderFunc[i] = {arg pos;
			[i, pos].postln;
			case
			{i == 0} { n = pos.linlin(0, 1, 1, 64) } //density
			{i == 1} { len = pos.linlin(0, 1, 0.001, 2) } //length
			{i == 2} { dur = pos.linlin(0, 1, 0.0001, 6); } //envDur
			{i == 3} { skew = pos; } //envSkew
			;
		}
	};


	//PADS
	4.do{arg i;
		~qn.padFunc[i] = {arg xyz;
			[i, xyz].postln;
			case
			{i >= 0 && i <= 3} {
				if (xyz[2] > 0) {
					~fx.addSynth(~fx.key[i]);
				} {
					~fx.freeSynth(~fx.key[i]);
				}
			};

		}
	};

	4.do{arg i;
		i = i+4;
		~qn.padFunc[i] = {arg xyz;
			[i, xyz].postln;
			case
			{i >= 0 && i <= 3} {
				if (xyz[2] > 0) {
					//grain[i] on
					~burst.(n, len, dur, skew);
				} {
					// grain[i] on;
				}
			};
		}
	};


)


/*

~qn.padXFunc[0]
~qn.padYFunc[0]
~qn.padZFunc[0] = {arg msg; msg.postln;  }




//------------------busses
~qn.padBus[0].get( {arg ...msg; msg.postln})
s.scope(22,~qn.sliderBus[0])
s.scope(48,~qn.padBus[0])

/*
~sensor = Sensor.new; ???????
averaging / smoothing
probability
grab values / samplerate
*/


//
~lp = LaunchPad.new(8, 8, 1)
~lp.post_(1)
~lp.funcDict[0] = {arg msg; msg.postln};

*/