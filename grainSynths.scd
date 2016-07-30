//grainSynths

/*
SynthDef(\grain, {arg outBus, bufnum, start = 0, end = 1000, t_reset,   rate = 1,  rateEnv = 0, rateDuty = 1, amp = 1, envDur = 3, envSkew = 0.1,
posIN, posMod, rateIN, rateMod, freq = 660, res = 0.7, fMix = 0;
var env, pos, sig;
env = EnvGen.ar(Env.perc(envDur * envSkew, envDur * (1 - envSkew)), doneAction: 2);

rate = XLine.ar((rateEnv+1)*rate, rate, rateDuty*envDur);
rate = rate + ( (rate * InFeedback.ar(rateIN)) * rateMod);

pos = Phasor.ar(t_reset, BufRateScale.kr(bufnum) * rate, start, end, start);
pos = pos.wrap(0, BufFrames.kr(bufnum));
pos = pos + ((pos + (pos * InFeedback.ar(posIN))) * posMod);

sig = BufRd.ar(1, bufnum, pos, 1, 4);
freq = freq.clip(20, 18000);
res = 1 - res;
sig = SelectX.ar(fMix, [sig, BPF.ar(sig, freq, res, (res ** -1) * (400 / freq ** 0.5))]);
sig = sig * env;
Out.ar(outBus, sig * amp);
}).add;
*/

//modEnv, ampEnv
SynthDef(\grain, {arg outBus, bufnum, start, end,
	t_reset, posMod = 0, posTime = 1,
	rate = 1, rateMod = 0,	rateTime= 1,
	fMix = 0.5, freq = 660, res = 0.9, amp = 1,
	freqMod = 0, freqTime = 1,
	mAtt = 0.1, mRel = 0.5, dur = 0.01, skew = 1;
	var env, mEnv, rEnv, fEnv, pEnv, pos, sig;

	env = EnvGen.ar(Env.perc(dur*skew, dur*(1-skew)), doneAction: 2);
	mEnv  = Env.perc(mAtt, mRel);

	rEnv = EnvGen.ar(mEnv, levelScale: rateMod, timeScale: rateTime);
	fEnv = EnvGen.ar(mEnv, levelScale: freqMod, timeScale: freqTime);
	pEnv = EnvGen.ar(mEnv, levelScale: posMod, timeScale: posTime);

	rate = rate + (rate*rEnv);
	freq = (freq + (freq*fEnv)).clip(20, 18000);
	res = 1- res ;

	pos = Phasor.ar(t_reset, BufRateScale.kr(bufnum) * rate, start, end, start);
	pos = pos + (pos * pEnv);
	pos = pos.wrap(0, BufFrames.kr(bufnum));
	// pos = pos + ((pos + (pos * InFeedback.ar(posIN))) * posMod);

	sig = BufRd.ar(1, bufnum, pos, 1, 4);
	freq = freq.clip(20, 18000);

	sig = SelectX.ar(fMix, [
		sig,
		BPF.ar(sig, freq, res, (res ** -1) * (400 / freq ** 0.5))
	]);

	sig = sig * env;
	Out.ar(outBus, sig * amp);
}).add

//extMod
// SynthDef(\grainMod, {}).add
/*

(
fork{6.do{
	fork{ 18.do{
		var id = 3;
		var pos = rand(~buf[id].numFrames);
		// var pos = 0;
		x = Synth(\grainEnv, [
			\outBus, rand(2), \bufnum, ~buf[id],
			\start, pos, \end, pos + (rrand(0.006, 0.3)*s.sampleRate),
			\posMod, 0.01, \posTime, 0.9,
			\rate, gauss(0.02, 0.5), \rateMod, rrand(0.002, 0.02), \rateTime, 0.09,
			\fMix, 0.7, \freq, rrand(1200, 6600), \res, 0.99,
			\freqMod, rrand(-0.006, 0.01), \freqTime, rrand(0.1, 3),
			\mAtt, 1.9, \mRel, 0.1, \mExt, 0,
			\att, rrand(0.03, 2), \rel, rrand(0.03, 3), \amp, 1/6
		]);

		gauss(0.1, 0.01).wait;
	}};
	rrand(1,3).wait;
}}
)
*/