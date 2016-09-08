classdef ITS
    %ITS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filename % filename of the ITS
        fid % file ID
        Type % Should be ITStrF01
        root % Block of the root element (see Block class)
    end
    
    methods
        function self = ITS(filename)
            self.filename = filename;
            self.fid = fopen(self.filename, 'rb');
            self.Type = fread(self.fid,8,'*char')';
            if ~strcmp(self.Type,'ITStrF01')
                error(strcat('The filename "',filename,'" does not seem to be a valid ITA file'));
            end
            self.root = Block(self.fid);
        end
        function [masses,Data] = getSpectra(self, ID)
            X = zlibdecode(uint8(self.root.goto(strcat('DataCollection/',num2str(ID),'/Reduced Data/IITFSpecArray/CorrectedData')).getBin()));
            N=length(X)/4;
            ch = 0:N-1;
            % The channel-mass conversion was found empirically from data
            % There is no guarenty that this will be correct for all Data!!!
            masses = polyval([8.75206913e-10,1.82528185e-06,9.51676243e-04],ch);
            Data = typecast(X,'single')';
        end
    end
    
end

