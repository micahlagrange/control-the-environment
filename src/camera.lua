local Util = require("src.util")

local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, scale)
    local self = setmetatable({}, Camera)
    self.x = x or 0
    self.y = y or 0
    self.scale = scale or 1
    return self
end

function Camera:update(dt, targetX, targetY, targetWidth, targetHeight, windowWidth, windowHeight)
    local targetCenterX = targetX + targetWidth / 2
    local targetCenterY = targetY + targetHeight / 2
    self.x = self.x + (targetCenterX - self.x - (windowWidth / 2) / self.scale) * 0.1
    self.y = self.y + (targetCenterY - self.y - (windowHeight / 2) / self.scale) * 0.1
end

function Camera:apply()
    love.graphics.push()
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:reset()
    love.graphics.pop()
end

function Camera:zoom(factor)
    self.scale = self.scale * factor
end

function Camera:toWorldSpace(x, y)
    -- whatever the zoom level, return the world coordinates of the screen coordinates
    return {
        x = x / self.scale + self.x,
        y = y / self.scale + self.y,
    }
end

function Camera:toTileSpace(x, y)
    local worldPos = self:toWorldSpace(x, y)
    return Util.worldToTileSpace(worldPos.x, worldPos.y)
end

return Camera
