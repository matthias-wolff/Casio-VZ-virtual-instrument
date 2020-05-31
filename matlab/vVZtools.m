 classdef vVZtools
  % Library of static methods.

  properties(Constant)
    
    dirWav = '../waves/';
    dirLab = '../labels/';
    
  end
  
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
      % Inverts the phase modulation y(k) = x2(k + K*x1(k)) with 0<=k<K.
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

    function theta = pdmA2theta(a) 
      % Converts the slope paramter of phase distortion modulation to the angle 
      % parameter.
      %
      %   theta = vVZtools.pdmA2theta(a)
      %
      % arguments:
      %   a     - The slope parameter
      %
      % returns: 
      %   theta - The angle parameter
      %
      % See also pdmTheta2a

      theta = (pi-atan(a)+atan(a./(2*a-1)))/pi*180;
    end
    
    function a = theta2a(theta)
      % Converts the angle paramter of phase distortion modulation to the slope 
      % parameter.
      %
      %   a = vVZtools.theta2a(theta)
      %
      % arguments:
      %   theta - The angle parameter
      %
      % returns: 
      %   a     - The slope parameter
      %
      % See also pdmA2theta

      a = theta;
      syms aparam real;
      assume(aparam>=1);
      for i=1:length(theta)
        t = theta(i)/180*pi;
        S = solve(t==pi-atan(aparam)+atan(aparam/(2*aparam-1)),aparam);
        a(i) = eval(S);
      end
    end
    
    function phipd = PDMcc(phi,a)
      % Caracteristic Curve of phase distorion modulation.
      %
      %   phipd = vVZtools.PDMcc(phi,a)
      %
      % arguments:
      %   phi   - An array of phase angles in the range [0,2*pi]
      %   a     - The PDM slope parameter
      %
      % returns:
      %   phipd - An array of PDM-modulated phase angles

      assert(all(phi>=0) && all(phi<=2*pi));
      phiB = pi./a;
      phipd = (phi<=phiB).*a.*phi + (phi>phiB).*(a.*phi+2*pi*(a-1))/(2*a-1);
    end
    
    function phipd = PDMccVZ(phi,a,phi0)
      assert(all(phi>=0) && all(phi<=2*pi));
      phiB = (pi-phi0)./a;
      phipd = (phi<=phiB).*a.*phi + (phi>phiB).*(a.*(phi0+pi).*phi-2*pi*(phi0-pi)*(a-1))/(phi0-pi+2*pi*a);
    end
    
  end

  %% == Signal and Label Files =================================================
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

      fn = [vVZtools.dirWav rid '.wav'];
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
      
      fn = [vVZtools.dirLab rid '.pm'];
      fn = strrep(fn,'\','/');
    end

    function fn = getParFn(rid)
      % Obtains the annotation file name for a vVZ recording ID.
      %
      %    fn = vVZtools.getParFn(rid)
      %
      % arguments:
      %   rid - The recording ID, e.g., 'recordings/wavetable/SAW1'
      %
      % returns:
      %   fn  - The file name: <vVZ>/labels/<rid>.par
      %
      % See also getWaveFn
      
      fn = [vVZtools.dirLab rid '.par'];
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
      % throws exception:
      %   - If the input file cannot be read
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
      % Writes a TIMIT label file.
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
      %   - If lab has a wrong format
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
    
    function lab = parread(fn,filter,exclude)
      % Reads a Partitur label file.
      %
      %   lab = vVZtools.parread(fn,filter,exclude)
      %
      % arguments:
      %   fn      - Name of Partitur label file
      %   filter  - Tiers to include or exclude, a cell vector of strings or
      %             character arrays (optional, default is no filtering)
      %   exclude - if true, tiers listed in filter argument are excluded
      %             (optional, default is false, i.e., tiers listed in filter 
      %             argument are included)
      %
      % returns:
      %   lab     - The labels as a table containing the following variables:
      %             - tier : tier name
      %             - value: value as string
      %
      % throws exception:
      %   - If the input file cannot be read
      %
      % See also parwrite
      
      % Read and parse Partitur file
      tier  = cell(0);
      value = cell(0);
      fid   = fopen(fn,'r');
      i     = 1;
      s     = fgetl(fid);
      while ischar(s)
        s = strtrim(s);
        if strlength(s)>0
          d = strfind(s,':');
          if ~isempty(d)
            tier{i,1}  = strtrim(s(1:d(1)-1));
            value{i,1} = strtrim(s(d(1)+1:strlength(s)));
            i = i+1;
          end
        end
        s = fgetl(fid);
      end
      fclose(fid);
      lab = table(tier,value);

      % Filter tiers
      if nargin>=2
        if nargin<3; exclude = false; end
        mask = contains(tier,filter);
        if exclude; mask = 1-mask; end
        i = 1;
        while i<=height(lab)
          if mask(i)==1
            i = i+1;
          else
            mask(i,:) = [];
            lab (i,:) = [];
          end
        end
      end
    end
    
    function parwrite(fn,lab)
      % Writes a Partitur label file.
      %
      %   vVZtools.parwrite(fn,lab)
      %
      % arguments:
      %   fn  - Name of TIMIT label file
      %   lab - The labels as a table containing the following variables:
      %         - tier : tier name
      %         - value: value as string
      %
      % throws exception:
      %   - If lab has a wrong format
      %   - If the output file cannot be written
      %
      % See also parread
      
      % Get table variables
      tier  = lab.tier;
      value = lab.value;
      
      % Create path
      path = fileparts(fn);
      mkdir(path);
 
      % Write output file
      L = max(strlength(tier))+2;
      fid  = fopen(fn,'w');
      for i=1:length(tier)
        if strlength(tier{i})>0 % Ignore empty tier tags!
          s = [tier{i} ':'];
          fmt = sprintf('%%-%ds%%s\\n',L);
          fprintf(fid,fmt,s,value{i});
        end
      end
      fclose(fid);      
    end
    
    function val = parseKeyVal(keyVal,key,fmt)
      % Returns a value from a list of key=value pairs.
      %
      %   val = vVZtools.parseKeyVal(keyVal,key,fmt)
      %
      % arguments:
      %   keyVal - A cell vector of "key = value" strings
      %   key    - Key to search for
      %   fmt    - Format string of value, e.g., '%d'
      %
      % returns
      %   val    - The value or an empty array if the key is not found or the
      %            value could not be parsed
      
      val = [];
      for i=1:length(keyVal)
        kv = strsplit(keyVal{i},'=');
        if strcmp(strtrim(kv{1}),key)
          val = sscanf(strtrim(kv{2}),fmt,1);
          return
        end
      end
    end
    
    function rlst = listRecordings(filter)
      % List vVZ test recordings.
      %
      %   rlst = vVZtools.listRecordings()
      %   rlst = vVZtools.listRecordings(filter)
      %
      % arguments:
      %   filter - A regular expression to filter for
      %
      % returns:
      %   rlst   - A vector of recording IDs. A recording ID is a relative file
      %            name excluding the extension.
      %
      % See also regexp, loadRecording, saveAnnotations
      
      l = dir(vVZtools.dirWav);
      dirWav = l(1).folder;
      l = dir([dirWav '/**/*.wav']);
      rlst = cell(0);
      if nargin==0; filter = '.*'; end
      for i=1:length(l)
        rec = strrep(l(i).folder,dirWav,'');
        rec = strrep(rec,'\','/');
        rec = [ rec(2:length(rec)) '/' strrep(l(i).name,'.wav','')];
        if ~isempty(regexp(rec,filter,'ONCE'))
          rlst{length(rlst)+1,1} = rec;
        end
      end
      rlst = sort(rlst);
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
      % See also getWaveFn, getParFn
      
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
        fprintf('    Try to change to directory vVZ/matlab!\n');
        return;
      end

      % Read annotation file
      fn = vVZtools.getParFn(rid);
      fprintf('- Read annotation file "%s"\n',fn);
      try
        fprintf('  - Read properties\n');
        props = vVZtools.parread(fn,'PM',true);
        fprintf('    - OK, %d properties\n',height(props));
        fprintf('  - Read pitch marks\n');
        lab = vVZtools.parread(fn,'PM');
        pm = zeros(height(lab),1);
        for i=1:length(pm)
          pm(i) = sscanf(lab.value{i},'%d');
        end
        fprintf('    - OK, %d pitch marks\n',length(pm));
      catch ME
        msg = sprintf('Cannot annotation file "%s". Reason: %s',fn,ME.message);
        fprintf('  - FAILED, reason: %s\n',ME.message);
      end
      
      % Read pitch mark file
      if isempty(pm)
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
      end
      
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

    function [status,msg] = saveAnnotations(rid,pm,props)
      fprintf('vVZtools.saveAnnotations(rid="%s")\n',rid);
      
      % Prepare label table
      pm    = sort(pm);
      tier  = cell(length(pm),1);
      value = cell(length(pm),1);
      for i=1:length(pm)
        tier{i}  = 'PM';
        value{i} = sprintf('%d',pm(i));
      end
      lab = [ props; table(tier,value) ];
      
      % Write Partitur file
      fn = vVZtools.getParFn(rid);
      fprintf('- Write annotation file "%s"\n',fn);
      try
        vVZtools.parwrite(fn,lab);
        status = 1;
        msg    = 'ok';
        fprintf('  - OK\n');
      catch ME
        status = 0;
        msg    = sprintf('Cannot write file "%s". Reason %s',fn,ME.message);
        fprintf('  - FAILED, reason: %s\n',ME.message);
      end
    end
    
    function [cycle,k0] = cutNiceCycle(wave,pm,FL,K0)
      % Cuts a cycle with a specified length out of a wave.
      %
      %   cycle = vVZtools.cutNiceCycle(wave,pm,FL,K0)
      %
      % arguments:
      %   wave  - The wave, a vector of samples
      %   pm    - Pitch marks, a vector of zero-based sample indexes
      %   FL    - A vector containing the one-based index of first and the last
      %           pitch mark to consider for cutting.
      %   K0    - The cycle length in samples
      %
      % returns:
      %   cycle - The best wave cycle found in the search range, i.e., the cycle
      %           whose length is closest to K0
      %   k0    - The zero-based index of the first sample of the cycle
      
      pm0 = FL(1); if pm0<=1; pm0 = 1; end
      pm1 = FL(2); if pm1>=length(pm); pm1 = length(pm)-1; end
      
      iBest = -1;
      KBest = length(wave);
      for i=pm0:pm1
        K = pm(i+1)-pm(i);
        if abs(K0-K) < abs(K0-KBest)
          iBest = i;
          KBest = K;
        end
      end
      
      cycle = wave(pm(iBest)+1:pm(iBest+1));
      k0    = pm(iBest);
      
    end
    
  end
  
  %% == Labeling and Pitch Marking =============================================
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
      n = k+1;                                                                  % One-based sample index
      lok = false;                                                              % Left-samples-ok-flag
      for i=1:l                                                                 % Seek l samples to the left >>
        if wave(n-i)< 0; lok = false; break; end                                %   Negative -> definitely not ok
        if wave(n-i)>=t; lok = true;  break; end                                %   Reached threshold -> definitely ok
      end                                                                       % <<
      rok = false;                                                              % Right-samples-ok-flag
      for i=1:l                                                                 % Seek l samples to the right >>
        if wave(n+i)>  0; rok = false; break; end                               %   Positive -> definitely not ok
        if wave(n+i)<=-t; rok = true;  break; end                               %   Reached threshold -> definitely ok
      end                                                                       % <<
      tf = (lok && rok);                                                        % Yup - there's a zero cr. at k
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
      n = k+1;                                                                  % One-based sample index
      lok = false;                                                              % Left-samples-ok-flag
      for i=1:l                                                                 % Seek l samples to the left >>
        if wave(n-i)>  0; lok = false; break; end                               %   Positive -> definitely not ok
        if wave(n-i)<=-t; lok = true;  break; end                               %   Reached threshold -> definitely ok
      end                                                                       % <<
      rok = false;                                                              % Right-samples-ok-flag
      for i=1:l                                                                 % Seek l samples to the right >>
        if wave(n+i)< 0; rok = false; break; end                                %   Negative -> definitely not ok
        if wave(n+i)>=t; rok = true;  break; end                                %   Reached threshold -> definitely ok
      end                                                                       % <<
      tf = (lok && rok);                                                        % Yup - there's a zero cr. at k
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
  
  %% == Plotting ===============================================================
  methods(Static)

    function plotPmInvert(y,x1,ft,yl,a)
      K = length(y);
      k = 0:K-1;
      figure;
      yyaxis right;
      plot(k,y ,'-','LineWidth',2,'Color','red'); hold on;
      title(ft);
      xlim([0 K])
      set(gca,'XTick',0:K/4:K);
      set(gca,'XTickLabel',{'0','0.25','0.5','0.75','1'});
      xlabel('$$\frac{\varphi}{2\pi}$$','Interpreter','latex');
      ylabel("$$\frac{y(\varphi)}{a}$$ ($$a\!=\!"+sprintf('%g',a)+"$$)",'Interpreter','latex');
      yyaxis left;
      ylabel('$$x_1(\varphi)$$','Interpreter','latex');
      ylim(yl);
      scatter(x1(1,:),x1(2,:),2,'filled','MarkerFaceColor','blue');
      hold off;
    end

    function plotPmModelPhase(phix1_mea,phix1_mod,ft,yl,mX,mY)
      figure;
      K = length(phix1_mod);
      scatter(phix1_mea(1,:),phix1_mea(2,:),2,'filled','MarkerFaceColor',[0.85 0.85 1]);
      ylim(yl);
      xlim([0 K]);
      set(gca,'XTick',0:K/4:K);
      set(gca,'XTickLabel',{'0','0.25','0.5','0.75','1'});
      xlabel('$$\frac{\varphi}{2\pi}$$','Interpreter','latex');
      ylabel('$$\frac{\varphi_{x1}(\varphi)}{2\pi}$$','Interpreter','latex');
      title(ft);
      hold on;
      k = 0:K-1;
      plot(k,phix1_mod,'blue','LineWidth',2);
      scatter(mX,mY,100,'+','red');
      scatter(mX,mY,100,'o','red');
      hold off;
    end
 
    function plotPmModelSignal(y_mea,y_mod,ft)
      K = length(y_mea);
      k = 0:K-1;
      figure;
      yyaxis left;
      plot(k,y_mea,'LineWidth',2,'Color','blue');
      hold on;
      ylabel('$$y_{REC}(\varphi)$$','Interpreter','latex');
      yyaxis right;
      plot(k,y_mod,'LineWidth',2,'Color','red');
      ylabel("$$y_{MODEL}(\varphi)$$",'Interpreter','latex');
      title(ft);
      xlim([0,K]);
      set(gca,'XTick',0:K/4:K);
      set(gca,'XTickLabel',{'0','0.25','0.5','0.75','1'});
      xlabel('$$\frac{\varphi}{2\pi}$$','Interpreter','latex');
    end

  end

end
% EOF