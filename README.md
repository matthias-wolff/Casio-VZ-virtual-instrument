# vVZ-1
A virtual replica of the Casio VZ-1/VZ-10M music synthesizer

### Project Outline
In this project I try to rebuild the vintage Casio VZ-1/VZ-10M music synthesizer in Native Instrument's Reaktor 6. The primary goal is a fully functional player which is compatible with MIDI editor/librarian software like Midiquest or the like. My workplan is
1. Make some debugging and development tools (sound validator, envelope validator, etc.)
2. Reproduce the 8 core waveforms of VZ-1/VZ-10M (1x sine, 5x sawtooth-like waveforms created by Casio's Phase Distortion Modulation, 1x white noise, 1x narrow-band noise)
3. Implement the core sound engine (wavetable oscillators, phase and ring modulators, VCAs, oscillator circuits)
4. Implement control signal generators (amplitude envelope generator, key following, layering, parametric sensitivity characterisitcs, etc.)
5. Implement MIDI SysEx control capability
6. Reproduce the factory voice and operations libraries

As a secondary goal I may want to reproduce the GUI of the original instrumenent which would be nice to have, but not necessarily of much practical use.

As this is a mere hobby project, progress is probably going to be slow.

### Collabarators Welcome!
If you are interested in collaborating, please let me know!

Matthias Wolff
Aug. 30, 2019
