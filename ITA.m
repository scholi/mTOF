classdef ITA
    %ITA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filename % filename of the ITA
        fid % store the file id
        type % should be always ITStrF01
        root % root Block element
    end
    
    methods
        function self = ITA(filename)
            self.filename = filename;
            self.fid = fopen(filename,'rb');
            self.type = fread(self.fid,8,'*char')';
            if ~strcmp(self.type,'ITStrF01')
                error(strcat('The filename "',filename,'" does not seem to be a valid ITA file'));
            end
            self.root = Block(self.fid);
        end
        function Tot = getImageById(self, id)
            sx = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.XSize').getULong(); % Image size (X) in piexels
            sy = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.YSize').getULong(); % Image size (Y) in piexels
            Nscan = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.NumberOfScans').getULong();
            Nimg = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.NumberOfImages').getULong() ;       
            Tot = zeros(sx,sy);
            for i = 0:Nscan-1
                Raw = self.root.goto(strcat('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image/ImageArray.Long[',num2str(i),']')).getBin();
                Tot = Tot + reshape(typecast(zlibdecode(uint8(Raw)),'single'),[sy,sx])';
            end
        end
        function Peaks = getPeaks(self)
            Peaks={};
            j=1;
            S=self.root.goto('MassIntervalList').getList();
            for i = 1:length(S)
                if strcmp(S{1,i},'mi')
                    try
                        m = self.root.goto(strcat('MassIntervalList/mi[',num2str(S{2,i}),']'));
                    catch
                        continue
                    end
                    id = m.goto('id').getULong();
                    Peaks{j,1} = id;
                    Peaks{j,2} = S{2,i};
                    Peaks{j,3} = strcat(m.goto('desc').getUTF16(),m.goto('assign').getUTF16());
                    Peaks{j,4} = m.goto('cmass').getDouble();
                    Peaks{j,5} = m.goto('lmass').getDouble();
                    Peaks{j,6} = m.goto('umass').getDouble();
                    j = j + 1;
                end
            end
        end
    end
    
end

