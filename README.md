# vVZ-1
A virtual replica of the Casio VZ-1/VZ-10M music synthesizer

### Project Outline
In this project I try to rebuild the vintage Casio VZ-1/VZ-10M music synthesizer in [Reaktor 6](https://www.native-instruments.com/en/products/komplete/synths/reaktor-6). The primary goal is a fully functional player which is compatible with MIDI editor/librarian software like [Midi Quest](https://squest.com/Products/MidiQuest12/index.html) or the like. My workplan is
1. Make some debugging and development tools (sound validator, envelope validator, etc.)
2. Reproduce the 8 core waveforms of VZ-1/VZ-10M (1x sine, 5x sawtooth-like waveforms created by Casio's Phase Distortion Modulation, 1x white noise, 1x pitch-sensitive narrow-band noise)
3. Implement the core sound engine (wavetable oscillators, phase and ring modulators, VCAs, oscillator circuits)
4. Implement control signal generators (amplitude envelope, key following, layering, parametric sensitivity characterisitcs, etc.)
5. Implement MIDI SysEx control capability
6. Reproduce the factory voice and operation libraries

As a secondary goal I may want to reproduce the GUI of the original instrumenent which would be nice to have, but not necessarily of much practical use.

### Collaborators Welcome!
As this is a mere hobby project, I cannot tell how far I will come with it. At any rate, progress is going to be slow.

If you are interested in collaborating, please let me know! It's much more fun to work together :)

Matthias Wolff
Aug. 30, 2019

### References
##### 1. Related Projects
* [VZone](https://www.youtube.com/watch?v=PaXGQDl-uco) - NI Kontakt instrument based on 24 sounds of the VZ-1
* [VirtualCZ](https://www.amazona.de/test-plugin-boutique-virtualcz-phase-distortion-synthesizer/) - Virtual remake of the Casio CZ-1 (predecessor of the VZ-1)

##### 2. Information on the VZ-1/VZ-10M Synthesizers
* [Green Box: Casio VZ-1, VZ-10M, VZ-8M, Hohner HS-2/E](https://www.amazona.de/green-box-casio-vz-1-vz-10m-vz-8m-hohner-hs-2-e/)
