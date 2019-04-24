[MyData, ~, ~, ~] = ExtractTracesAndEvents(MyFilePath);
[Traces, CamA, CamB, TrialInfo] = ParseTrialsVideoSync(MyData);
clear MyData
