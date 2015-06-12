function [] = rfWell (r,c,varargin)
% Very error prone - change Arduino handling for stability
persistent a x y Rstep Cstep LRwell
switch numel(varargin)
    case 0
        % Currently just passes through normal operation
    case 1
        if ~isempty(varargin{1})
            switch class(varargin{1})
                case 'ARD'
                    a = varargin{1};
                case 'char'
                    switch varargin{1}
                        case 'cal'
                            if ~isempty(a) && isa(a,'ARD')
                                a.fhHome;
                            end
                            x = 0;
                            y = 0;
                        case 'clr'
                            clear rfWell
                        case 'check'
                            disp({a,LRwell,x,y,Rstep,Cstep})
                            assignin('base','rfWellSet',{a,LRwell,x,y,Rstep,Cstep});
                        otherwise
                            disp('rfWell: Not valid input')
                    end
                case 'double'
                    if numel(varargin{1}) == 2
                        LRwell = varargin{1};
                    else
                        disp('rfWell: Not valid input')
                    end
                otherwise
                    disp('rfWell: Not valid input')
            end
        return;
        end
    case 2
        if isa(varargin{1},'double') && isa(varargin{2},'double')
            x = varargin{1};
            y = varargin{2};
        else
            disp('rfWell: Not valid input')
        end
        return;
    case 3
        LRwell = varargin{1};
        Rstep = varargin{2};
        Cstep = varargin{3};
        
        % For 364-well plate close to home w/ P1 as LRwell:
        %   use LRwell = 300,270
        
        % For 364-well plate close to home w/ A1 as LRwell:
        %   use LRwell = 400,150
        
        return;
    otherwise
        disp('rfWell: Not valid input')
        return;
end
if isempty(a)
    a = ARD(3);
    a.fhNoz(1250);
end
if isempty(x)
%     a.fhHome;
    x = 0;
    y = 0;
end
if isempty(LRwell)
    LRwell = [3600,160];
end
if isempty(Rstep)
    Rstep = 180;
    Cstep = 180;
end
Rtarget = (r - 1) * Rstep + LRwell(1);
Ctarget = (c - 1) * Cstep + LRwell(2);
steps = [Rtarget - x,Ctarget - y];
a.fhMove(steps(1),steps(2));
x = Rtarget;
y = Ctarget;