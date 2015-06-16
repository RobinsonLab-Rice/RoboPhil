classdef ARD < handle
    %ARD Class for managing connection and communicatino with Arduinos
    %   ARD connects to and communicates with Arduinos over emulated Serial
    %   Written by Benjamin Avants, 2013
    
    properties
        ArduinoSerial
        ArduinoCOM
        Connected
        FigureHandle
        LastResponse
        ListenerFunction
        PinList
    end
    
    methods
        function obj = ARD(ArduinoCOM,varargin)
            existing = Objects.find('ARD',ArduinoCOM);
            if isempty(existing)
                com = ['COM' num2str(ArduinoCOM)];
                obj.ArduinoCOM = ArduinoCOM;
                obj.FigureHandle = 0;
                obj.LastResponse = [];
                obj.ListenerFunction = @obj.ardCallback;
                obj.PinList = [];
                temp = instrfind;
                flag = 0;
                for i = 1:size(temp,2)
                    if strcmp(temp(i).port,com)
                        flag = i;
                    end
                end
                if flag == 0
                    obj.ArduinoSerial = serial(com);
                    if numel(varargin) == 1
                        obj.ArduinoSerial.BaudRate = varargin{1};
                    end
                else
                    obj.ArduinoSerial = temp(flag);
                end
                Objects.add(obj,'ARD',ArduinoCOM); % Enable instance tracking
            else
                obj = existing;
            end
            obj.open();
            %             end
        end
        
        function psEnableAll (obj)
            a = obj.ArduinoSerial;
            fprintf(a,'2a');
        end
        
        function psDisableAll (obj)
            a = obj.ArduinoSerial;
            fprintf(a,'2o');
        end
        
        function psSet (obj,ch1,ch2,ch3)
            a = obj.ArduinoSerial;
            if ch1 == 1
                cmd = 'p';
            else
                cmd = 'n';
            end
            if ch2 == 1
                cmd = [cmd 'p'];
            else
                cmd = [cmd 'n'];
            end
            if ch3 == 1
                cmd = [cmd 'p'];
            else
                cmd = [cmd 'n'];
            end
            
            fprintf(a,['2t' cmd]);
        end
        
        function psSet1 (obj,ch,val)  % ch is a char 'x','y', or 'z'
            a = obj.ArduinoSerial;
            if val == 1
                val = 'p';
            elseif val == 0
                val = 'n';
            else
                disp('Error, unknown input');
            end
            fprintf(a,['2' ch val]);
        end
        
        function magPower (obj)
            obj.send('4p');
        end
        
        function magInit (obj)
            obj.send('4i');
        end
        
        function magStream (obj)
            obj.send('4s');
        end
        
        function magStatus (obj)
            obj.send('4c');
        end
        
        function ledttl (obj)
            obj.send('5');
        end
        
        function fhHome (obj)
            a = obj.ArduinoSerial;
            obj.LastResponse = [];
            fprintf(a,'calibrate()');
        end
        
        function fhMove (obj,x,y)
            a = obj.ArduinoSerial;
            obj.LastResponse = [];
            fprintf(a,['moveSteps(',num2str(x),',',num2str(y),')']);
        end
        
        function fhMoveTo (obj,x,y)
            a = obj.ArduinoSerial;
            obj.LastResponse = [];
            fprintf(a,['moveTo(',num2str(x),',',num2str(y),')']);
        end
        
        function fhNoz (obj,x) % writes useconds of pulsewidth, middle = 1500
            a = obj.ArduinoSerial;
            obj.LastResponse = [];
            fprintf(a,['servoMicros(',num2str(x),')']);
        end
        
        function fhDispense (obj)
            a = obj.ArduinoSerial;
            fprintf(a,'3d');
        end
        
        function hsMoveAll (obj, pos)
            a = obj.ArduinoSerial;
            outstr = '6a';
            for i = 1:length(pos)
                outstr = strcat(outstr, 'x', num2str(pos(i),'%05u'));
            end
            
            fprintf(a,outstr);
        end
        
        function hsMoveOne(obj, mnum, pos)
            a = obj.ArduinoSerial;
            if ~isa(mnum,'char')
                mnum = num2str(mnum);
            end
            outstr = strcat('6e', mnum-1, num2str(pos));
            fprintf(a,outstr);
        end
        
        function hsCalibrate(obj,option)
            a = obj.ArduinoSerial;
            outstr = strcat('6c',num2str(option));
            fprintf(a,outstr);
        end
        
        function pinAdd(obj,pin)
            a = obj.ArduinoSerial;
            cmd = ['7a',num2str(pin)];
            fprintf(a,cmd);
            if ~any(obj.PinList == pin)
                obj.PinList(end+1) = pin;
            end
        end
        
        function pinAddBlock(obj,startPin,numPins)
            a = obj.ArduinoSerial;
            cmd = ['7b',num2str(startPin),num2str(numPins)];
            fprintf(a,cmd);
            for ii = startPin:(startPin + numPins - 1)
                if ~any(obj.PinList == ii)
                    obj.PinList(end+1) = ii;
                end
            end
        end
        
        function pinInit(obj)
            a = obj.ArduinoSerial;
            fprintf(a,'7i');
        end
        
        function pinRemove(obj,pin)
            a = obj.ArduinoSerial;
            cmd = ['7r',num2str(pin)];
            fprintf(a,cmd);
            obj.PinList(obj.PinList == pin) = [];
        end
        
        function pinSwitch(obj,pins)
            a = obj.ArduinoSerial;
            cmd = ['7s',num2str(numel(pins))];
            for ii = 1:numel(pins)
                cmd = [cmd,num2str(pins(ii),'%02i')];
            end
            fprintf(a,cmd);
        end
        
        function pinSet(obj,pin,state)
            a = obj.ArduinoSerial;
            cmd = '7';
            if state == 0
                cmd = [cmd,'l',num2str(pin)];
            else
                cmd = [cmd,'h',num2str(pin)];
            end
            fprintf(a,cmd);
        end
        
        function pinReset(obj)
            a = obj.ArduinoSerial;
            fprintf(a,'7z');
        end
        
        function pinList = pinCheck(obj)
            pinList = obj.PinList;
        end
        
        function PWMPin(obj,pin)
            a = obj.ArduinoSerial;
            cmd = ['8p',num2str(pin)];
            fprintf(a,cmd);
        end
        
        function PWMDC(obj,dutyCycle)
            a = obj.ArduinoSerial;
            cmd = ['8a',num2str(dutyCycle)];
            fprintf(a,cmd);
        end
        
        function PWMstart(obj)
            a = obj.ArduinoSerial;
            cmd = '8b';
            fprintf(a,cmd);
        end
        
        function PWMstop(obj)
            a = obj.ArduinoSerial;
            cmd = '8c';
            fprintf(a,cmd);
        end
        
        function PWMon(obj)
            a = obj.ArduinoSerial;
            cmd = '8h';
            fprintf(a,cmd);
        end
        
        function PWMoff(obj)
            a = obj.ArduinoSerial;
            cmd = '8l';
            fprintf(a,cmd);
        end
        
        function PWMinit(obj)
            a = obj.ArduinoSerial;
            cmd = '8i';
            fprintf(a,cmd);
        end
        
        function close (obj)
            a = obj.ArduinoSerial;
            fclose(a);
        end
        
        function open (obj)
            a = obj.ArduinoSerial;
            set(a,'BytesAvailableFcnMode','terminator');
            set(a,'BytesAvailableFcn',obj.ListenerFunction);
            if strcmp(a.status,'closed')
                try
                    fopen(a);
                    obj.Connected = true;
                catch
                    obj.Connected = false;
                end
            end
        end
        
        function send (obj, command)
            if obj.Connected
                a = obj.ArduinoSerial;
                fprintf(a,command);
            elseif command(1) == '*'
                obj.LastResponse = 'FAIL TO CONNECT';
            end
        end
        
        function ardCallback (obj, o, ~)
            while o.BytesAvailable > 0
                temp = fscanf(o);
                temp = strtrim(temp);
                obj.LastResponse = temp;
                if obj.FigureHandle == 0
                    fprintf([temp,'\n']);
                else
                    set(obj.FigureHandle,'String',temp)
                    cbf = get(obj.FigureHandle,'Callback');
                    if isa(cbf,'function_handle')
                        cbf(obj.FigureHandle,[]);
                    end
                end
            end
        end
        
        function [serial] = serial (obj)
            serial = obj.ArduinoSerial;
        end
        
        function [response] = response (obj)
            response = obj.LastResponse;
        end
        
        function setListener (obj, functionHandle)
            obj.ListenerFunction = functionHandle;
            obj.open();
        end
        
        function [com] = com (obj)
            com = obj.ArduinoSerial.port;
        end
        
        function srs (obj)
            obj.send('r');
        end
        
        function output (obj,handle)
            obj.FigureHandle = handle;
        end
        
        function delete (obj)
            delete(obj.ArduinoSerial);
            Objects.remove(obj);
        end
    end
    
end