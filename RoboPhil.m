function varargout = RoboPhil(varargin)
% ROBOPHIL MATLAB code for RoboPhil.fig
%      ROBOPHIL, by itself, creates a new ROBOPHIL or raises the existing
%      singleton*.
%
%      H = ROBOPHIL returns the handle to a new ROBOPHIL or the handle to
%      the existing singleton*.
%
%      ROBOPHIL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROBOPHIL.M with the given input arguments.
%
%      ROBOPHIL('Property','Value',...) creates a new ROBOPHIL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RoboPhil_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RoboPhil_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RoboPhil

% Last Modified by GUIDE v2.5 18-Jun-2015 15:34:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RoboPhil_OpeningFcn, ...
                   'gui_OutputFcn',  @RoboPhil_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before RoboPhil is made visible.
function RoboPhil_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

if strcmp(get(hObject,'Visible'),'off')
    warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
    
    setappdata(hObject,'wait',1);
    
    available = IDSerialComs;
    a = [];
    for ii = 1:size(available,1)
        if strcmp('Arduino',available{ii,1}(1:7))
            a = ARD(available{ii,2},115200);
            a.output(handles.ArduinoText);
            break;
        end
    end
    if ~isempty(a)
        setappdata(hObject,'Arduino',a);
        set(handles.FindArdMI,'Enable','off');
        set(handles.DisconnectArdMI,'Enable','on');
        set(handles.CalibrateArdMI,'Enable','on');
        setappdata(handles.RoboPhil,'UserSteps',360);
        
        if isempty(varargin)
            plate.cStep = 181;
            plate.rStep = 181;
            plate.LRWell = [335,88];
            plate.numWells = [24,16];
            plate.wellShape = 's';
            plate.up = 1350;
            plate.down = 1165;
        else
            plate = varargin{1};
        end
        
        resp = rfDisp([],a,plate.up,plate.down);
        if isa(resp,'double') && resp == -1
            disp('rfDisp not configured')
            setappdata(hObject,'DispMinWait',[])
        else
            setappdata(hObject,'DispMinWait',1)
        end
        
        set(hObject,'WindowKeyPressFcn',{@KeyManagerKPF,handles});
        
        tic;
        a.fhHome
        
        KeyManagerKPF(hObject,[],handles);
        
        while ~strcmp('Finished',get(handles.ArduinoText,'String'))
            pause(.1)
            if toc > 10
                break;
            end
        end
        
        set(handles.PrecisionToggle,'Background','r','Value',1)
        a.send('precisionOn()');
        
        setappdata(handles.RoboPhil,'plate',plate);
        
        if strcmp('Finished',get(handles.ArduinoText,'String'))
            set(handles.XPosition,'String',num2str(plate.LRWell(1)));
            set(handles.YPosition,'String',num2str(plate.LRWell(2)));
            set(handles.XWell,'String','1');
            set(handles.YWell,'String','1');
            setappdata(hObject,'wait',0);
        else
            disp('Calibration Failed')
        end
        
        rfMove('setup',a,plate.LRWell,plate.rStep,plate.cStep);
        rfMove('w',1,1);
        
        guidata(hObject, handles);
        
        checkPosition(handles)
    else
        setappdata(hObject,'wait',0);
       guidata(hObject, handles); 
    end
end


function KeyManagerKPF(obj,event,h)
persistent XWell YWell XPos YPos WellB PosB
if isempty(XWell)
    XWell = findjobj(h.XWell);
    YWell = findjobj(h.YWell);
    XPos = findjobj(h.XPosition);
    YPos = findjobj(h.YPosition);
    WellB = findjobj(h.MoveWellButton);
    PosB = findjobj(h.MoveToButton);
end
t(1) = XWell.isFocusOwner();
t(2) = YWell.isFocusOwner();
t(3) = XPos.isFocusOwner();
t(4) = YPos.isFocusOwner();
if any(t)
    return;
