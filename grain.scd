// grain
 {
	arg group, key  = [\grain];
	var outbus, dur, skew, args, argsDev;
	var prob = 1, synths, methods;
	outbus = Bus.audio(s, 1);

	args = Dictionary.newFrom([\dur, 1, \skew, 0.5, \amp, 1]);
	argsDev = Dictionary.newFrom([\dur, 0, \skew, 0, \amp, 0]);

	methods = (
		outbus: { outbus },
		synths: { synths },
		start: {},
		stop: {},

		args: { args },
		argsDev: { argsDev },

		prob: { prob },

		burst: {arg self, n = 3, spread = 0.1, dur_, skew_;
			var key_, args_, outbus_;
			if (dur_.notNil) { args[\dur] = dur_ };
			if (skew_.notNil) { args[\skew] = skew_ };
			// waitTime =  ((args[\dur]/n) * spread).clip(0.001, 8);


			if (synths.notNil) { synths.collect(_.release); }; //remove old synths
			synths = Array.newClear(n);

			//SEND OSC
			if (~sendOSC.notNil) {  ~sendOSC.sendMsg('/grainStart', 0, n.asInteger) };

			fork{ n.do{arg i;
				if (rand(1.0) < self.prob) {

					args_ = Dictionary.new;
					args.keysValuesDo{arg k, v;
						//add deviation
						if (argsDev[k].notNil) {
							if (args[k].isFunction) {
								args_[k] = gauss(args[k].value, argsDev[k]);
							} {
								args_[k] = gauss(args[k], argsDev[k]);
							}
						} {
							args_[k] = args[k];
						}
						//iteration as modsource
						// ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
					};


					// args_ = args.deepCopy;
					if (outbus.isArray) { args[\outBus] = self.outbus.choose } { args[\outBus] = self.outbus };
					if (key.isArray) { key_ = key.choose } { key_ = key };
					Synth(key_, args.asKeyValuePairs, group);

					group.postln;
					// extFunc //sendOSC
					// if (~sendOSC.notNil) {  ~sendOSC.sendMsg('/grain', replyID.asInteger, i, rate[i].asFloat, amp[i].asFloat, durM[i].asFloat, duty[i].asFloat, skew.asFloat) };

					i.postln;

				};

				// (spread/n).clip(0.0001, 8).wait;
				spread.clip(0.0001, 8).wait;
			}};
		},

	);
};

/*
~g = Group.new
~b = ~burst.(~g, [\grain])
{Out.ar(0, InFeedback.ar(~b.outbus))}.play
~b.args.putPairs([\bufnum, ~buf[0], \start, 0, \end, 1*s.sampleRate, \rate, 1])
~b.argsDev[\rate] = 2
~b.argsDev[\dur] = 0
~b.burst(12, 0.01, 1, 0.9) //density, inter grain time, dur, skew
~b.args[\rate] = {rrand(0.5, 0.1)}

~b.prob = 0.9


//TODO !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !  !
PBind
ControlSpec
iterative modulation      //see grainGen.scd
s.sendMsg()  instead of   Synth()




(
var n = 12, dens = 3;
fork{ n.do{ arg o;
	var oMod = (o+1)/n;
	// var rate = rrand(0.1, 1.5);
	var rate = Scale.minor.ratios.choose * [0.1, 0.5, 1, 2, 5,6,7].choose;

	y = 0 ! dens;
	x = dens.do{ arg i;
		var start = rrand(0.25, 0.75).postln, len = 0.1;
		// var dur = gauss(0.06, 0.05).abs, skew = 0.001;
		var dur = gauss(6, 0.1).abs.postln, skew = 0.5;
		// var id = rand(~buf.size) * 0.65;
		var id = 2;
		y[i] = Synth(\grain, [
			\bufnum, ~buf[id], \start, start*~buf[id].numFrames, \end, (start*~buf[id].numFrames)+(len*s.sampleRate),
			// \bufnum, ~inBuf, \start, start*~inBuf.numFrames, \end, (start*~inBuf.numFrames)+(len*s.sampleRate),
			// \rate, 2 * oMod +1, \rateEnv, 0, \rateDuty, 0.3,
			// \rate, rrand(0.25, 120) , \rateEnv, rand(12) * rand(2), \rateDuty, 0.3,
			\rate, gauss(rate, 0.001), \rateEnv, rand(0.001), \rateDuty, rrand(0.005, 1.5),
			\fMix, 0.6, \freq, rrand(300, 1800), \res, 0.998,
			\envDur, dur, \envSkew, skew,
			\outBus, rand(1)+2, \amp, (1/dens)  * 0.25
		]);
	};

	rrand(0.75, 3).wait;
	// rrand(0.1, 2).wait;
}}
)
y.collect(_.free)

s.makeGui
*/