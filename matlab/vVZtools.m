classdef vVZtools
  % Library of static methods.

  %properties(Constant)
  %end

  %% == Pitch <-> Frequency Converters ====================================
  methods(Static)

    function p = f2p(f)
      % Converts note frequency to pitch based on the concert pitch A4=440 Hz.
      %
      %   p = f2p(f)
      %
      % arguments:
      %   f - Note frequency in Hz
      %
      % returns:
      %   p - Pitch, the integer part is a MIDI note number
      %
      % See also p2f

      p = 69+12*log(f/440)/log(2);
    end

    function [OCT,NOTE,FINE] = f2vzp(f)
      % Converts note frequency to a VZ fix pitch setting (Menu 1-02, PITCH FIX=ON). 
      %
      %   [OCT,NOTE,FINE] = f2vzp(f)
      %
      % arguments:
      %   f    - Tone frequency in Hz
      %
      % returns:
      %   OCT  - Value for OCT parameter in Menu 1-02
      %   NOTE - Value for NOTE parameter in Menu 1-02
      %   FINE - Value for FINE parameter in Menu 1-02
      %
      % Description:
      %   The method assumes that VZ's  master tune is set to 440 Hz (Menu 3-00, TUNE(A4)=440.0).
      % 
      % Calibration measurement:
      %   - VZ master tune set to A4=440 Hz
      %   - One SINE oscillator (M1)
      %   - Blue Cat's FreqAnalyst Pro
      %
      %   OCT = 0..10 (N=11), NOTE=0..11 (N=12), FINE=0..63 (N=64)
      %
      %   OCT= 4, NOTE=0, FINE=0 -> f=  186 Hz (F#3+ 9ct) -> p= 54.0936
      %   OCT= 5, NOTE=0, FINE=0 -> f=  372 Hz (F#4+10ct) -> p= 66.0936
      %   OCT= 6, NOTE=0, FINE=0 -> f=  745 Hz (F#5+11ct) -> p= 78.1168
      %   OCT= 7, NOTE=0, FINE=0 -> f= 1490 Hz (F#6+ 8ct) -> p= 90.1168
      %   OCT= 8, NOTE=0, FINE=0 -> f= 2976 Hz (F#7+11ct) -> p=102.0936
      %   OCT= 9, NOTE=0, FINE=0 -> f= 5963 Hz (F#8+ 9ct) -> p=114.1256
      %   OCT=10, NOTE=0, FINE=0 -> f=11904 Hz (F#9+ 9ct) -> p=126.0936  
      %                                           ^---^         ^----^
      %                                                 average -> 10.0257 ct
      %   -> OCT = 0 -> (F#-1+10.0257ct) -> p=6.10257
      %   -> OCT = (f2p(f)-6.10257)/12

      Nn   = 12;                                                           % # note steps, NOTE=0..11
      Nf   = 64;                                                           % # fine steps, FINE=0..63
      o    = round((vVZtools.f2p(f)-6.10257)/12*Nn*Nf);                    % OCT value in  NOTE x FINE ticks
      OCT  = floor(o/(Nn*Nf));                                             % OCT value -> return
      n    = o - OCT*Nn*Nf;                                                % NOTE values in FINE ticks
      NOTE = floor(n/Nf);                                                  % NOTE value -> return
      FINE = n-NOTE*Nf;                                                    % FINE value -> return
    end

    function f = p2f(p)
      % Converts pitch to note frequency based on the concert pitch A4=440 Hz.
      %
      %   f = p2f(p)
      %
      % arguments:
      %   p - Pitch or MIDI note number
      %
      % returns:
      %   f - Note frequency in Hz
      %
      % See also f2p

      f = pow2((p-69)/12)*440;
    end

  end
end

% EOF