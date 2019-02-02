function [] = GetBehaviorEvents(filename)

[data, settings, TargetZones, FakeTargetZones] = ExtractSessionDataFixedGain(filename);
[Traces, TrialInfo, TargetZones] = ChunkToTrials(data, TargetZones);
[Odors, ZonesToUse, Traces] = TruncateTrials(Traces, TrialInfo, TargetZones);

end



        