function translate_PAAS_to_nc(campaign,savefolder,savefilename, ...
    b_abs,b_abs_highres,time,time_highres,rawdatafilename,laser_wavelength)
%translate_PAAS_to_nc Writes a NetCDF file containing PAAS data
%   Input:  campaign        name of the campaign
%           savefolder      folder where data is saved
%           savefilename    filename for results
%           b_abs           averaged b_abs
%           b_abs_highres   highresolution b_abs
%           time            time axis corresponding to b_abs (one for all)
%           time_highres    time axis corresponding to b_abs_highres
%           rawdatafil.     filename for raw data
%           laser_wavel.    laser wavelengths in nm    

    
%% If filename already exists, delete it
    if ~isfolder(savefolder)
        mkdir(savefolder)
    end
    filename = [savefolder,filesep,savefilename];
    if exist(filename)
         delete(filename)
    end


    %% 1. Create file with variable
    nccreate(filename,'time', 'Dimensions', {'time',size(time',1),'y1',1}, 'FillValue','disable');
    for i = 1:length(laser_wavelength)
        nccreate(filename,['time_highres_',num2str(laser_wavelength(i))], 'Dimensions', {'time_highres',size(time_highres',1),'y1',1}, 'FillValue','disable');
        nccreate(filename,['b_abs_',num2str(laser_wavelength(i))], 'Dimensions', {'time',size(b_abs',1),'y1',1}, 'FillValue','disable');
        nccreate(filename,['b_abs_highres_',num2str(laser_wavelength(i))], 'Dimensions', {'time_highres',size(b_abs_highres',1),'y1',1}, 'FillValue','disable');
    end

    %% 2. write in file
    ncwrite(filename,'time',posixtime(time'))
        ncwriteatt(filename,'time','unit','seconds since 1970-01-01 00:00:00');
        ncwriteatt(filename,'time','long name','Time axis for b_abs variable. The time axis is the same for all lasers.');
    for i = 1:length(laser_wavelength)
        ncwrite(filename,['time_highres_',num2str(laser_wavelength(i))],posixtime(time_highres(i,:)'))
            ncwriteatt(filename,['time_highres_',num2str(laser_wavelength(i))],'unit','seconds since 1970-01-01 00:00:00');
            ncwriteatt(filename,['time_highres_',num2str(laser_wavelength(i))],'long name',['Time axis for b_abs_highres',num2str(laser_wavelength(i)),' variable.']);
        ncwrite(filename,['b_abs_',num2str(laser_wavelength(i))],b_abs(i,:)')
            ncwriteatt(filename,['b_abs_',num2str(laser_wavelength(i))],'unit','M-1');
            ncwriteatt(filename,['b_abs_',num2str(laser_wavelength(i))],'long name',['Absorption coefficient for ',num2str(laser_wavelength(i)),' nm.']);
        ncwrite(filename,['b_abs_highres_',num2str(laser_wavelength(i))],b_abs_highres(i,:)')
            ncwriteatt(filename,['b_abs_highres_',num2str(laser_wavelength(i))],'unit','M-1');
            ncwriteatt(filename,['b_abs_highres_',num2str(laser_wavelength(i))],'long name',['Absorption coefficient in high resolution for ',num2str(laser_wavelength(i)),' nm.']);
    end

    %% 3. Write global attributes
    fileattrib(filename,"+w");
    ncwriteatt(filename,"/","author",'M. Schnaiter, martin.schnaiter@kit.edu');
    ncwriteatt(filename,"/","creation_date",datestr(now));
    ncwriteatt(filename,"/","reference",'doi.org/10.5194/amt-16-2753-2023');
    ncwriteatt(filename,"/","campaign",campaign);
    ncwriteatt(filename,"/","number of lasers",num2str(length(laser_wavelength)));
    ncwriteatt(filename,"/","raw data filename",rawdatafilename);
    for i = 1:length(laser_wavelength)
        ncwriteatt(filename,"/",strjoin({'laser',num2str(i),'wavelength in nm'}),num2str(laser_wavelength(i)));
    end



    ncdisp(filename)
end