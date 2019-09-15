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
      %   x1 = vVZtools.pmInvert(y,x2)
      %   x1 = vVZtools.pmInvert(y,x2,C)
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

  %% == Recording files ========================================================
  methods(Static)

    function fn = getWaveFn(rid)
      % Obtains the wave file name for a vVZ recording ID.
      %
      %    fn = vVZtools.getWaveFn(rid)
      %
      % arguments:
      %   rid - The recording ID, e.g., 'recordings/wavetable/SAW1'
      %
      % returns:
      %   fn  - The file name: <vVZ>/waves/<rid>.wav
      %
      % See also getPmFn

      fn = ['../waves/' rid '.wav'];
      fn = strrep(fn,'\','/');
    end

    function fn = getPmFn(rid)
      % Obtains the pitch mark file name for a vVZ recording ID.
      %
      %    fn = vVZtools.getPmFn(rid)
      %
      % arguments:
      %   rid - The recording ID, e.g., 'recordings/wavetable/SAW1'
      %
      % returns:
      %   fn  - The file name: <vVZ>/labels/<rid>.pm
      %
      % See also getWaveFn
      
      fn = ['../labels/' rid '.pm'];
      fn = strrep(fn,'\','/');
    end
    
    function lab = timitread(fn,filter)
      % Reads a TIMIT label file.
      %
      %   lab = vVZtools.timitread(fn,filter)
      %
      % arguments:
      %   fn     - Name of TIMIT label file
      %   filter - Label name to filter for (optional, default is no filtering)
      %
      % returns:
      %   lab    - The labels as a table containing the following variables:
      %            - k_S : zero-based sample index of label beginning
      %            - k_E : zero-based sample index of label end
      %            - name: label name
      %
      % See also timitwrite
      
      fid = fopen(fn,'r');
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
    
    function timitwrite(fn,lab)
      % Reads a TIMIT label file.
      %
      %   vVZtools.timitwrite(fn,lab)
      %
      % arguments:
      %   fn  - Name of TIMIT label file
      %   lab - The labels as a table containing the following variables:
      %         - k_S : zero-based sample index of label beginning
      %         - k_E : zero-based sample index of label end
      %         - name: label name
      %
      % throws exception:
      %   - If lab has a wring format
      %   - If the output file cannot be written
      %
      % See also timitread
      
      % Get table variables
      k_S  = lab.k_S;
      k_E  = lab.k_E;
      name = lab.name;
      
      % Create path
      path = fileparts(fn);
      mkdir(path);
 
      % Write output file
      fid  = fopen(fn,'w');
      for i=1:length(k_S)
        fprintf(fid,'%d %d %s\n',k_S(i),k_E(i),name{i});
      end
      fclose(fid);      
    end
    
    function [wave,pm,props,msg] = loadRecording(rid)
      % Loads a vVZ rescording.
      %
      %   [wave,pm,props] = vVZtools.oadRecording(rid)
      %
      % arguments:
      %   rid   - The recording ID, e.g., 'recordings/wavetable/SAW1'
      %
      % returns:
      %   wave  - The recording, an array of samples or an empty array if no
      %           wave file exists for the recording ID
      %   pm    - Pitch marks, an arry of zero-based sample indexes or an empty
      %           array if no pitch mark file exists for the recording ID
      %   props - RESERVED
      %   msg   - Message
      %
      % See also getWavFn, getPmFn
      
      fprintf('vVZtools.loadRecording(rid="%s")\n',rid);
      wave  = [];
      pm    = [];
      props = [];
      msg   = 'ok';

      % Read wave file
      fn = vVZtools.getWaveFn(rid);
      fprintf('- Read wave file "%s"\n',fn);
      try
        wave = audioread(fn);
        fprintf('  - OK, %d samples\n',length(wave));
      catch ME
        msg = sprintf('Cannot read wave file "%s". Reason: %s',fn,ME.message);
        fprintf('  - FAILED, reason: %s\n',ME.message);
        return;
      end
      
      % Read pitch mark file
      fn = vVZtools.getPmFn(rid);
      fprintf('- Read pitch marks file "%s"\n',fn);
      try
        lab = vVZtools.timitread(fn,'PM');
        pm  = lab.k_E;
        fprintf('  - OK, %d pitch marks\n',length(pm));
      catch ME
        msg = sprintf('Cannot read label file "%s". Reason: %s',fn,ME.message);
        fprintf('  - FAILED, reason: %s\n',ME.message);
      end
      
      % TODO: Read props from par file!
    end  
    
    function [status,msg] = savePitchMarks(rid,pm)

      fprintf('vVZtools.savePitchMarks(rid="%s")\n',rid);
      
      % Prepare label table
      k_E  = sort(pm);
      k_S  = zeros(length(pm),1);
      name = cell(length(pm),1);
      for i=1:length(pm)
        if i==1
          k_S(i) = 0;
        else
          k_S(i) = k_E(i-1);
        end
        name{i} = 'PM';
      end
      lab = table(k_S,k_E,name);
      
      % Write TIMIT file
      fn = vVZtools.getPmFn(rid);
      fprintf('- Write pitch mark file "%s"\n',fn);
      try
        vVZtools.timitwrite(fn,lab);
        status = 1;
        msg    = 'ok';
        fprintf('  - OK\n');
      catch ME
        status = 0;
        msg    = sprintf('Cannot write file "%s". Reason %s',fn,ME.message);
        fprintf('  - FAILED, reason: %s\n',ME.message);
      end
      
    end
    
  end
  
  %% == Labeling ===============================================================
  methods(Static)

    function kf = seekClosest(wave,k,L,fnc,varargin)
      % Seeks an event in a wave
      %
      %   kf = seekClosest(wave,k,L,@zeroCrossingF,l,t)
      %   kf = seekClosest(wave,k,L,@zeroCrossingR,l,t)
      %
      % arguments:
      %   wave     - A vector of samples
      %   k        - Zero-based sample index to start seeking from
      %   L        - Range to seek in: [k-L,k+L]
      %   fnc      - Detector function (see remarks)
      %   varargin - Additional arguments to detector function
      %
      % returns: 
      %   kf       - Zero-based sample index of closest event or
      %              -1 if no event has been found
      %
      % remarks:
      %   Valid detector functions have the signature
      %
      %      tf = fnc(wave,k,varargin)
      %
      %   where the return value is a Boolean indicating the detection
      %   result. Detector functions must cope with indexes k<0 and
      %   k>length(wave)-1 without throwing exceptions!

      kf = -1;
      for dk=0:L
        if fnc(wave,k+dk,varargin)
          kf = k+dk;
          return;
        end
        if fnc(wave,k-dk,varargin)
          kf = k-dk;
          return;
        end
      end
    end
    
    function tf = zeroCrossingF(wave,k,l,t)
      % Detects a falling-edge zero crossing.
      %
      %   tf = zeroCrossingF(wave,k,l,t)
      %
      % arguments:
      %   wave - A vector of samples
      %   k    - Zero-based sample index to examine
      %   l    - Detection window [k-l,k+l]
      %   t    - Detection threshold (samples values left of k must reach
      %          t, sample values right of k must reach -t)
      %
      % returns:
      %   tf   - True if a falling-edge zero crossing is at k,
      %          false otherwise
      %
      % See also zeroCrossingR, autoPitchMark

      if nargin==3 && iscell(l)                                                 % Args.3,4 committed as cell array >>
        t = l{2};                                                               %   Get t
        l = l{1};                                                               %   Get l
      end                                                                       % <<
      tf = false;                                                               % Initialize return value
      K  = length(wave);                                                        % Length wave
      if k<l || k>=K-l; return; end                                             % k too close to ends -> return
      i = k+1;                                                                  % One-based sample index
      wl = wave(i-l:i-1);                                                       % L samples left of k
      wr = wave(i:i+l);                                                         % L samples right of k
      if ~all(wl> 0); return; end                                               % non-positive left samples -> return
      if ~all(wr<=0); return; end                                               % positive right samples -> return
      if max(wl)< t ; return; end                                               % threshold missed left -> return
      if min(wr)>-t ; return; end                                               % threshold missed right -> return
      tf = true;                                                                % Yup - there's a zero cr. at k
    end
    
    function tf = zeroCrossingR(wave,k,l,t)
      % Detects a rising-edge zero crossing.
      %
      %   tf = zeroCrossingR(wave,k,l,t)
      %
      % arguments:
      %   wave - A vector of samples
      %   k    - Zero-based sample index to examine
      %   l    - Detection window [k-l,k+l]
      %   t    - Detection threshold (samples values left of k must reach
      %          t, sample values right of k must reach -t)
      %
      % returns:
      %   tf   - True if a rising-edge zero crossing is at k,
      %          false otherwise
      %
      % See also zeroCrossingF, autoPitchMark

      if nargin==3 && iscell(l)                                                 % Args.3,4 committed as cell array >>
        t = l{2};                                                               %   Get t
        l = l{1};                                                               %   Get l
      end                                                                       % <<
      tf = false;                                                               % Initialize return value
      K  = length(wave);                                                        % Length wave
      if k<l || k>=K-l; return; end                                             % k too close to ends -> return
      i = k+1;                                                                  % One-based sample index
      wl = wave(i-l:i-1);                                                       % L samples left of k
      wr = wave(i:i+l);                                                         % L samples right of k
      if ~all(wl< 0); return; end                                               % non-negtive left samples -> return
      if ~all(wr>=0); return; end                                               % negative right samples -> return
      if min(wl)>-t ; return; end                                               % threshold missed left -> return
      if max(wr)< t ; return; end                                               % threshold missed right -> return
      tf = true;                                                                % Yup - there's a zero cr. at k
    end

    function [pm,K0m] = autoPitchMark(wave,k0,K0,l,t)
      % Automatic pitch marking.
      %
      %   [pm,K0m] = vVZtools.autoPitchMark(wave,k0,K0,l,t)
      %
      % arguments:
      %   wave - A vector of samples
      %   k0   - Zero-based sample index of approximate position of first
      %          pitch mark
      %   K0   - Approximate cycle length in samples
      %   l    - Length of zero-crossing detection window
      %   t    - Zero-crossong detection threashold
      %
      % returns:
      %   pm   - The pitch detected marks, an array of zero-based sample indexes
      %   K0m  - The average cycle length in samples
      %
      % See also zeroCrossingR, zeroCrossingF
      
      fprintf('vVZtools.autoPitchMark(k0=%d, K0=%d, l=%d, t=%f)\n',k0,K0,l,t);
      pm  = [];
      K0m = -1;

      % Pre-cheks
      if isempty(wave); return; end
      K = length(wave);
      if k0<0 || k0>=K
        warning('k0 must be in [0,%d]. ABORTING.',K-1);
        return;
      end
      if K0<=0
        warning('K must be positive. ABORTING.');
        return;
      end
      
      % Search initial zero-crossing near k0
      fprintf('- Pitch mark at cycle beginning: ');
      L   = round(K0/4); % Search range
      kzf = vVZtools.seekClosest(wave,k0,L,@vVZtools.zeroCrossingF,l,t);
      kzr = vVZtools.seekClosest(wave,k0,L,@vVZtools.zeroCrossingR,l,t);
      if kzf>=0 && kzr>=0
        if abs(k0-kzf)<=abs(k0-kzr)
          kz0 = kzf;
          falling = true;
        else
          kz0 = kzr;
          falling = false;
        end
      elseif kzf>=0
        kz0 = kzf;
        falling = true;
      elseif kzr>=0
        kz0 = kzr;
        falling = false;
      else
        fprintf('not found -> ABORT\n');
        return;
      end
      if falling
        fprintf('k=%d, falling edge\n',kz0);
      else
        fprintf('k=%d, rising edge\n',kz0);
      end

      % Seek zero-crossing near k0+K0
      if falling
        kz1 = vVZtools.seekClosest(wave,k0+K0,L,@vVZtools.zeroCrossingF,l,t);
      else
        kz1 = vVZtools.seekClosest(wave,k0+K0,L,@vVZtools.zeroCrossingR,l,t);
      end
      fprintf('- Pitch mark at cycle end      : ');
      if kz1<0
        fprintf('not found -> ABORT\n');
        return;
      else
        K0 = kz1-kz0;
        fprintf('k=%d, K0:=%d\n',kz1,K0);
      end

      % Seek further zero-crossings to the left
      k = kz0-K0;
      while k>0
        if falling
          kz = vVZtools.seekClosest(wave,k,L,@vVZtools.zeroCrossingF,l,t);
        else
          kz = vVZtools.seekClosest(wave,k,L,@vVZtools.zeroCrossingR,l,t);
        end
        if kz<0; break; end
        %fprintf('- Pitch mark at                : k=%d\n',kz);
        pm(length(pm)+1) = kz; %#ok
        k = kz-K0;
      end
      
      % Add initial pitch marks to output
      pm(length(pm)+1) = kz0;
      pm(length(pm)+1) = kz1;

      % Seek further zero-crossings to the right
      k = kz1+K0;
      while k<K-1
        if falling
          kz = vVZtools.seekClosest(wave,k,L,@vVZtools.zeroCrossingF,l,t);
        else
          kz = vVZtools.seekClosest(wave,k,L,@vVZtools.zeroCrossingR,l,t);
        end
        if kz<0; break; end
        %fprintf('- Pitch mark at                : k=%d\n',kz);
        pm(length(pm)+1) = kz;
        k = kz+K0;
      end
      
      % Sort pitch marks
      pm = sort(pm);
      fprintf('- Found %d further zero-crossings\n',length(pm)-2);
      
      % Compute mean cylce length
      K0m = 0;
      for i=2:length(pm)
        K0m = K0m + (pm(i)-pm(i-1));
      end
      K0m = K0m/(length(pm)-1);
      fprintf('- Mean cycle length: %f samples\n',K0m);
    end
    
  end
  
end
% EOF