end
% jFig = get(h.RoboPhil,'JavaFrame');
%jWin = jFig.fHG1Client.getWindow();
if ~ishandle(obj) %|| get(jWin,'Focused') == 0
    return;
end
if getappdata(h.RoboPhil,'wait') == 1
    return;
end

switch event.Key
    case 'leftarrow'
        setappdata(h.RoboPhil,'wait',1);
        cbf = get(h.X1Button,'Callback');
        cbf(h.X1Button,[]);
    case 'rightarrow'
        setappdata(h.RoboPhil,'wait',1);
        cbf = get(h.X2Button,'Callback');
        cbf(h.X2Button,[]);
    case 'uparrow'
        setappdata(h.RoboPhil,'wait',1);
        cbf = get(h.Y1Button,'Callback');
        cbf(h.Y1Button,[]);
    case 'downarrow'
        setappdata(h.RoboPhil,'wait',1);
        cbf = get(h.Y2Button,'Callback');
        cbf(h.Y2Button,[]);
    case 'return'
        if WellB.isFocusOwner()
            MoveWellButton_Callback(h.MoveWellButton,[],h)
        elseif PosB.isFocusOwner()
            MoveToButton_Callback(h.MoveWellButton,[],h)
        else
            return;
        end
    case 'slash'
        DispenseButton_Callback(h.DispenseButton,[],h);
    case 'rightbracket'
        precisionSelect(1,h)
    case 'leftbracket'
        precisionSelect(-1,h)
    case 'comma'
        rfDisp('s',-5);
        pause(0.1)
        disp(rfDisp('c'));
    case 'period'
        rfDisp('s',5);
        pause(0.1)
    otherwise
%         disp(get(h.MoveWellButton,'Selected'))
%         disp(event.Key)
        entry = strcmpi(cellstr(get(h.UserList,'String')),event.Key);
        if any(entry)
            set(h.UserList,'Value',find(entry,1,'first'));
            UserList_Callback(h.UserList,'open',h);
        else
            return;
        end
end


% --- Outputs from this function are returned to the command line.
function varargout = RoboPhil_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



function XPosition_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function XPosition_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YPosition_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function YPosition_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in X1Button.
function X1Button_Callback(hObject, eventdata, handles)
if get(handles.InvertXCB,'Value') == 0
    dir = 1;
else
    dir = -1;
end
StepX(dir,handles)


% --- Executes on button press in X2Button.
function X2Button_Callback(hObject, eventdata, handles)
if get(handles.InvertXCB,'Value') == 0
    dir = -1;
else
    dir = 1;
end
StepX(dir,handles)



function StepX (dir,handles)
pos = str2double(get(handles.XPosition,'String'));
sel = get(get(handles.PrecisionSelect,'SelectedObject'),'Tag');
switch sel
    case 'WellRB'
        plate = getappdata(handles.RoboPhil,'plate');
        steps = plate.rStep * dir;
    case 'Steps100RB'
        steps = 100 * dir;
    case 'Steps10RB'
        steps = 10 * dir;
    case 'Steps1RB'
        steps = 1 * dir;
    case 'StepsUserRB'
        steps = getappdata(handles.RoboPhil,'UserSteps') * dir;
end
set(handles.XPosition,'String',num2str(pos + steps));
set(handles.ArduinoText,'String','');
rfMove('i',steps,0);
pause(.1)
checkPosition(handles)


% --- Executes on button press in Y2Button.
function Y2Button_Callback(hObject, eventdata, handles)
if get(handles.InvertYCB,'Value') == 0
    dir = -1;
else
    dir = 1;
end
StepY(dir,handles)


% --- Executes on button press in Y1Button.
function Y1Button_Callback(hObject, eventdata, handles)
if get(handles.InvertYCB,'Value') == 0
    dir = 1;
else
    dir = -1;
end
StepY(dir,handles)



