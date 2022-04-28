function [Successes] = BootStrappedSuccessRates(AllTrials,PerturbedTrials)

U = unique(PerturbedTrials);

for rounds = 1:20
    indices = [];
    for i = 1:numel(U)
        if any(find(PerturbedTrials==U(i)))
            idx = find(AllTrials(:,2)==U(i));
            % pick trial count matched trials randomly
            indices = [indices randperm(numel(idx),numel(find(PerturbedTrials==U(i))))];
        end
    end
    Successes(rounds) = numel(find(~isnan(AllTrials(indices,1))));
end

Successes = Successes/numel(PerturbedTrials);
end
