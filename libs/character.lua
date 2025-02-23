local Luafinding = require("libs/luafinding")
local Util = require("src/util")
local Character = {}
Character.__index = Character

Character.AI_SPEED = 100 -- Set AI speed variable

function Character:new(x, y, width, height)
    local self = setmetatable({}, Character)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.path = nil
    self.pathIndex = 1
    self.id = nil          -- Add identifier property
    self.targetFruit = nil -- Add targetFruit property
    return self
end

local function tileToWorldSpace(tileX, tileY)
    return {
        x = (tileX - 1) * TILE_SIZE,
        y = (tileY - 1) * TILE_SIZE
    }
end

function Character:chooseNearestFruit()
    local nearestFruit = nil
    local nearestDistance = math.huge

    for _, fruit in ipairs(Fruits) do
        local fruitPos = tileToWorldSpace(fruit.x, fruit.y)
        local distance = math.sqrt((self.x - fruitPos.x) ^ 2 + (self.y - fruitPos.y) ^ 2)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestFruit = fruit
        end
    end
    if DEBUG and self.id == 1 then
        self:debugFruitPathing()
    end
    self.targetFruit = nearestFruit
end

function Character:debugFruitPathing()
    if self.targetFruit then
        local distance = math.sqrt((self.x - self.targetFruit.x) ^ 2 + (self.y - self.targetFruit.y) ^ 2)
        local nearestFruitPos = tileToWorldSpace(self.targetFruit.x, self.targetFruit.y)
        print("ai x = " ..
            self.x ..
            ", y = " ..
            self.y ..
            " -->target x = " ..
            nearestFruitPos.x .. ", y = " .. nearestFruitPos.y .. " distance = " .. distance)
    end
end

function Character:update(dt)
    self:moveToNextStep(dt)
    self:calculatePickupFruit()
end

function Character:calculatePickupFruit()
    if self.targetFruit then
        local targetPos = tileToWorldSpace(self.targetFruit.x, self.targetFruit.y)
        if math.abs(self.x - targetPos.x) < 1 and math.abs(self.y - targetPos.y) < 1 then
            self.targetFruit = nil
            World[self.targetFruit.x][self.targetFruit.y].Alive = false
        end
    end
end

function Character:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
    if DEBUG then self:drawDebug() end
end

function Character:drawDebug()
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function Character:moveToNextStep(dt)
    if self.targetFruit then
        local targetPos = tileToWorldSpace(self.targetFruit.x, self.targetFruit.y)
        local directionX = targetPos.x - self.x
        local directionY = targetPos.y - self.y
        local length = math.sqrt(directionX ^ 2 + directionY ^ 2)
        if length > 0 then
            directionX = directionX / length
            directionY = directionY / length
        end

        self.x = self.x + directionX * dt * Character.AI_SPEED
        self.y = self.y + directionY * dt * Character.AI_SPEED

        if math.abs(self.x - targetPos.x) < 1 and math.abs(self.y - targetPos.y) < 1 then
            Util.removeEntityAtTile(Fruits, self.targetFruit.x, self.targetFruit.y)
            self.targetFruit = nil -- Reached the target
        end
    end
end

return Character