function StepY (dir,handles)
pos = str2double(get(handles.YPosition,'String'));
sel = get(get(handles.PrecisionSelect,'SelectedObject'),'Tag');
switch sel
    case 'WellRB'
        plate = getappdata(handles.RoboPhil,'plate');
        steps = plate.cStep * dir;
    case 'Steps100RB'
        steps = 100 * dir;
    case 'Steps10RB'
        steps = 10 * dir;
    case 'Steps1RB'
        steps = 1 * dir;
    case 'StepsUserRB'
        steps = getappdata(handles.RoboPhil,'UserSteps') * dir;
end
set(handles.YPosition,'String',num2str(pos + steps));
set(handles.ArduinoText,'String','');
rfMove('i',0,steps);
checkPosition(handles)



function checkPosition (handles)
a = getappdata(handles.output,'Arduino');
if isempty(a)
    return;
end
tic
plate = getappdata(handles.RoboPhil,'plate');
while ~strcmp('Done',get(handles.ArduinoText,'String'))
    resp = get(handles.ArduinoText,'String');
    if numel(resp) > 3 && strcmp('Arm',resp(1:3))
        break;
    end
    if toc > 10
        break;
    end
    pause(.1)
end
set(handles.ArduinoText,'String','');
a.send('check()');
while strcmp('',get(handles.ArduinoText,'String'))
    pause(.1)
end
resp = get(handles.ArduinoText,'String');
start = find(resp == ':');
comma = find(resp == ',');
x = resp(start+1:comma-1);
y = resp(comma+1:end);
set(handles.XPosition,'String',x);
set(handles.YPosition,'String',y);
xpos = str2double(x);
xwell = (xpos - plate.LRWell(1)) / plate.rStep + 1;
if xwell == round(xwell)
    xwellStr = num2str(xwell);
else
    xwellStr = ['~ ',num2str(round(xwell))];
end
ypos = str2double(y);
ywell = (ypos - plate.LRWell(2)) / plate.cStep + 1;
if ywell == round(ywell)
    ywellStr = num2str(ywell);
else
    ywellStr = ['~ ',num2str(round(ywell))];
end
set(handles.XWell,'String',xwellStr);
set(handles.YWell,'String',ywellStr);
setappdata(handles.RoboPhil,'wait',0);


% --- Executes on button press in InvertXCB.
function InvertXCB_Callback(hObject, eventdata, handles)


% --- Executes on button press in InvertYCB.
function InvertYCB_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function ArduinoMain_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function FindArdMI_Callback(hObject, eventdata, handles)
available = IDSerialComs;
a = [];
for ii = 1:size(available,1)
    if strcmp('Arduino',available{ii,1}(1:7))
        a = ARD(available{ii,2});
        a.output(handles.ArduinoText);
        break;
    end
end
if ~isempty(a)
    setappdata(handles.RoboPhil,'Arduino',a);
    rfMove('setup',a);
    set(hObject,'Enable','off');
    set(handles.DisconnectArdMI,'Enable','on');
    set(handles.CalibrateArdMI,'Enable','on');
end


% --------------------------------------------------------------------
function DisconnectArdMI_Callback(hObject, eventdata, handles)
a = getappdata(handles.RoboPhil,'Arduino');
if ~isempty(a) && isa(a,'ARD')
    a.delete;
    set(hObject,'Enable','off');
    set(handles.CalibrateArdMI,'Enable','off');
    set(handles.FindArdMI,'Enable','on');
    setappdata(handles.RoboPhil,'Arduino',[]);
end


% --------------------------------------------------------------------
function CalibrateArdMI_Callback(hObject, eventdata, handles)
a = getappdata(handles.RoboPhil,'Arduino');
if ~isempty(a) && isa(a,'ARD')
    a.fhHome;
    while ~strcmp('Finished',get(handles.ArduinoText,'String'))
        pause(.1)
    end
    rfMove('w',1,1);
    checkPosition(handles);
end


% --------------------------------------------------------------------
function PlateMain_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function SetLRWPosMI_Callback(hObject, eventdata, handles)
plate = getappdata(handles.RoboPhil,'plate');
resp = inputdlg('Enter Position of Well 1,1 in X,Y notation:', ...
    'RoboPhil: Plate',[1,50]);
