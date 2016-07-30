//--------------------------------------------------------------------MAIN-
(
Server.default.options.memSize = 1048576;
Server.default.waitForBoot{

	if (~sendOSC.isNil) { ~sendOSC = NetAddr("127.0.0.1", 9001) };

	//put these busses inside ext files?
	if (~inBus.isNil) { ~inBus = Bus.audio(s, 1); };
	if (~fxBus.isNil) { ~fxBus = Bus.audio(s, 1); };
	if (~mBus.isNil) { ~mBus = Bus.audio(s, 1); };

	~inG = Group.new;
	~fxG = Group.after(~inG);
	~mG = Group.after(~fxG);

	~in = {arg amp = 1; Out.ar(~inBus, SoundIn.ar(0) * amp);}.play(~inG);

	if (~buf.isNil) { (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "buffers.scd").loadPaths[0]; };
	(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "grainSynths.scd").loadPaths[0];
	~grain = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "grain.scd").loadPaths[0];
	~grain = ~grain.(~inG);

	(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "fxSynths.scd").loadPaths[0];
	~fx = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "fx.scd").loadPaths[0];
	~fx = ~fx.(~inBus, ~fxBus, ~fxG, [\distort, \ring, \chorus, \filter]);

	// ~mod = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "mod.scd").loadPaths[0];
	// ~mod.(~inG);


	if (~inBuf.isNil) { ~inBuf = Buffer.alloc(s, 1*s.sampleRate) };
	~an = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "analysis.scd").loadPaths[0];
	~an = ~an.(~fxBus, ~inBuf, 0, ~sendOSC);


	// ~verb = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "verb.scd").loadPaths[0];
	~out = {arg inBus, pan = 0, amp = 1; Out.ar(0, Pan2.ar(In.ar(inBus), pan, amp)) }.play(~mG, args: [\inBus, ~fxBus]);
}


)



//-----------------------------------------------------------------mapping-

(PathName(thisProcess.nowExecutingPath).pathOnly +/+ "map.scd").loadPaths[0];


//---------------------------------------------------------------------gui-

// (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "gui.scd").loadPaths[0];

//-------------------------------------------------------------------------




~in.set(\amp, 10)
~grain.outbus = ~inBus.index
~grain.args.putPairs([\bufnum, ~buf[3], \start, 0, \end, 1*s.sampleRate])
~grain.args.putPairs([\bufnum, ~inBuf, \start, 0, \end, 1*s.sampleRate])
(
var i = ~an.onsets.size.rand - 1; ~grain.args.putPairs([\bufnum, ~inBuf, \start, ~an.onsets[i][1][0], \end, ~an.onsets[i][0][0]]) ;
~grain.burst(1, 0.0, 1, 0.5) //density, inter grain time, dur, skew
)
//FROM CURRENT POSITION ???


~grain.args.putPairs([\fMix, 0.6, \freq, {rrand(33, 660)}, \res, 0.89])
~grain.burst(16, 0.01, {rrand(0.01, 1.3)}, 0.5) //density, inter grain time, dur, skew
~grain.args[\rate] = {rrand(0.5, 12)}
~grain.argsDev[\rate] = 0.02
~grain.prob = 1
~grain.grainFunc =


~fx.key;
~fx.args;
~fx.inbus;
~fx.outbus;
~fx.addSynth(\distort)
~fx.freeSynth(\distort)
// fork{ inf.do{ rrand(1, 3).wait; ~fx.synths[0].set(\tone, [0.3, 0.6, 0.75, 0.25].choose, \dist, 0.6) }}
z = fork{ inf.do{ rrand(1, 3).wait; ~fx.setArgs([\tone, [0.3, 0.6, 0.75, 0.25].choose, \dist, 2], \distort) }}
z.stop
~fx.addSynth(\ring)
~fx.freeSynth(\ring)
// p = fork{ inf.do{ rrand(0.6, 2).wait;~fx.synths[1].set(\freq, [0.2, 0.3, 6, 3, 1, 9, 12, 120, 1200, 1600, 1800].choose) }}
p = fork{ inf.do{ rrand(0.6, 2).wait;~fx.setArgs([\freq, [0.2, 0.3, 6, 3, 1, 9, 12, 120, 1200, 1600, 1800].choose], \ring) }}

~fx.setArgs([\dist, 0.6, \tone, 0.9], \distort)
~fx.synths[0].get(\dist, {arg v; v.postln})

~fx.synths
~fx.synths.size
~fx.mix(0.5)
//TODO
// macro knobs     (XY ???)
//ADD dry wet mixer at end!!

~an.inbus(~inBus)
~an.inbus(~fxBus)
~an.inbus(~mBus)
~inBuf.play

~an.synths.set(\thresh, 0.1)
~an.onsets.size
~an.onsetFunc
~an.onsetFunc[0] = {arg msg; msg.postln}
~an.onsetFunc = {arg msg;
	msg.postln;
	// ~grain.burst(12, 0.01, 0.6, 0.5) //density, inter grain time, dur, skew
}


~an.analysis[~an.index] //last value
// ~an.amp[0] //access amplitude values
~an.amp(1) //get average amp   var = (percentage of data to use)   //USE NUMBERS AROUND CENTER POINT  (USE ~an.index!!!!)  ?? //gaussian??
~an.pitch(1)
~an.freq(1)
~an.slope(1)
//CALCULATE amount of deviation, how steady are the values? standard dev
//TRY different sampling speeds for SendReply, sync to buffer recording?
//USE BUFFERS instead of Dictionaries  (probably FASTER ??)






//ADD REVERB
~out.set(\pan, 0, \amp, 0)