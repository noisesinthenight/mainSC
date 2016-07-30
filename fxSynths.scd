//FX SynthDefs

SynthDef(\distort, {arg inBus, outBus, gate = 1, att = 0.1, rel = 0.1, dist = 0, tone = 0, shape = 0, feed = 0, amp = 1;
	var env, inSig, dSig;
	env = EnvGen.ar(Env.asr(att, 1, rel), gate, doneAction: 2);
	inSig = In.ar(inBus) + (Delay1.ar(LocalIn.ar(1) * feed));
	// inSig = (inSig * dist).tanh;
	dist = dist + 1;

	// inSig = SineShaper.ar(inSig, shape) * ((1-shape)+1);
	// inSig = (inSig * dist).tanh;

	dSig = RHPF.ar(inSig, 20, 0.3);
	dSig = (inSig * dist).softclip;

	dSig = ((dSig+inSig) * (dist*10)).clip;
	// inSig = (inSig * (dist*100)).distort;
	dSig = LowShelf.ar(dSig, 185, 1, -48*tone);
	dSig = HighShelf.ar(dSig, 6000, 1, -48*(1-tone));

	dist = dist * 5;
	dSig = (dSig * dist).tanh;

	ReplaceOut.ar(outBus, (dSig * env) * amp);
	LocalOut.ar(inSig);
}).add;

SynthDef(\crush, {arg inBus, outBus, gate = 1, att = 0.1, rel = 0.1, dist = 0, shape = 0, amp = 1;
	var env, inSig;
	env  = EnvGen.ar(Env.asr(att, 1, rel), gate, doneAction: 2);
	inSig = In.ar(inBus);
	inSig = Decimator.ar(inSig, s.sampleRate * ((dist*10)+1).reciprocal, 16);
	ReplaceOut.ar(outBus, (inSig * env) * amp);
}).add;


SynthDef(\filter, {arg inBus, outBus, gate = 1, att =0.1, rel = 0.1, freq = 1200, res = 0.3, type = 0, amp = 1;
	var env, inSig, fSig;
	env  = EnvGen.ar(Env.asr(att, 1, rel), gate, doneAction: 2);
	inSig = In.ar(inBus);
	res = 1 - res;
	fSig = SelectX.ar(type*3, [
		RLPF.ar(inSig, freq, res),
		// BPF.ar(inSig, freq, res),
		BPF.ar(inSig, freq, res, 1/res.sqrt),
		RHPF.ar(inSig, freq, res)
	]);
	ReplaceOut.ar(outBus, (fSig * env) * amp);
}).add;


// chorus / short delays / karplus
SynthDef(\chorus, {arg inBus, outBus, gate = 1, att = 0.1, rel = 0.1, time = 0.1, feed = 0.6, freq = 0.01, depth = 0, mix = 0.5, amp  = 1;
	var env, inSig, modSig, fSig, dSig;
	env  = EnvGen.ar(Env.asr(att, 1, rel), gate, doneAction: 2);
	inSig = In.ar(inBus);
	modSig = SinOsc.ar(freq);
	fSig = LocalIn.ar(1);
	dSig = DelayC.ar(inSig + (fSig * feed), 2, time + ((time*modSig) * depth));
	inSig = SelectX.ar(mix, [inSig, inSig*dSig]);
	ReplaceOut.ar(outBus, (inSig * env) * amp);
	LocalOut.ar(dSig);
}).add;

// ringmodulation / freqshifting
SynthDef(\ring, {arg inBus, outBus, gate = 1, att = 0.1, rel =0.1, freq = 10, shape = 0, type = 0, depth  = 1,  amp = 1;
	var env, inSig, modSig, fSig, rSig;
	env  = EnvGen.ar(Env.asr(att, 1, rel), gate, doneAction: 2);
	inSig = In.ar(inBus);

	fSig  = inSig.ring4(FreqShift.ar(inSig, freq, mul: 2) * depth);
	modSig = SinOsc.ar(freq).abs; //replace with saw >< square      even <> odd
	rSig = inSig.ring1(modSig*depth);
	inSig = SelectX.ar(type, [rSig, fSig]);

	ReplaceOut.ar(outBus, (inSig * env) * amp);
}).add;