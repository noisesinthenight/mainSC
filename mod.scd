//mod

chaotic/sonification algorithms (generate buffer data)
static+dynamic wavetables
quantiser/downsample/sample and hold


SynthDef(\mod, {arg inBus,  fmBus, outBus, bufnum, freq = 0.3, fMod = 0, feed = 1, amp = 1;
	var inSig, rSig;
	inSig = In.ar(0);
	// RecordBuf.ar(inSig, bufnum, 0, rec, feed, rec);

	sig = VOsc.ar(0, freq)


	//sah here
	Out.ar(outBus, sig);
}).add

// ~modBuf = Buffer.alloc(s,

//use envelopes instead ?????