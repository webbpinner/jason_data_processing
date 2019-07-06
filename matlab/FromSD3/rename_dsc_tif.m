%rename_dsc_tif.m
%
%Takes the digital still camera files and renames them using the time they
%were created.  Note that when copying the files onto this machine use
% cp -p {source} {destination}
%to preserve original time stamp.
%
%To figure out time offset, open a picture viewer and note the time of the
%photographed clock before the launch and the name of the file.
%Verify that the new file names are consistent with the determined offset.
%Iterate again as necessary.
%
%This MatLab script should replace the PERL script previously used on Dan
%Fornari's Ibook computer.
%
%
%   Program History
%
%   Spring 2005  ???     created
%
%   09/2005      vlf     modified to be more universal. no longer need to
%                           hard code path names. User is now prompted to
%                           input time offset in a window.
%


%prompt the user for the input image directory
%directory = uigetdir;
%eval(['cd ' directory ';']);

%prompt the user for the time offset
prompt={'Enter offset (+/-seconds):'}
name=('Time Offset')
defaultanswer={'3'};
answer=inputdlg(prompt,name,1,defaultanswer);
addsec=str2num(char(answer));

directory=sprintf('./');
d = dir(strcat(directory,'/J2*.tif'));
s = strvcat(d.name);

start = 1;
stop = size(s,1);

Inames = s(start:stop,:);

if ~exist(strcat(directory,'/Time_Stamped'),'dir')
    mkdir(strcat(directory,'/Time_Stamped'));
end

numImages = size(Inames,1);
for ii = 1:numImages
    S=imfinfo(Inames(ii,:));
    [da ti]=strread(S.FileModDate,'%s%s','delimiter',' ');
    [day month year]=strread(char(da),'%d%s%d','delimiter','-');
    [hour minute second]=strread(char(ti),'%d%d%d','delimiter',':');
    second=second+addsec;
    if (second >= 60)
        second=second-60;
        minute=minute+1;
        if (minute >= 60)
            minute=minute-60;
            hour=hour+1;
            if (hour >= 24)
                hour=hour-24;
                day=day+1;
            end
        end
    elseif (second < 0)
        second=second+60;
        minute=minute-1;
        if (minute < 0)
            minute=minute+60;
            hour=hour-1;
            if (hour < 0)
                hour=hour+24;
                day=day-1;
            end
        end
    end

    monthLookup=['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'];
    mnth=strmatch(char(month),monthLookup);

    newname=sprintf('Time_Stamped/%4.4d_%02.2d_%2.2d_%2.2d_%2.2d_%2.2d.%4.4d.tif',year,char(mnth,day,hour,minute,second,ii));
    fprintf('%s %s\n',Inames(ii,:),newname);
    copyfile(Inames(ii,:), newname);
end

fprintf('\n');