resp = resp{1};
comma = find(resp == ',');
if isempty(comma)
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
xWell = str2double(resp(1:comma-1));
yWell = str2double(resp(comma+1:end));
if isnan(xWell) || isnan(yWell) || xWell < 0 || yWell < 0
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
plate.LRWell = [xWell,yWell];
setappdata(handles.RoboPhil,'plate',plate);
rfMove('setup',plate.LRWell);


% --------------------------------------------------------------------
function RowStepsMI_Callback(hObject, eventdata, handles)
plate = getappdata(handles.RoboPhil,'plate');
resp = str2double(inputdlg('Enter the Number of Steps between Wells in X:', ...
    'RoboPhil: Plate',[1,50]));
if isnan(resp) || resp < 0
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
plate.rStep = resp;
setappdata(handles.RoboPhil,'plate',plate);
rfMove('setup',plate.rStep,plate.cStep);


% --------------------------------------------------------------------
function ColStepsMI_Callback(hObject, eventdata, handles)
plate = getappdata(handles.RoboPhil,'plate');
resp = str2double(inputdlg('Enter the Number of Steps between Wells in Y:', ...
    'RoboPhil: Plate',[1,50]));
if isnan(resp) || resp < 0
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
plate.cStep = resp;
setappdata(handles.RoboPhil,'plate',plate);
rfMove('setup',plate.rStep,plate.cStep);


% --- Executes when user attempts to close RoboPhil.
function RoboPhil_CloseRequestFcn(hObject, eventdata, handles)
a = getappdata(handles.output,'Arduino');
if isa(a,'ARD')
    a.delete;
end
while getappdata(handles.RoboPhil,'wait') == 1
    pause(0.1);
end
clear rfDisp rfWell RoboPhil
close(findall(0,'Tag','RoboPhilPlate'));
delete(hObject);


% --- Executes on button press in MoveToButton.
function MoveToButton_Callback(hObject, eventdata, handles)
xwell = round(str2double(get(handles.XPosition,'String')));
ywell = round(str2double(get(handles.YPosition,'String')));
if isnan(xwell) || isnan(ywell)
    return;
end
if getappdata(handles.RoboPhil,'wait') == 1
    return;
end
setappdata(handles.RoboPhil,'wait',1);
set(handles.ArduinoText,'String','');
rfMove('s',xwell,ywell);
checkPosition(handles);



function XWell_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function XWell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YWell_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function YWell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MoveWellButton.
function MoveWellButton_Callback(hObject, eventdata, handles)
xwell = round(str2double(get(handles.XWell,'String')));
ywell = round(str2double(get(handles.YWell,'String')));
if isnan(xwell) || isnan(ywell)
    return;
end
if getappdata(handles.RoboPhil,'wait') == 1
    return;
end
setappdata(handles.RoboPhil,'wait',1);
set(handles.ArduinoText,'String','');
rfMove('w',xwell,ywell);
checkPosition(handles);


% --- Executes on button press in DispenseButton.
function DispenseButton_Callback(hObject, eventdata, handles)
setappdata(handles.RoboPhil,'wait',1);
code = rfDisp(getappdata(handles.RoboPhil,'DispMinWait'));
if code == 1
    setappdata(handles.RoboPhil,'wait',0);
end


% --- Executes when selected object is changed in PrecisionSelect.
function PrecisionSelect_SelectionChangeFcn(hObject, eventdata, handles)
if hObject == handles.StepsUserRB
    set(handles.UserStepsEdit,'Enable','on');
else
    set(handles.UserStepsEdit,'Enable','off');
end



