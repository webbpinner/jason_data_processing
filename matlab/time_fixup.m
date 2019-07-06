% this function augments a structure to include extra time
% fields. The structure starts with a .t field, which contains
% the time in unix seconds. The augmented time fields
% include .t0 (seconds), .tm(minutes), .th (hours)
% which are all referenced to the start of the first day as
% determined from either the first entry in the input t vector or
% the second argument, tstart, which is optional. That is used to make
% the 0 day something other than the day of the first entry in
% the .t vector
function [s] = time_fixup(s0,tstart)

  if isfield(s0, 'unix_seconds')

    if numel(s0.unix_seconds>0)

      if(nargin ==1)

        tstart = s0.unix_seconds(1);
      end

      s = s0;
      s.t0 = mission_time(s.unix_seconds,tstart);
      s.th = s.t0/3600;
      s.tm = s.t0/60;

    else

      s = [];
      return;
    end

  elseif isfield(s0, 't')
    
    if numel(s0.t>0)
    
      if(nargin ==1)
        tstart = s0.t(1);
      end
    
      s = s0;
      s.t0 = mission_time(s.t,tstart);
      s.th = s.t0/3600;
      s.tm = s.t0/60;
    
    else
    
      s = [];
      return;
    end
  
  else
  
    s = [];
  end
end
