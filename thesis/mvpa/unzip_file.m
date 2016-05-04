function unzip_file(fileName)
    zippedFileName = strcat(fileName, '.gz');
    if ~exist(fileName)
        assert(exist(zippedFileName) == 2, sprintf('Neither %s nor %s exists', fileName, zippedFileName));
        printf('File %s is Zipped. Unzipping...', fileName);
        gunzfile = strcat(zippedFileName);
        if ismac
            gunzip(gunzfile);
        else
            status = unix(strcat('gunzip ', gunzfile));
        end
        printf('Unzipping %s', status);
    end
