function [] = AlignTrialsToEvent()
% align all trials by trial time start
max_offset = max(cell2mat(cellfun(@min,TrialInfo.StayTimeStart,'UniformOutput',false)'));
Lever_mat(:,end+1:end+max_offset) = NaN; % padding for trial shifting
for i = 1:size(Lever,2)
    if min(TrialInfo.StayTimeStart{i}) < max_offset
        temp_offset = max_offset - min(TrialInfo.StayTimeStart{i});
        Lever_mat(i,:) = circshift(Lever_mat(i,:),[1,temp_offset]);
        Lever_mat(i,1:temp_offset) = NaN;
    end
end
end