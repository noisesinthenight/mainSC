//_____________________________________________________  __  __  _  _ _  FX  _ _  _  __  __   _________________________________
//ADD dry wet mixer at end!!
// select position to add in chain!!!!,
// macro knobs     (XY ???)
// ~macro = {arg id = 0;
//find fx key
//get arg key (parameter name)
//get ranges/mappings
//set
// }
// ControlSpec(0, 1000, 'exp', 1)



{
	arg inbus_, outbus_, group, keys = [\distort, \crush, \filter, \chorus, \ring];
	var inbus, outbus, args,  synths, storedKeys, storedArgs, methods;
	if (inbus_.isNil) { inbus = Bus.audio(s, 1) } { outbus = outbus_ };
	if (outbus_.isNil) { outbus = Bus.audio(s, 1) } { inbus = inbus_ };


	/*---*/
	args = Dictionary.newFrom([
		\distort, Dictionary.newFrom([\dist, 1, \tone, 0.3, \shape, 0, \feed, 0]),
		\crush, Dictionary.newFrom([\dist, 0.1, \tone, 0.5]),
		\filter, Dictionary.newFrom([\freq, 880, \type, 0, \res, 0.3]),
		\chorus, Dictionary.newFrom([\time, 0.1, \feed, 0.5, \freq, 10, \depth, 1]),
		\ring, Dictionary.newFrom([\freq, 10, \type, 0])
	]);

	synths = Dictionary.new;
	storedKeys = Dictionary.new;
	storedArgs = Dictionary.new;

	// mixSynth = {arg mix = 1; ReplaceOut.ar(outbus, SelectX.ar(mix, [In.ar(inbus), In.ar(outbus)]) )}.play;

	methods = (
		key: { keys },
		args: { args },
		inbus: { inbus },
		outbus: { outbus },
		synths: { synths },

		addSynth: {arg self, key_, id;
			//default next slot
			if (id.isNil) { id = synths.size };
			if (synths[id].notNil) { synths[id].release };

			if (id == 0) {
				//first synth
				synths[id] = Synth(key_, args[key_].asKeyValuePairs++[\inBus, inbus, \outBus, outbus], group, 'addToTail');
				// synths[id] = Synth(key_, args[key_].asKeyValuePairs++[\inBus, inbus, \outBus, outbus], group, 'addBefore: mixSynth');
			} {
				//replace synth
				synths[id] = Synth(key_, args[key_].asKeyValuePairs++[\inBus, outbus, \outBus, outbus], group, 'addToTail');
				// synths[id] = Synth(key_, args[key_].asKeyValuePairs++[\inBus, outbus, \outBus, outbus], group, 'addBefore: mixSynth');
			};
			("addFX: "++key_++" "++id).postln;
		},

		freeSynth: {arg self, id;
			//default last added
			if (id.isNil) { id = synths.size - 1};
			if (id.isNumber) {
				//remove using id number
				synths[id].release;
				synths.removeAt(id);
				("freeFX: "++" "++id).postln;

			} {
				//remove using key
				synths.keysValuesDo{arg k, v;
					if (v.defName.asSymbol == id) {
						v.release;
						synths.removeAt(k);
						("freeFX: "++id++" "++k).postln;
					}
				}
			}
		},

		setArgs: {arg self, args_, id;
			if (id.isNil) { id = synths.size -1  };
			if (id.isNumber) {
				//set using id number
				args_.keysValuesDo{arg k, v;
					synths[id].set(k, v);
				}
			} {
				// set using key
				synths.keysValuesDo{arg k, v;
					if (v.defName.asSymbol == id) {
						args_.keysValuesDo{arg kk, vv;
							v.set(kk, vv);
						}
					}
				}
			}
		},


		parallel: {arg self, on = 0;
			synths.size.do{arg i;
				if ((on == 1) || (i == 0)) {
					//parallel mode
					synths[i].set(\inBus, inbus, \outBus, outbus);
				} {
					//serial mode
					synths[i].set(\inBus, outbus, \outBus, outbus);
				}
			}
		},


		store: {arg self, id = 0;
			storedKeys[id] = Array.fill(synths.size, {arg i; synths[i].defName.asSymbol});
			storedArgs[id] = Dictionary.new;
			synths.size.do{arg i;
				storedArgs[id][i] = args[synths[i].defName.asSymbol];
			};
		},
		recall: {arg self, id = 0;
			synths.collect(_.release);
			args = storedArgs[id].deepCopy;
			storedKeys[id].size.do{arg i;
				self.add.(storedKeys[id][i], i);
			};
		},
	);

}
