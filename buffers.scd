(
var files  = [
	"/Users/dan/!MASTERS/BLOG/2015/June/samples/concretetiles.aif",
	"/Users/dan/!MASTERS/BLOG/2015/June/samples/creakytrain.aif",
	"/Users/dan/@SAMPLES/_SAMPLES/Percussive/!LOOPS/100bpm Metal + Glass perc4.aif",
	"/Users/dan/@SAMPLES/_SAMPLES/Percussive/!LOOPS/100bpm Stone + Wood perc2.aif"
];

var buf;

fork{
	~buf = Array.fill(files.size, {arg i;
		Buffer.readChannel(s, files[i], channels: 1);
	});
	s.sync;
	~buf.collect(_.normalize);
};

~buf;
)