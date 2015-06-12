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

% Last Modified by GUIDE v2.5 11-Jun-2015 17:29:43

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
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RoboPhil (see VARARGIN)

% Choose default command line output for RoboPhil
handles.output = hObject;

warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame

setappdata(hObject,'wait',1);

set(hObject,'WindowKeyPressFcn',{@KeyManagerKPF,handles});

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
    setappdata(hObject,'Arduino',a);
    set(handles.FindArdMI,'Enable','off');
    set(handles.DisconnectArdMI,'Enable','on');
    set(handles.CalibrateArdMI,'Enable','on');
    
    a.fhHome
    pause(1)
    
    % rfWell([],[],a)
    % rfWell([],[],[400,150],180,180)
    % rfWell([],[],'cal')
    rfMove('setup',a,[400,150],180,180);
    rfMove('w',1,1);
    tic;
    while ~strcmp('Finished',get(handles.ArduinoText,'String'))
        pause(.1)
        if toc > 10
            break;
        end
    end
    if strcmp('Finished',get(handles.ArduinoText,'String'))
        set(handles.XPosition,'String','400');
        set(handles.YPosition,'String','150');
        set(handles.XWell,'String','1');
        set(handles.YWell,'String','1');
        setappdata(hObject,'wait',0);
    else
        disp('Calibration Failed')
    end
    
    resp = rfDisp([],a,1155,1155);
    if isa(resp,'double') && resp == -1
        disp('rfDisp not configured')
    end
else
    
end
% UIWAIT makes RoboPhil wait for user response (see UIRESUME)
% uiwait(handles.RoboPhil);

% Update handles structure
guidata(hObject, handles);


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
jFig = get(h.RoboPhil,'JavaFrame');
jWin = jFig.fHG1Client.getWindow();
if ~ishandle(obj) || get(jWin,'Focused') == 0
    return;
end
if getappdata(h.RoboPhil,'wait') == 1
    return;
end
% assignin('base','h',h)
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
    otherwise
        disp(get(h.MoveWellButton,'Selected'))
        disp(event.Key)
end


% --- Outputs from this function are returned to the command line.
function varargout = RoboPhil_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function XPosition_Callback(hObject, eventdata, handles)
% hObject    handle to XPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XPosition as text
%        str2double(get(hObject,'String')) returns contents of XPosition as a double


% --- Executes during object creation, after setting all properties.
function XPosition_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YPosition_Callback(hObject, eventdata, handles)
% hObject    handle to YPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YPosition as text
%        str2double(get(hObject,'String')) returns contents of YPosition as a double


% --- Executes during object creation, after setting all properties.
function YPosition_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in X1Button.
function X1Button_Callback(hObject, eventdata, handles)
% hObject    handle to X1Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.InvertXCB,'Value') == 0
    dir = 1;
else
    dir = -1;
end
StepX(dir,handles)


% --- Executes on button press in X2Button.
function X2Button_Callback(hObject, eventdata, handles)
% hObject    handle to X2Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
        steps = 180 * dir;
    case 'Steps100RB'
        steps = 100 * dir;
    case 'Steps10RB'
        steps = 10 * dir;
    case 'Steps1RB'
        steps = dir;
end
set(handles.XPosition,'String',num2str(pos + steps));
set(handles.ArduinoText,'String','');
rfMove('i',steps,0);
% if dir == 1
%     disp('Left')
% else
%     disp('Right')
% end
pause(.1)
checkPosition(handles)


% --- Executes on button press in Y2Button.
function Y2Button_Callback(hObject, eventdata, handles)
% hObject    handle to Y2Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.InvertYCB,'Value') == 0
    dir = -1;
else
    dir = 1;
end
StepY(dir,handles)

% --- Executes on button press in Y1Button.
function Y1Button_Callback(hObject, eventdata, handles)
% hObject    handle to Y1Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
        steps = 180 * dir;
    case 'Steps100RB'
        steps = 100 * dir;
    case 'Steps10RB'
        steps = 10 * dir;
    case 'Steps1RB'
        steps = dir;
end
set(handles.YPosition,'String',num2str(pos + steps));
set(handles.ArduinoText,'String','');
rfMove('i',0,steps);
% if dir == 1
%     disp('Up')
% else
%     disp('Down')
% end
% pause(.1)
checkPosition(handles)


function checkPosition (handles)
a = getappdata(handles.output,'Arduino');
if isempty(a)
    return;
end
tic
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
xwell = (xpos - 400) / 180 + 1;
if xwell == round(xwell)
    xwellStr = num2str(xwell);
else
    xwellStr = ['~ ',num2str(round(xwell))];
end
ypos = str2double(y);
ywell = (ypos - 150) / 180 + 1;
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
% hObject    handle to InvertXCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InvertXCB


% --- Executes on button press in InvertYCB.
function InvertYCB_Callback(hObject, eventdata, handles)
% hObject    handle to InvertYCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InvertYCB


% --------------------------------------------------------------------
function ArduinoMain_Callback(hObject, eventdata, handles)
% hObject    handle to ArduinoMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function FindArdMI_Callback(hObject, eventdata, handles)
% hObject    handle to FindArdMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
% hObject    handle to DisconnectArdMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
% hObject    handle to CalibrateArdMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
% hObject    handle to PlateMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SetLRWPosMI_Callback(hObject, eventdata, handles)
% hObject    handle to SetLRWPosMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function RowStepsMI_Callback(hObject, eventdata, handles)
% hObject    handle to RowStepsMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ColStepsMI_Callback(hObject, eventdata, handles)
% hObject    handle to ColStepsMI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close RoboPhil.
function RoboPhil_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to RoboPhil (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear rfDisp rfWell RoboPhil
a = getappdata(handles.output,'Arduino');
if isa(a,'ARD')
    a.delete;
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in MoveToButton.
function MoveToButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveToButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
% hObject    handle to XWell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XWell as text
%        str2double(get(hObject,'String')) returns contents of XWell as a double


% --- Executes during object creation, after setting all properties.
function XWell_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XWell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YWell_Callback(hObject, eventdata, handles)
% hObject    handle to YWell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YWell as text
%        str2double(get(hObject,'String')) returns contents of YWell as a double


% --- Executes during object creation, after setting all properties.
function YWell_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YWell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MoveWellButton.
function MoveWellButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveWellButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
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
% hObject    handle to DispenseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
