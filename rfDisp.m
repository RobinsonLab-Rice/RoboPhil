function finished = rfDisp (waitT,varargin)
persistent a up down current
switch numel(varargin)
    case 0
        % Do Nothing, pass through switch case
    case 1
        if isa(varargin{1},'ARD')
            a = varargin{1};
            finished = 'Arduino Set';
            return;
        else
            disp('rfDisp: Not a valid command')
            finished = -1;
            return;
        end
    case 2
        if isa(varargin{1},'double') && isa(varargin{2},'double')
            up = varargin{1};
            down = varargin{2};
            finished = 'Up and Down Set';
            return;
        else
            disp('rfDisp: Not a valid command')
            finished = -1;
            return;
        end
    case 3
        if isa(varargin{1},'ARD') && isa(varargin{2},'double') && isa(varargin{3},'double')
            a = varargin{1};
            up = varargin{2};
            down = varargin{3};
            finished = 'All parameters Set';
            return;
        else
            disp('rfDisp: Not a valid command')
            finished = -1;
            return;
        end
    otherwise
        disp('rfDisp: Not a valid command')
        finished = -1;
        return;
end
if isempty(a)
    a = ARD(3);
end
if isempty(up) || isempty(down)
    up = 1500;
    down = 1150;
end
if isempty(current)
    current = 1500;
end
for ii = flip(down:25:current)
    a.fhNoz(ii)
    pause(.05)
end
% a.fhNoz(down + 50)
% pause(.3)
% a.fhNoz(down);
pause(waitT);
a.fhNoz(up);
current = up;
finished = 1;