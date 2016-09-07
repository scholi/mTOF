classdef Block
    %BLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fid % file id to acces the data
        offset % offset in the file of the current block
        Type % type of the block
        name % name of the blockj
        value % Offet of the block content
        Head % header of the block
    end
    
    methods
        function self = Block(fileID)
            self.fid = fileID;
            self.offset = ftell(self.fid);
            self.Type = fread(self.fid,5);
            if(~all(self.Type(2:5)'==[25 0 0 0]))
                error('Wrong block format found!'); 
            end
            if(length(self.Type)<5)
                error('EOF reached. Block cannot be read');
            end 
            H = fread(self.fid,5,'uint32'); % slen, z, num, size1, size2
            self.Head = H;
            self.name = fread(self.fid,self.Head(1),'*char')';
            self.value = ftell(self.fid);
        end
        function obj = goto(self, path)
            names = strsplit(path, '/');
            obj = self;
            for i = 1:length(names)
                idx = 0;
                n = names{i};
                j = strfind(n ,'[');
                if j>0
                    idx = str2num( n(j+1:length(n)-1) );
                    n = n(1:j-1);
                end
                obj = obj.gotoItem(n,idx);
            end
        end
        function obj = gotoItem(self, name, id)
            if nargin<3
                id=0;
            end
            S = self.getList();
            for i = 1:size(S,2)
                if strcmp(name,S{1,i}) && id == S{2,i}
                    fseek(self.fid,S{4,i},-1);
                    obj = Block(self.fid);
                    return 
                end
            end
        end
        function out=getDouble(self)
            fseek(self.fid,self.value,-1);
            out = fread(self.fid, 1,'float64');
        end
        function out = getBin(self)
            fseek(self.fid,self.value,-1);
            out = fread(self.fid,self.Head(4))';
        end
        function out=getULong(self)
            fseek(self.fid,self.value,-1);
            out = fread(self.fid, 1,'uint32');
        end
        function out = getUTF16(self)
            fseek(self.fid,self.value,-1);
            bytes = fread(self.fid,self.Head(4))';
            out = native2unicode(bytes,'UTF-16LE');
        end
        function S=getList(self)
            fseek(self.fid,self.value,-1);
            prep1 = fread(self.fid, 3, 'uint32'); % index, slen, id
            fread(self.fid, 9); % skip 9 bytes
            L = fread(self.fid, 1, 'uint32');
            fread(self.fid, 8); % skip 8 bytes
            NextBlock = fread(self.fid, 1, 'uint64');
            N = self.Head(3);
            if(N==0)
                N = L;
            end
            S = cell(4,N);
            for i = 1:N
                fread(self.fid,1); % skip 1 byte
                prep = fread(self.fid, 3, 'uint32'); % index, slen, id
                fread(self.fid,4); % skip 4 bytes
                bck = ftell(self.fid); % store position
                fseek(self.fid,self.value,-1); % go back to the beginning of the inner-block
                fseek(self.fid,prep(1),0); % relative seek forward for string
                S{1,i} = fread(self.fid,prep(2),'*char')';
                fseek(self.fid,bck,-1); % go back to the right position in the file
                S{2,i} = prep(3);
                S{3,i} = fread(self.fid, 1, 'uint64'); % block length
                S{4,i} = fread(self.fid, 1, 'uint64'); %  block index (ie. start offset)
            end
            if(NextBlock~=0)
                fseek(self.fid,NextBlock,-1);
                Next = Block(self.fid);
                S=horzcat(S,Next.getList());
                clear Next; 
            end
        end
    end
    
end

