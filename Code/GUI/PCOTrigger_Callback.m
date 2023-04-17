function PCOTrigger_Callback(h)
h.Arduino.write(41,'uint16');
guidata(h.hObject, h);
% testing