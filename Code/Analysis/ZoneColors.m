function [rgb] = ZoneColors(code)

switch code
    case 1
        rgb=[44 127 184]/256;
    case 2
        rgb=[127 205 187]./256;
    case 3%purple light
        rgb=[237 248 177]./256;
    case 4%purple dark
        rgb=[173 127 168]./256;
    case 5%orange
        rgb=[245 121 0]./256;
    case 6%red
        rgb=[239 41 41]./256;
    case 7%turquize
        rgb=[0 139 139]./256;
    case 8%pink
        rgb=[199 21 133]./256;
end
end