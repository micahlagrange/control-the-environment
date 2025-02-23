local Vector = require("libs/vector")

local Util = {}

function Util.toVector(coords)
    return Vector(coords.x, coords.y)
end

function Util.removeEntityAtTile(givenTable, tile_x, tile_y)
    for i = #givenTable, 1, -1 do
        if givenTable[i].x == tile_x and givenTable[i].y == tile_y then
            -- remove the entity from the table if it's position is the targeted position
            table.remove(givenTable, i)
        end
    end
end

return Util