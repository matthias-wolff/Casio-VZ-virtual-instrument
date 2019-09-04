# vVZ-1
A virtual replica of the Casio VZ-1/VZ-10M/VZ-8M music synthesizer

### Project Outline
In this project I try to rebuild the vintage Casio VZ-1/VZ-10M/VZ-8M music synthesizer in [Reaktor 6](https://www.native-instruments.com/en/products/komplete/synths/reaktor-6). The primary goal is a fully functional player which is compatible with MIDI editor/librarian software like [Midi Quest](https://squest.com/Products/MidiQuest12/index.html) or the like. My workplan is
1. Make some debugging and development tools (waveform validator, envelope validator, etc.)
2. Reproduce the 8 core waveforms of VZ (1x sine, 5x sawtooth-like waveforms created by Casio's Phase Distortion Modulation, 1x white noise, 1x pitch-sensitive narrow-band noise---or 
   just a mix of white noise and a sine?)
3. Implement the core sound engine (wavetable oscillators, phase and ring modulators, DCAs, oscillator circuits)
4. Implement control signal generators (amplitude envelope, key following, layering, parametric sensitivity characterisitcs, etc.)
5. Implement MIDI SysEx control capability
6. Reproduce the factory voice and operation libraries

I always strongly disliked the unpleasant---though most characteristic---aliasing and analog noise of the VZ. Hence, I will not attempt to reproduce this. Insofar, the remake is not intended to be perfect.

As a secondary goal I may want to reproduce the GUI of the original instrument. This would be a nice-to-have, however not necessarily of much practical use.

### Collaborators Welcome!
As this is a mere hobby project, I cannot tell how far I will come with it. At any rate, progress is going to be slow.

If you are interested in collaborating, please let me know! It's much more fun to work together :)

Matthias Wolff<sup>&nbsp;[[0000-0002-3895-7313](https://orcid.org/0000-0002-3895-7313)]</sup><br>
Aug. 30, 2019

----------

### References
##### 1. Related Projects
* [VZone](https://www.youtube.com/watch?v=PaXGQDl-uco) - [NI Kontakt 6](https://www.native-instruments.com/en/products/komplete/samplers/kontakt-6/) instrument based on 24 sounds of the VZ-1
* [VirtualCZ](https://www.amazona.de/test-plugin-boutique-virtualcz-phase-distortion-synthesizer/) - virtual remake of the Casio CZ-1 (predecessor of the VZ-1)
* [Casio CZ for iOS](https://www.amazona.de/test-casio-cz-virtueller-phase-distortion-synth-ios/) - another virtual remake of the CZ-1 by Casio itself

##### 2. Information on the VZ-1/VZ-10M Synthesizers
* [Gregor Nitsche (sound-c-pro). CASIO VZ](http://www.soundc-pro.com/casio-vz/)
* [Green Box. Casio VZ-1, VZ-10M, VZ-8M, Hohner HS-2/E. AMAZONA.de, 2018](https://www.amazona.de/green-box-casio-vz-1-vz-10m-vz-8m-hohner-hs-2-e/)
* [Workshop. Casio CZ/VZ und die Grundlagen der Phase Distortion Synthesis. AMAZONA.de, 
  2008](https://www.amazona.de/workshop-casio-czvz-und-die-grundlagen-der-phase-distortion-synthesis/)
* [ProckGnosis. Casio VZ-10M - Exploring the Synth and Sounds. YouTube video, 2019](https://www.youtube.com/watch?v=YF16PshtaMs)

##### 3. Sound Examples
* [RetroSound. CASIO VZ-1 iPD Synthesizer "VeeZeeOne". YouTube video, 2015](https://www.youtube.com/watch?v=mWFKpTlMaYM)
* [RetroSound. CASIO VZ-1 iPD Synthesizer (1987). YouTube video, 2015](https://www.youtube.com/watch?v=LVG_FVgP7yU)

##### 4. Tutorials
* [ADSR Tutorials. Reaktor - Drawable Wavetable Oscillators. YouTube video, 2013](https://www.youtube.com/watch?v=TtkViDlVx-Y)
* [ADSR Tutorials. Working with Phase Modulation in Reaktor. YouTube video, 2013](https://www.youtube.com/watch?v=I1u2WKA9p3c)
* [ADSR Tutorials. Working with Stacked Macros In Reaktor. YouTube video, 2013](https://www.youtube.com/watch?v=DrrV_ce0cUE)