local Vector = require("libs.vector")

local Util = {}

function Util.toVector(coords)
    return Vector(coords.x, coords.y)
end

function Util.tileToWorldSpace(tileX, tileY)
    return {
        x = (tileX - 1) * TILE_SIZE,
        y = (tileY - 1) * TILE_SIZE
    }
end

function Util.worldToTileSpace(worldX, worldY)
    return {
        x = math.floor(worldX / TILE_SIZE) + 1,
        y = math.floor(worldY / TILE_SIZE) + 1
    }
end

function Util.removeEntityAtTile(givenTable, tile_x, tile_y)
    for i = #givenTable, 1, -1 do
        if givenTable[i].x == tile_x and givenTable[i].y == tile_y then
            -- remove the entity from the table if it's position is the targeted position
            if DEBUG then
                print("Removing entity at " .. tile_x .. ", " .. tile_y)
            end
            table.remove(givenTable, i)
        end
    end
end

function Util.isTileAlive(world, x, y)
    return world[x] and world[x][y] and world[x][y].Alive
end

return Util
