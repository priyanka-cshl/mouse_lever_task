% column names in MyData
function [myzone, TargetZones] = WhichZones(myvalue,mycase)

TargetZones = [ 1.3000    1.0000    0.7000
                1.5500    1.2500    0.9500
                1.8000    1.5000    1.2000
                2.0500    1.7500    1.4500
                2.3000    2.0000    1.7000
                2.5500    2.2500    1.9500
                2.8000    2.5000    2.2000
                3.0500    2.7500    2.4500
                3.3000    3.0000    2.7000
                3.5500    3.2500    2.9500
                3.8000    3.5000    3.2000
                4.0500    3.7500    3.4500];

switch mycase
    case 'low'
        myzone = find(TargetZones(:,3)==myvalue);
    case 'target'
        myzone = find(TargetZones(:,2)==myvalue);
    case 'high'
        myzone = find(TargetZones(:,1)==myvalue);
    otherwise
        myzone = [];
end

end
