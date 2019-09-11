fn = '../labels/recordings/phaseModulationAnalysis/M1=SINE, M2=SINE, 46.875 Hz, ENV DEPTH=29.timit';
lab = vVZtools.readTimit(fn,'GON'); disp(lab);
lab = vVZtools.readTimit(fn); disp(lab);