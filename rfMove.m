function [code] = rfMove (type,varargin)
% Very error prone - change Arduino handling for stability
persistent a x y Rstep Cstep LRwell
if ~ischar(type)
    code = -1;
    return;
end
if isempty(x) || isempty(y)
    x = 0;
    y = 0;
end
if isempty(LRwell)
    LRwell = [400,150];
end
if isempty(Rstep)
    Rstep = 180;
    Cstep = 180;
end
n = numel(varargin);
switch type
    case 'w'
        if n == 2 && isa(varargin{1},'double') && isa(varargin{2},'double')
            Rtarget = (varargin{1} - 1) * Rstep + LRwell(1);
            Ctarget = (varargin{2} - 1) * Cstep + LRwell(2);
            a.fhMoveTo(Rtarget,Ctarget);
            x = Rtarget;
            y = Ctarget;
            code = [x,y];
        else
            disp('rfMove: Command unrecognized')
            code = -1;
            return;
        end
    case 's'
        if n == 2 && isa(varargin{1},'double') && isa(varargin{2},'double')
            Rtarget = varargin{1};
            Ctarget = varargin{2};
            a.fhMoveTo(Rtarget,Ctarget);
            x = Rtarget;
            y = Ctarget;
            code = [x,y];
        else
            disp('rfMove: Command unrecognized')
            code = -1;
            return;
        end
    case 'i'
        if n == 2 && isa(varargin{1},'double') && isa(varargin{2},'double')
            Rtarget = varargin{1};
            Ctarget = varargin{2};
            a.fhMove(Rtarget,Ctarget);
            x = Rtarget + x;
            y = Ctarget + y;
            code = [x,y];
        else
            disp('rfMove: Command unrecognized')
            code = -1;
            return;
        end
    case 'p'
        if n == 2 && isa(varargin{1},'double') && isa(varargin{2},'double')
            x = varargin{1};
            y = varargin{2};
            code = [x,y];
        else
            disp('rfMove: Command unrecognized')
            code = -1;
            return;
        end
    case 'setup'
        switch n
            case 0
                disp('rfMove: Command unrecognized')
                code = -1;
                return;
            case 1
                switch class(varargin{1})
                    case 'ARD'
                        a = varargin{1};
                        x = 0;
                        y = 0;
                        code = 0;
                    case 'double'
                        if numel(varargin{1}) == 2
                            LRwell = varargin{1};
                            code = 0;
                        else
                            disp('rfMove: Command unrecognized')
                            code = -1;
                            return;
                        end
                    otherwise
                        disp('rfMove: Command unrecognized')
                        code = -1;
                        return;
                end
            case 2
                if isa(varargin{1},'double') && isa(varargin{2},'double')
                    Rstep = varargin{1};
                    Cstep = varargin{2};
                    code = 0;
                else
                    disp('rfMove: Command unrecognized')
                    code = -1;
                    return;
                end
            case 3
                v = varargin;
                l1 = isa(v{1},'double') && numel(v{1}) == 2;
                l2 = isa(v{2},'double') && isa(v{3},'double');
                if l1 && l2
                    LRwell = v{1};
                    Rstep = v{2};
                    Cstep = v{3};
                    code = 0;
                else
                    disp('rfMove: Command unrecognized')
                    code = -1;
                    return;
                end
            case 4
                v = varargin;
                l1 = isa(v{1},'ARD');
                l2 = isa(v{2},'double') && numel(v{2}) == 2;
                l3 = isa(v{3},'double') && isa(v{4},'double');
                if l1 && l2 && l3
                    a = v{1};
                    x = 0;
                    y = 0;
                    LRwell = v{2};
                    Rstep = v{3};
                    Cstep = v{4};
                    code = 0;
                else
                    disp('rfMove: Command unrecognized')
                    code = -1;
                    return;
                end
            otherwise
                disp('rfMove: Command unrecognized')
                code = -1;
                return;
        end
    case 'clear'
        clear rfMove
        code = 0;
        return;
    otherwise
        disp('rfMove: Command unrecognized')
        code = -1;
        return;
end