function precisionSelect (direction,handles)
sel = get(get(handles.PrecisionSelect,'SelectedObject'),'Tag');
switch sel
    case 'WellRB'
        if direction == 1
            next = handles.Steps100RB;
        else
            next = handles.StepsUserRB;
            set(handles.UserStepsEdit,'Enable','on');
        end
    case 'Steps100RB'
        if direction == 1
            next = handles.Steps10RB;
        else
            next = handles.WellRB;
        end
    case 'Steps10RB'
        if direction == 1
            next = handles.Steps1RB;
        else
            next = handles.Steps100RB;
        end
    case 'Steps1RB'
        if direction == 1
            next = handles.StepsUserRB;
            set(handles.UserStepsEdit,'Enable','on');
        else
            next = handles.Steps10RB;
        end
    case 'StepsUserRB'
        set(handles.UserStepsEdit,'Enable','off');
        if direction == 1
            next = handles.WellRB;
        else
            next = handles.Steps1RB;
        end
end
set(next,'Value',1);


% --- Executes on button press in PrecisionToggle.
function PrecisionToggle_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1
    set(hObject,'Background','r')
    a = getappdata(handles.RoboPhil,'Arduino');
    a.send('precisionOn()');
else
    set(hObject,'Background',[.941,.941,.941])
    a = getappdata(handles.RoboPhil,'Arduino');
    a.send('precisionOff()');
end


% --------------------------------------------------------------------
function TipControlMain_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function DispenseMinWaitMI_Callback(hObject, eventdata, handles)
resp = str2double(inputdlg('Enter Minimum Wait Time in Seconds:', ...
    'RoboPhil: Tip Control',[1,50]));
if isempty(resp) || isnan(resp) || resp < 0 || resp > 60
    warndlg('Invalid Wait Time Entry','RoboPhil: Tip Control');
    return;
end
setappdata(handles.RoboPhil,'DispMinWait',resp);
% %wait = getappdata(hObject,'DispMinWait');
% wait = resp;
% up = getappdata(handles.RoboPhil,'DispUpPos');
% down = getappdata(handles.RoboPhil'DispDownPos');
% rfDisp(wait,up,down);
return;


% --------------------------------------------------------------------
function UpPositionMI_Callback(hObject, eventdata, handles)
resp = str2double(inputdlg('Enter "Up" Position in Percent (max UP = 100.0):', ...
    'RoboPhil: Tip Control',[1,70]));
if isempty(resp) || isnan(resp) || resp < 0 || resp > 100
    warndlg('Invalid Up Position Entry','RoboPhil: Tip Control');
    return;
end
plate = getappdata(handles.RoboPhil,'plate');
plate.up = round((resp * 10) + 1000);
setappdata(handles.RoboPhil,'plate',plate);
rfDisp([],plate.up,plate.down);


% --------------------------------------------------------------------
function DownPositionMI_Callback(hObject, eventdata, handles)
resp = str2double(inputdlg('Enter "Down" Position in Percent (min DOWN = 00.0):', ...
    'RoboPhil: Tip Control',[1,70]));
if isempty(resp) || isnan(resp) || resp < 0 || resp > 100
    warndlg('Invalid Down Position Entry','RoboPhil: Tip Control');
    return;
end
plate = getappdata(handles.RoboPhil,'plate');
plate.down = round((resp * 10) + 1000);
setappdata(handles.RoboPhil,'plate',plate);
rfDisp([],plate.up,plate.down);


% --------------------------------------------------------------------
function NumberOfWellsMI_Callback(hObject, eventdata, handles)
plate = getappdata(handles.RoboPhil,'plate');
resp = inputdlg('Enter Number of Wells in X,Y notation:', ...
    'RoboPhil: Plate',[1,50]);
resp = resp{1};
comma = find(resp == ',');
if isempty(comma)
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
xWell = str2double(resp(1:comma-1));
yWell = str2double(resp(comma+1:end));
if isnan(xWell) || isnan(yWell) || xWell < 0 || yWell < 0
    warndlg('Invalid Well Entry','RoboPhil: Plate');
    return;
