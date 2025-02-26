local Util = require("src.util")

local World = {}
World.__index = World

function World:new(tiles, camera)
    local self = setmetatable({}, World)
    self.tiles = tiles
    self.camera = camera
    return self
end

function World:getWorldCoordinatesFromScreen(x, y)
    -- The camera may have moved the world around, so we need to add the camera's offset
    return self.camera:toWorldSpace(x, y)
end

function World:getTileCoordinatesFromScreen(x, y)
    -- The camera may have moved the world around, so we need to add the camera's offset
    local camPos = self:getWorldCoordinatesFromScreen(x, y)
    local tile = Util.worldToTileSpace(camPos.x, camPos.y)
    if DEBUG then
        print("Getting tile... Camera returned x: " .. tile.x .. " Camera y: " .. tile.y)
    end
    return tile
end

function World:breakWallTileAtMouse()
    local uix, uiy = love.mouse.getPosition()
    local tilePos = self:getTileCoordinatesFromScreen(uix, uiy)
    if self.tiles[tilePos.x] and self.tiles[tilePos.y] then
        local tile = self.tiles[tilePos.x][tilePos.y]
        if DEBUG then
            print("setting (alive? " ..
                tostring(tile.Alive) .. ") tile " .. tilePos.x .. ", " .. tilePos.y .. " to alive")
        end
        if not tile.Alive then
            tile.Alive = true
        end
    end
end

function World:breakWallTileAndSurroundingAtMouse()
    local uix, uiy = love.mouse.getPosition()
    local tilePos = self:getTileCoordinatesFromScreen(uix, uiy)
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 }
    }
    if UI_DEBUG then print("explod") end
    for _, offset in ipairs(offsets) do
        local x, y = tilePos.x + offset[1], tilePos.y + offset[2]
        if self.tiles[x] and self.tiles[x][y] then
            local tile = self.tiles[x][y]
            if UI_DEBUG then
                print("explode (alive? " ..
                    tostring(tile.Alive) .. ") tile " .. x .. ", " .. y .. " to alive")
            end
            if not tile.Alive then
                tile.Alive = true
            end
        end
    end
end

function World:tileIsAliveAtPosition(x, y)
    if not self.tiles[x] or not self.tiles[y] then
        return false
    end
    local tile = self.tiles[x][y]
    return tile and tile.Alive
end

function World:drawTileDebugSquares()
    for x, column in pairs(self.tiles) do
        for y, tile in pairs(column) do
            if tile.Alive then
                love.graphics.setColor(0, 1, 0, 0.5) -- Green with transparency
            else
                love.graphics.setColor(1, 0, 0, 0.5) -- Red with transparency
            end
            love.graphics.rectangle("fill", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        end
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

function World:debugClick(x, y)
    local tile = self:getTileCoordinatesFromScreen(x, y)
    if UI_DEBUG then
        local worldPos = self:getWorldCoordinatesFromScreen(x, y)
        print("Clicked tile: " .. tile.x .. ", " .. tile.y .. " world space: " .. worldPos.x .. ", " .. worldPos.y)
    end
end

return World
