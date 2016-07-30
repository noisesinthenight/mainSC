//__________________________----------________--------_________-------________--------------------ANALYSIS--
{
	arg inbus, bufnum, replyID = -1, netAddr;
	var synth, onsets, onsetFunc, analysis, lastPos, aCount, aFunc, oFunc, methods;

	synth = {arg t_getPos, inBus, bufnum, rec = 1, feed = 0, thresh = 0.15, smooth = 0.25, replyID = -1;
		var inSig, ampSig, onset, count, fft, centroid, slope, noise, pos, isRec, rSig, pSig, p;
		inSig = InFeedback.ar(inBus);
		//COMPRESSOR ON INPUT!!!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

		ampSig = Amplitude.ar(inSig, 0.01, smooth);
		// ampSig = PeakFollower.ar(inSig, smooth);
		// ampSig = EnvDetect.ar(inSig, 100, smooth);
		// ampSig.poll;
		// onset = (Delay1.ar(ampSig) - ampSig).abs > thresh;
		onset = ampSig > thresh;`
		// onset.poll;

		p = Pitch.kr(inSig, 330, 60, 8000, ampThreshold: thresh);
		fft = FFT(LocalBuf(1024), inSig, 0.5, 0, 1, 0);
		centroid = SpecCentroid.kr(fft);
		// centroid = Lag.kr(centroid, 0.1);
		slope = FFTSlope.kr(fft) * 10000;  	// SpecFlatness
		noise =  FFTSpread(fft) * 0.000001;

		//recording (constant)
		pos = Phasor.ar(0, BufRateScale.ir(bufnum), 0, BufFrames.ir(bufnum));
		pSig = BufRd.ar(1, bufnum, pos, 1, 4);
		rSig = BufWr.ar((inSig + (pSig * feed)) * Lag.kr(rec, 0.1), bufnum, pos * rec, 1);



		// Out.kr(posOUT, pos);



		//output data
		count = Stepper.ar(onset, HPZ1.ar(pos), 0, 256, 1, 0);
		SendReply.ar(Changed.ar(onset, 0.1)  * rec , '/onset', [count, onset, pos, ampSig, p[0], centroid, slope], replyID);
		SendReply.ar(Impulse.ar(100)  * rec , '/analysis', [pos, ampSig, p[0], centroid, slope], replyID); //every 10 ms
		SendReply.ar(t_getPos, '/pos', pos, replyID);

	}.play(args: [
		\bufnum, bufnum,
		\replyID, replyID,
	]);


	//STORE ANALYSIS
	analysis = Dictionary.new;
	lastPos = 0;
	aCount = 0;

	aFunc = OSCFunc({arg msg;
		var pos = msg[3];
		if (pos < lastPos) {
			aCount = 0;  //restart counter when cross 0 in buffer
		} {
			aCount = aCount + 1;
		};
		lastPos = pos;
		//store data
		analysis[aCount] = msg[3..7];
		//send OSC    //args: replyID, amp>thresh, , pos, ampSig, pitch, centroid, slope
		if (netAddr.notNil) {  netAddr.sendMsg('/analysis', aCount, (pos/bufnum.numFrames).asFloat, msg[4], msg[5], msg[6], msg[7]) };
	}, '/analysis');


	//STORE ONSETS
	onsets = Dictionary.new;
	onsetFunc = Dictionary.new;

	oFunc = OSCFunc({arg msg;
		var id = msg[2], count = msg[3]-1;
		if (msg[4] == 1) {
			//eventSTART
			if (count == 0) { onsets[count] = Dictionary.new; };  //clear onset list
			onsets[count] = [msg[5.. 8], msg[5.. 8]];
		} {
			//eventEND
			onsets[count][msg[4]] = msg[5.. 8];
		};

		// external function   //args:  [count, on/off, pos, amp, pitch, centroid, slope]
			if (onsetFunc.isFunction) {
				onsetFunc.([onsets.size-1]++msg[3.. 8]);
			} {
				onsetFunc.do{arg func, i;
					if (func.isFunction) {  func.([onsets.size-1]++msg[3.. 8])  }
				};
		};

		//send OSC //args: replyID, amp>thresh, , pos, ampSig, pitch, centroid, slope
		if (netAddr.notNil) {
			netAddr.sendMsg('/onset', id, msg[4].asInteger, (msg[5]/bufnum.numFrames), msg[6], msg[7], msg[8], msg[9] )
		};
	}, '/onset');



	methods = (
		inbus: { arg self, bus;
			if (bus.isNil) {
				inbus  //get
			} {
				inbus = bus;  //set
				synth.set(\inBus, bus);
			}
		},
		synths: { synth },
		bufnum: { bufnum },
		analysis: { analysis },
		onsets: { onsets },
		onsetFunc: {onsetFunc},

		thresh: { arg self, thresh;     synth.set(\thresh, thresh)  },
		smooth: { arg self, smooth;     synth.set(\smooth, smooth)  },

		//FIND AVERAGES FOR ANALYSIS DATA ! ! ! ! ! <<<<<<<<<<<<<<<<<<<<<<<<<<< DO THIS
		// analysisAvg: {
		// 	var avg = Dictionary.new;
		// 	analysis.keysValuesDo{arg k, v;
		// 		avg[k] = ;
		// 	}
		// },
		index: { aCount }, //current index
		amp: { arg self, avg;
			var f = Array.newClear(analysis.size);
			analysis.size.do{arg i;
				f[i] = analysis[i];
			};
			f = f.flop;
			if (avg.isNil) {
				f[1]; //all amps
			} {
				avg = (avg * f.size).asInteger;
				f[1][0.. avg].sum / f[1][0.. avg].size; //avg
			}
		},

		pitch: { arg self, avg;
			var f = Array.newClear(analysis.size);
			analysis.size.do{arg i;
				f[i] = analysis[i];
			};
			f = f.flop;
			if (avg.isNil) {
				f[2]; //all
			} {

				avg = (avg * f.size).asInteger;
				f[2][0.. avg].sum / f[2][0.. avg].size; //avg
			}
		},

		freq: { arg self, avg;
			var f = Array.newClear(analysis.size);
			analysis.size.do{arg i;
				f[i] = analysis[i];
			};
			f = f.flop;
			if (avg.isNil) {
				f[3]; //all
			} {

				avg = (avg * f.size).asInteger;
				f[3][0.. avg].sum / f[3][0.. avg].size; //avg
			}
		},

		slope: { arg self, avg;
			var f = Array.newClear(analysis.size);
			analysis.size.do{arg i;
				f[i] = analysis[i];
			};
			f = f.flop;
			if (avg.isNil) {
				f[4]; //all
			} {

				avg = (avg * f.size).asInteger;
				f[4][0.. avg].sum / f[4][0.. avg].size; //avg
			}
		},


	);
}

// x = OSCFunc({arg msg; "hjhgh".postln}, '/onset', -1, 9001)   //HMMMMM