end
plate.numWells = [xWell,yWell];
setappdata(handles.RoboPhil,'plate',plate);
plateFig = findall(0,'Tag','RoboPhilPlate');
if ~isempty(plateFig)
    pos = get(plateFig,'Position');
    close(plateFig);
    PlateInterfaceMI_Callback([],[],handles);
    plateFig = findall(0,'Tag','RoboPhilPlate');
    pos2 = get(plateFig,'Position');
    pos2(1) = pos(1);
    pos2(2) = pos(2) + pos(4) - pos2(4);
    set(plateFig,'Position',pos2);
end


% --------------------------------------------------------------------
function WellShapeMI_Callback(hObject, ~, handles)
plate = getappdata(handles.RoboPhil,'plate');
resp = questdlg('Select Well Shape','RoboPhil: Plate','Square','Circle','Cancel', ...
    'Square');
switch resp
    case 'Square'
        plate.wellShape = 's';
    case 'Circle'
        plate.wellShape = 'c';
    case 'Cancel'
        return;
end
setappdata(handles.RoboPhil,'plate',plate);
plateFig = findall(0,'Tag','RoboPhilPlate');
if ~isempty(plateFig)
    pos = get(plateFig,'Position');
    close(plateFig);
    PlateInterfaceMI_Callback([],[],handles);
    plateFig = findall(0,'Tag','RoboPhilPlate');
    pos2 = get(plateFig,'Position');
    pos2(1) = pos(1);
    pos2(2) = pos(2) + pos(4) - pos2(4);
    set(plateFig,'Position',pos2);
end


% --------------------------------------------------------------------
function PlateInterfaceMI_Callback(hObject, eventdata, handles)
plate = getappdata(handles.RoboPhil,'plate');
f = figure('IntegerHandle','off','NumberTitle','off','Visible','off', ...
    'MenuBar','none','Name','RoboPhil: Plate','Units','Pixels', ...
    'WindowKeyPressFcn',{@KeyManagerKPF,handles},'Tag','RoboPhilPlate');
pos = get(f,'Position');
numX = plate.numWells(1);
minX = 5 * numX;
if pos(3) < minX
    pos(3) = minX;
end
numY = plate.numWells(2);
minY = 5 * numY;
if pos(4) < minY
    pos(2) = pos(2) - (minY - pos(4));
    pos(4) = minY;
end
set(f,'Position',pos,'Units','normalized');
a = axes('Parent',f,'Units','normalized','Position',[0,0,1,1],'XTick',[],'YTick',[]);
switch plate.wellShape
    case 's'
        curve = [0,0];
    case 'c'
        curve = [1,1];
end
for ii = 1:numX
    for jj = 1:numY
        rectangle('Parent',a,'Position',[(numX-ii)/numX,(jj-1)/numY,1/numX,1/numY],...
            'UserData',[ii,jj,numX,numY],'FaceColor','g','ButtonDownFcn',@WellBDF, ...
            'Curvature',curve);
    end
end
set(f,'Visible','on')



function WellBDF (obj,~)
persistent RoboPhil XWell YWell h moveFcn
if isempty(RoboPhil) || ~ishandle(RoboPhil)
    RoboPhil = findall(0,'Tag','RoboPhil');
    XWell = [];
    YWell = [];
    moveFcn = [];
    h = [];
    if isempty(RoboPhil)
        return;
    end
end
if isempty(XWell)
    h = guidata(RoboPhil);
    XWell = h.XWell;
    YWell = h.YWell;
    moveButton = h.MoveWellButton;
    moveFcn = get(moveButton,'Callback');
end
if getappdata(RoboPhil,'wait') == 1
    return;
end
color = get(obj,'FaceColor');
if color(2) == 1
    set(obj,'FaceColor',[0.5,0,0]);
    ID = get(obj,'UserData');
    if get(h.InvertXCB,'Value') == 1
        xStr = num2str(ID(3) + 1 - ID(1));
    else
        xStr = num2str(ID(1));
    end
    if get(h.InvertYCB,'Value') == 1
        yStr = num2str(ID(4) + 1 - ID(2));
    else
        yStr = num2str(ID(2));
    end
    set(XWell,'String',xStr);
    set(YWell,'String',yStr);
    moveFcn(h.MoveWellButton,[]);
    while getappdata(RoboPhil,'wait') == 1
        pause(0.1)
    end
    set(obj,'FaceColor',[1,0,1]);
