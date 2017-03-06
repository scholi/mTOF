classdef ITA
    %ITA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filename % filename of the ITA
        fid % store the file id
        type % should be always ITStrF01
        root % root Block element
        Peaks % Peaks list
        sx % image size in x
        sy % image size in y
        Nscan % number of scans
        Nimg % Number of images (channels)
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
            self.Peaks = self.getPeaks();
            self.sx = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.XSize').getULong(); % Image size (X) in piexels
            self.sy = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.YSize').getULong(); % Image size (Y) in piexels
            self.Nscan = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.NumberOfScans').getULong();
            self.Nimg = self.root.goto('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image.NumberOfImages').getULong() ; 
        end
        function out = getChannelNameById(self, id)
            for i = 1:length(self.Peaks)
                if self.Peaks{i,1}==id
                    out = self.Peaks{i,3};
                    return
                end
            end
        end
        function res = getChannelByName(self, name)
            res={};
            ri=1;
            for i = 1:length(self.Peaks)
                ma=regexp(self.Peaks{i,3},name);
                if length(ma)>0
                    res{ri}=self.Peaks(i,:)';
                    ri =ri+1;
                end
            end
            res = horzcat(res{:});
        end
        function out = getImageSumById(self, channels, scans)
            if nargin<3
                scans = 1:self.Nscan;
            end
            out = zeros(self.sx,self.sy);
            for i = 1:length(channels)
                for j = 1:length(scans)
                    Z = self.getImageById(channels(i), scans(j));
                    out = out + Z;
                end
            end     
        end
        function [out, channels] = getImageSumByMass(self, masses, scans)
            if nargin<3
                scans = 0:self.Nscan-1;
            end
            channels = {};
            out = zeros(self.sx,self.sy);
            for i = 1:length(masses)
                C = self.getChannelByMass(masses(i));
                channels(:,i)=C(:,size(C,2));
                ch = C{1,size(C,2)};
                for j = 1:length(scans)
                    Z = self.getImageById(ch, scans(j));
                    out = out + Z;
                end
            end     
        end
        function [out, channels] = getAddedImageByMass(self, masses)
            channels = {};
            out = zeros(self.sx,self.sy);
            for i = 1:length(masses)
                C = self.getChannelByMass(masses(i));
                channels(:,i)=C(:,size(C,2));
                ch = C{1,size(C,2)};
                Z = self.getAddedImageById(ch);
                out = out + Z;
            end     
        end
        function [out, channels] = getImageSumByName(self, names, scans)
            if nargin<3
                scans = 0:self.Nscan-1;
            end
            out = zeros(self.sx,self.sy);
            channels = self.getChannelByName(names);
            for i = 1:size(channels,2)
                for j = 1:length(scans)
                    ch =channels{1,i};
                    Z = self.getImageById(ch, scans(j));
                    out = out + Z;
                end
            end     
        end
        function [out, channels] = getAddedImageByName(self, names)
            out = zeros(self.sx,self.sy);
            channels = self.getChannelByName(names);
            for i = 1:size(channels,2)
                ch =channels{1,i};
                Z = self.getAddedImageById(ch);
                out = out + Z;
            end     
        end
        function res = getChannelByMass(self, mass)
            res={};
            ri=1;
            for i = 1:length(self.Peaks)
                if self.Peaks{i,5}<=mass && self.Peaks{i,6}>=mass
                    res{ri}=self.Peaks(i,:)';
                    ri =ri+1;
                end
            end
            res = horzcat(res{:});
        end
        function Tot = getAddedImageById(self, id)
            Raw = self.root.goto(strcat('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScansAdded/Image[',num2str(id),']/ImageArray.Long')).getBin();
            Tot = reshape(typecast(zlibdecode(uint8(Raw)),'single'),[self.sy,self.sx])';
        end
        function Tot = getImageById(self, id, scan)
            Raw = self.root.goto(strcat('filterdata/TofCorrection/ImageStack/Reduced Data/ImageStackScans/Image[',num2str(id),']/ImageArray.Long[',num2str(scan),']')).getBin();
            Tot = reshape(typecast(zlibdecode(uint8(Raw)),'single'),[self.sy,self.sx])';
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

