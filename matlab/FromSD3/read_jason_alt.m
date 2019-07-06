function [alts] = read_jason_alt(filename)

filt_str = sprintf('!grep ALT %s | awk ''NF == 8'' > altimeter.tmp', filename)
%filt_str=sprintf('grep ALT %s | awk ''NF == 8''', filename)
eval(filt_str);

lsr = dir('altimeter.tmp');
if lsr.bytes > 44

   struct_fields = {'year','month','day','hour','minute','second', ...
    'altitude', 'unk1', 'unk2', 'therest'};

   fid = fopen('altimeter.tmp');

   altc = textscan(fid, 'ALT %f/%f/%f %f:%f:%f JAS2 %f %f %d %s', ...
    'CommentStyle', 'Y');

   fclose(fid);

   alts = cell2struct(altc, struct_fields, 2);

   alts.t = ymdhms_to_sec(alts.year(:), alts.month(:), alts.day(:), ...
    alts.hour(:), alts.minute(:), alts.second(:));

   alts=time_fixup(alts);

else
   alts = [];
end
