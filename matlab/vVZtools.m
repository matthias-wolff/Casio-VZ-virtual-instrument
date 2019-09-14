classdef vVZtools
  % Library of static methods.

  %properties(Constant)
  %end

  %% == Pitch <-> Frequency Converters =========================================
  methods(Static)

    function p = f2p(f)
      % Converts note frequency to pitch based on the concert pitch A4=440 Hz.
      %
      %   p = vVZtools.f2p(f)
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
      %   [OCT,NOTE,FINE] = vVZtools.f2vzp(f)
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
      %   f = vVZtools.p2f(p)
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

  %% == Phase Modulation =======================================================
  methods(Static)
  
    function x1 = pmInvert(y,x2,C)
      % Inverts the phase modulation y(k) = x2(k + K*x1(k)).
      %
      %   x1 = vVZtools.pmInverse(y,x2)
      %   x1 = vVZtools.pmInverse(y,x2,C)
      %
      % arguments:
      %   y  - The phase-modulated signal, a vector of samples representing
      %        exactly one cycle of a periodic signal. The value range is [-1,1].
      %   x2 - The carrier signal being modulated, a vector of samples 
      %        representing exactly one cycle of a periodic signal. The value 
      %        range is [-1,1]. The lengths of y and x2 must be identical.
      %   C  - Number of phase unwrapping cycles, default is C=2.
      %
      % returns:
      %   x1 - The modulating signal. As the solution is, in general, not unique, 
      %        the method returns an array with two rows. The first row contains
      %        the sample index and the second row contains the signal value.
      %        Sample indexes may occur multiply, however in ascending order.
      
      % Pre-checks                                                              % -------------------------------------
      if nargin<2; error('Too few arguments' ); end                             % Less than 2 arguments -> error
      if nargin>3; error('Too many arguments'); end                             % More than 2 arguments -> error
      if nargin==2; C=2; end                                                    % Default value for C
      if ~isvector(y) || ~isnumeric(y)                                          % y not a numeric vector >>
        error('Argument y must be a numeric vector');                           %   Error
      end                                                                       % <<
      if ~isvector(x2) || ~isnumeric(x2)                                        % x2 not a numeric vector >>
        error('Argument x2 must be a numeric vector');                          %   Error
      end                                                                       % <<
      K = length(y);                                                            % Signal length in samples
      if K==0;          error('Signal y must not be empty'                ); end% y empty -> error
      if length(x2)~=K; error('Signals y and x2 must have the same length'); end% Different lengths -> error

      % Main                                                                    % -------------------------------------
      x2p = circshift(x2,1);                                                    % x2(k-1); predecessors of x(k), cyclic
      x1  = zeros(2,2*K*C);                                                     % Allocate output array
      x1p = 1;                                                                  % Write pointer in output array
      for k=0:K-1                                                               % Loop over samples of y >>
        yk = y(k+1);                                                            %   Get sample y(k)
        m1 = (yk>x2p).*(yk<=x2);                                                %   y(k)>x(k-1) AND y(k)<=x(k)
        m2 = (yk<x2p).*(yk>=x2);                                                %   y(k)<x(k-1) AND y(k)>=x(k)
        m  = m1+m2;                                                             %   y(k) between x(k-1) and x(k)
        %plot(0:K-1,m1,0:K-1,m2,0:K-1,m);                                       %   DEBUG: plot
        nn = find(m)-1;                                                         %   Find matching points in x2
        for i=1:length(nn)                                                      %   Loop over matches >>
          n    = nn(i);                                                         %     Sample index in x2
          x2pn = x2(mod(n-1,K)+1);                                              %     x2(n-1), cyclic
          x2n  = x2(n+1);                                                       %     x2(n)
          ykn  = n-1 + (yk-x2pn)/(x2n-x2pn);                                    %     Linear interpolation
          if ykn<0; ykn = ykn+K; end                                            %     Phase wrap
          %fprintf('y(%d)=%g, x2(%d)=%g, x2(%d)=%g -> n=%g\n',...               %     DEBUG: printout
          %  k,yk,n-1,x2pn,n,x2n,ykn);                                          %     ...
          for c=-C:C                                                            %     Phase unwrapping loop >>
            x1(1,x1p) = k;                                                      %       Write to output
            x1(2,x1p) = (ykn-k)/K + c;                                          %       Write to output
            x1p       = x1p+1;                                                  %       Increment output pointer
          end                                                                   %     <<
        end                                                                     %   <<
      end                                                                       % <<
      x1 = x1(:,1:x1p-1);                                                       % Truncate output
    end
    
  end

  %% == Labeling ===============================================================
  methods(Static)
    
    function lab = readTimit(fnTimit,filter)
      % Reads a TIMIT label file.
      %
      %   lab = vVZtools.readTIMIT(fnTimit,filter)
      %
      % arguments:
      %   fnTimit - Name of TIMIT label file
      %   filter  - Label name to filter for (optional, default is no filtering)
      %
      % returns:
      %   lab     - The labels as a table containing the following variables:
      %             - k_S : zero-based sample index of label beginning
      %             - k_E : zero-based sample index of label end
      %             - name: label name
      
      fid = fopen(fnTimit,'r');
      l = textscan(fid,'%d %d %s');
      fclose(fid);
      k_S = l{1};
      k_E = l{2};
      name = l{3};
      lab = table(k_S,k_E,name);
      
      if nargin==2
        i = 1;
        while i<=height(lab)
          if strcmp(filter,lab.name{i})
            i = i+1;
          else
            lab(i,:)=[];
          end
        end
      end
    end
    
    function lab = pitchMark(wave,k,K)
      % Crude pitch marker.
      %
      %   lab = vVZtools.pitchMark(x,k,K)
      %
      % arguments:
      %   x   - The signal to label, a vector of samples.
      %   k   - Zero-based index of an initial pitchmark.
      %   K   - Approximate cycle length in samples.
      %
      % returns:
      %   lab - The pitch marks in the TIMIT label format.
      %
      % See also readTimit
      
      n = 0.05*K;
      [kz,rising] = vVZtools.findZeroCrossing(wave,k,n);
      while kz>0
        % TODO: ...
      end
    end
    
  end
  
  methods(Static,Access=protected)
    
    function [kz,rising] = findZeroCrossing(wave,k,n)
      kz = -1;
      rising = false;
      for i=0:n

        % Look i samples left of k
        try
          if wave(k-i)>=0 && wave(k-i+1)<=0
            kz = k-i;
            rising = false;
            break;
          elseif wave(k-i)<=0 && wave(k-i+1)>=0
            kz = k-i;
            rising = true;
            break;
          end
        catch
          % Ignore
        end
        
        % Look i samples right of k
        try
          if wave(k+i)>=0 && wave(k+i+1)<=0
            kz = k+i;
            rising = false;
            break;
          elseif wave(k+i)<=0 && wave(k+i+1)>=0
            kz = k+i;
            rising = true;
            break;
          end
        catch
          % Ignore
        end
      end
    end
    
  end
    
end
% EOF