else
    set(obj,'FaceColor','g');
end



function UserStepsEdit_Callback(hObject, eventdata, handles)
steps = str2double(get(hObject,'String'));
if isnan(steps) || steps < 0 || steps > 3500
    steps = num2str(getappdata(handles.RoboPhil,'UserSteps'));
    set(hObject,'String',steps);
else
    setappdata(handles.RoboPhil,'UserSteps',steps);
end


% --- Executes on selection change in UserList.
function UserList_Callback(hObject, eventdata, handles)
if isempty(eventdata)
    selType = get(handles.RoboPhil,'SelectionType');
else
    selType = eventdata;
end
UD = get(hObject,'UserData');
sel = get(hObject,'Value');
list = cellstr(get(hObject,'String'));
switch selType
    case 'open'
        set(handles.XPosition,'String',num2str(UD{sel,2}(1)));
        set(handles.YPosition,'String',num2str(UD{sel,2}(2)));
        MoveToButton_Callback(handles.MoveToButton,[],handles);
    case 'normal'
        return;
    case 'alt'
        resp = questdlg(['Delete User Position "',UD{sel,1},'"?'], ...
            'RoboFlow: User Position');
        if strcmp(resp,'Yes')
            list(sel) = [];
            UD(sel,:) = [];
            if isempty(list)
                list = {''};
            end
            if sel > numel(list)
                sel = numel(list);
            end
            set(handles.UserList,'String',list,'Value',sel,'UserData',UD);
        end
    otherwise
        return;
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over UserList.
function UserList_ButtonDownFcn(hObject, eventdata, handles)
if isempty(eventdata)
    selType = get(handles.RoboPhil,'SelectionType');
else
    selType = eventdata;
end
UD = get(hObject,'UserData');
sel = get(hObject,'Value');
list = cellstr(get(hObject,'String'));
switch selType
    case 'open'
        set(handles.XPosition,'String',num2str(UD{sel,2}(1)));
        set(handles.YPosition,'String',num2str(UD{sel,2}(2)));
        MoveToButton_Callback(handles.MoveToButton,[],handles);
    case 'normal'
        return;
    case 'alt'
        resp = questdlg(['Delete User Position "',UD{sel,1},'"?'], ...
            'RoboFlow: User Position');
        if strcmp(resp,'Yes')
            list(sel) = [];
            UD(sel,:) = [];
            if isempty(list)
                list = {''};
            end
            if sel > numel(list)
                sel = numel(list);
            end
            set(handles.UserList,'String',list,'Value',sel,'UserData',UD);
        end
    otherwise
        return;
end


% --- Executes during object creation, after setting all properties.
function UserList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AddPositionButton.
function AddPositionButton_Callback(hObject, eventdata, handles)
temp = str2double(get(handles.XPosition,'String'));
if isempty(temp) || isnan(temp)
    return;
end
pos(1) = temp;
temp = str2double(get(handles.YPosition,'String'));
if isempty(temp) || isnan(temp)
    return;
end
pos(2) = temp;
resp = inputdlg('Please enter a Letter for this position', ...
    'RoboPhil: User Position',[1,50]);
if isempty(resp) || isempty(resp{1}) || numel(resp{1}) ~= 1
    warndlg('Not a valid entry','RoboPhil: User Position');
    return;
end
list = cellstr(get(handles.UserList,'String'));
UD = get(handles.UserList,'UserData');
if isempty(list) || isempty(list{1})
    list = resp;
    UD = {resp{1},pos};
else
    list{end+1} = resp{1};
    UD = [UD;{resp{1},pos}];
end
set(handles.UserList,'String',list,'UserData',UD);






