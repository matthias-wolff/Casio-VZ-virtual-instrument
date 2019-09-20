# VZ-1 Recordings
This folders contains various recordings from my VZ-1.

### 1 Sampled Wavetable
vVZ features wavetable oscillators loaded with waveforms recorded from an
original VZ-1 device. To obtain the samples, I recorded a single oscillator 
signal. Each cycle of the sampled waveforms contains exactly 1024 samples.

#### 1.1 Calibration Measurement
I tried to avoid resampling of the recordings. So I figured out how to setup
VZ-1 to produce signals with a "natural" cycle length of 1024 samples. To that 
end, I performed the following calibration measurement:

1. Set the master tune in `Menu 3-00` to `TUNE(A4)=440.0`(Hz)
2. Initialize a new voice `Menu 1-00`...`Menu 1-18`: [Copy/Initialize]+[YES]
3. Deactivate all modules except `M1`
4. Set `M1` to fix pitch: `Menu 1-02`, `PITCH FIX=ON`
5. Vary waveform (`Menu 1-01`, `FORM=xxx`) and fix pitch (`Menu 1-02`, `OCT=nn`, 
   `NOTE=nn`, `FINE=nn`)
6. Record the oscillator signal at a sampling frequency of 48 kHz
7. Manually label the zero-crossings of two subsequent falling edges and
   compute the difference &rarr; cycle length <i>K</i> in samples

The recorded files are stored in folder `<vVZ>/waves/recordings/PITCH FIX measurement`. 
The following table summarizes the settings and measured cycle lengths:

FORM|OCT | NOTE | FINE|    K
----|----|------|-----|-----
SINE| 02 |   00 |   08| 1026
SAW1| 02 |   00 |   08| 1025
SAW2| 02 |   00 |   08| 1025
SAW3| 02 |   00 |   08| 1026
SAW4| 02 |   00 |   08| 1026
SAW5| 02 |   00 |   08| 1025
SINE| 02 |   00 |   09| 1024
SAW1| 02 |   00 |   09| 1025
SAW2| 02 |   00 |   09| 1024
SAW3| 02 |   00 |   09| 1024
SAW4| 02 |   00 |   09| 1025
SAW5| 02 |   00 |   09| 1025
SINE| 02 |   00 |   10| 1023
SAW1| 02 |   00 |   10| 1023
SAW2| 02 |   00 |   10| 1024
SAW3| 02 |   00 |   10| 1022
SAW4| 02 |   00 |   10| 1025
SAW5| 02 |   00 |   10| 1024
SAW5| 02 |   00 |   11| 1023

**Result:** When recorded at 48 kHz, one waveform cycle of the VZ-1 is 1024 
samples long if

1. the master tune is set to 440.0 Hz (`Menu 3-00`, `TUNE(A4)=440.0`) and
2. a fix pitch of `OCT=02`, `NOTE=00`, and `FINE=9` is set in `Menu 1-02`.

#### 1.2 Recording and Cutting the Waveforms
I recorded the VZ-1 oscillator waveforms with the settings described in the
section above. The wave files are stored in folder `<vVZ>/waves/recordings/wavetable`. 
I manually labeled the zero-crossing of a falling edge (approx. 5 cycles into 
the wave) in each recording and an cut out 1024 samples starting from there 
using the Matlab script `<vVZ>/matlab/WaveformCutter.mlx`.

The positions <i>k</i><sub>0</sub> (in samples) of the labeled zero-crossings 
are:

file      | <i>k</i><sub>0</sub>
----------|---------------------
SINE.wav  | 11211
SAW1.wav  | 14036
SAW2.wav  | 12222
SAW3.wav  | 12336
SAW4.wav  | 18400
SAW5.wav  | 13068
NOISE1.wav| 33521
NOISE2.wav| 31777

The cut waveforms are placed in folder `<vVZ>/waves/wavetable/sampled` by
`WaveformCutter.mlx`.

**TODO:** 
1. The procedure does not work for the `NOISEn` waveforms. Improve!

--------------------------------------------------------------------------------
<span style="font-size:6pt">
Sep. 6, 2019<br>
Matthias Wolff
</span>