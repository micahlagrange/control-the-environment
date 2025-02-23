local Luafinding   = require("libs/luafinding")
local Util         = require("src/util")
local Character    = {}
local Vector       = require("libs/vector")
Character.__index  = Character

Character.AI_SPEED = 30 -- Set AI speed variable

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
    if self.targetFruit then return end

    print(#Fruits .. " fruits available")

    local nearestFruit = nil
    local nearestDistance = math.huge

    for _, fruit in ipairs(Fruits) do
        local fruitPos = tileToWorldSpace(fruit.x, fruit.y)
        local distance = math.sqrt((self.x - fruitPos.x) ^ 2 + (self.y - fruitPos.y) ^ 2)
        if distance < nearestDistance and not fruit.claimed then
            nearestDistance = distance
            nearestFruit = fruit
        end
    end
    if nearestFruit then
        nearestFruit.claimed = true
        self.targetFruit = nearestFruit
    else
        self:complain()
    end
    if DEBUG then
        self:debugFruitPathing()
    end
end

function Character:complain()
    print("AI " .. self.id .. " is complaining!")
end

function Character:debugFruitPathing()
    if self.targetFruit and self.id == #Fruits - 1 then
        local nearestFruitPos = tileToWorldSpace(self.targetFruit.x, self.targetFruit.y)
        local distance = math.sqrt((self.x - nearestFruitPos.x) ^ 2 + (self.y - nearestFruitPos.y) ^ 2)
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

function Character:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)

    if DEBUG then
        -- Convert coordinates to tile space
        local tileX = math.floor(self.x / TILE_SIZE) + 1
        local tileY = math.floor(self.y / TILE_SIZE) + 1
        -- Draw coordinates above the tile
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("(" .. tileX .. ", " .. tileY .. ")", self.x, self.y - 10)
    end

    if DEBUG then self:drawDebug() end
end

function Character:drawDebug()
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    if DEBUG then
        -- Draw fruit coordinates above their tiles
        for _, fruit in ipairs(Fruits) do
            local fruitPos = tileToWorldSpace(fruit.x, fruit.y)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("(" .. fruit.x .. ", " .. fruit.y .. ")", fruitPos.x, fruitPos.y - 10)
        end
    end
end

function Character:calculatePickupFruit()
    if self.path and #self.path > 0 then
        local nextStep = self.path[self.pathIndex]
        local targetPos = tileToWorldSpace(nextStep.x, nextStep.y)
        if math.abs(self.x - targetPos.x) < 1 and math.abs(self.y - targetPos.y) < 1 then
            self.pathIndex = self.pathIndex + 1
            if self.pathIndex > #self.path then
                -- Reached the target
                if self.targetFruit then
                    print("Reached target fruit at " .. self.targetFruit.x .. ", " .. self.targetFruit.y)
                    Util.removeEntityAtTile(Fruits, self.targetFruit.x, self.targetFruit.y)
                    self.targetFruit = nil
                    self.path = nil
                end
            end
        end
    end
end

function Character:moveToNextStep(dt)
    if self.targetFruit then
        if not self.path or #self.path == 0 then
            local startX, startY = math.floor(self.x / TILE_SIZE) + 1, math.floor(self.y / TILE_SIZE) + 1
            local endX, endY = self.targetFruit.x, self.targetFruit.y
            local pathfinder = Luafinding(Vector(startX, startY), Vector(endX, endY), World, false)
            self.path = pathfinder:GetPath()
            if DEBUG then
                print("Got path for AI " .. self.id .. ": " .. #self.path)
            end
            self.pathIndex = 1
        end

        if self.path and #self.path > 0 then
            local nextStep = self.path[self.pathIndex]
            local targetPos = tileToWorldSpace(nextStep.x, nextStep.y)
            local directionX = targetPos.x - self.x
            local directionY = targetPos.y - self.y
            local length = math.sqrt(directionX ^ 2 + directionY ^ 2)
            if length > 0 then
                directionX = directionX / length
                directionY = directionY / length
            end

            self.x = self.x + directionX * dt * Character.AI_SPEED
            self.y = self.y + directionY * dt * Character.AI_SPEED
        end
    end
    if DEBUG then
        self:debugFruitPathing()
    end
end

return Character
