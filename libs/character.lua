local Luafinding   = require("libs.luafinding")
local Util         = require("src.util")
local Character    = {}
local Vector       = require("libs.vector")
Character.__index  = Character

Character.AI_SPEED = 30 -- Set AI speed variable

function Character:new(world, x, y, width, height, image)
    local self = setmetatable({}, Character)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.path = nil
    self.pathIndex = 1
    self.id = nil            -- Add identifier property
    self.targetFruit = nil   -- Add targetFruit property
    self.complaining = false -- Add complaining property
    self.animation = {
        image = love.graphics.newImage("assets/images/guys/whitecollarwalk.png"),
        frameWidth = 16,
        frameHeight = 16,
        currentFrame = 1,
        totalFrames = 4,
        frameDuration = 0.1,
        time = 0
    }
    self.world = world
    if image then
        self.image = image
    end
    return self
end

function Character:updateAnimation(dt)
    self.animation.time = self.animation.time + dt
    if self.animation.time >= self.animation.frameDuration then
        self.animation.time = self.animation.time - self.animation.frameDuration
        self.animation.currentFrame = self.animation.currentFrame % self.animation.totalFrames + 1
    end
end

function Character:chooseNearestFruit()
    if self.targetFruit then return end

    if DEBUG then print(#Fruits .. " fruits available") end

    local nearestFruit = nil
    local nearestDistance = math.huge

    for _, fruit in ipairs(Fruits) do
        local fruitPos = Util.tileToWorldSpace(fruit.x, fruit.y)
        local distance = math.sqrt((self.x - fruitPos.x) ^ 2 + (self.y - fruitPos.y) ^ 2)
        if distance < nearestDistance and not fruit.claimed then
            nearestDistance = distance
            nearestFruit = fruit
        end
    end
    if nearestFruit then
        nearestFruit.claimed = true
        self.targetFruit = nearestFruit
        self.complaining = false -- Reset complaining status
    else
        self:complain()
    end

    if DEBUG then
        self:debugFruitPathing()
    end
end

function Character:complain()
    self.complaining = true -- Set complaining status
end

function Character:debugFruitPathing()
    if self.targetFruit and self.id == #Fruits - 1 then
        local nearestFruitPos = Util.tileToWorldSpace(self.targetFruit.x, self.targetFruit.y)
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
    self:updateAnimation(dt)
end

function Character:draw()
    if self.complaining then
        love.graphics.setColor(1, 0, 0, 0.5) -- Red for complaining with transparency
    elseif self.targetFruit then
        love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for having a target fruit with transparency
    else
        love.graphics.setColor(0, 0, 1, 0.5) -- Blue for no target fruit with transparency
    end

    -- Draw a circle above the AI character's head
    local circleX = self.x + self.width / 2
    local circleY = self.y - self.height / 2
    local circleRadius = self.width * 0.25
    love.graphics.circle("fill", circleX, circleY, circleRadius)

    if self.image then
        love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
        local scaleX = 1
        if self.path and #self.path > 0 then
            local nextStep = self.path[self.pathIndex]
            local targetPos = Util.tileToWorldSpace(nextStep.x, nextStep.y)
            if targetPos.x > self.x then
                scaleX = -1 -- Flip horizontally if moving left
            end
        end
        local frameX = (self.animation.currentFrame - 1) * self.animation.frameWidth
        love.graphics.draw(self.animation.image,
            love.graphics.newQuad(frameX, 0, self.animation.frameWidth, self.animation.frameHeight,
                self.animation.image:getDimensions()), self.x + self.width / 2, self.y, 0,
            scaleX * (self.width / self.animation.frameWidth), self.height / self.animation.frameHeight,
            self.animation.frameWidth / 2, 0)
    else
        love.graphics.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
    end

    if PATH_DEBUG and self.targetFruit then
        love.graphics.setColor(1, 1, 0) -- Reset color to yellow
        love.graphics.print("(" .. self.targetFruit.x .. ", " .. self.targetFruit.y .. ")", self.x - 5,
            self.y + self.height + 3)
    end

    if PATH_DEBUG then
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

    if PATH_DEBUG then
        -- Draw fruit coordinates above their tiles
        for _, fruit in ipairs(Fruits) do
            local fruitPos = Util.tileToWorldSpace(fruit.x, fruit.y)
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("(" .. fruit.x .. ", " .. fruit.y .. ")", fruitPos.x, fruitPos.y - 10)
        end
    end
end

function Character:moveToNextStep(dt)
    if self.targetFruit then
        if not self.path or #self.path == 0 then
            local startPos = Util.worldToTileSpace(self.x, self.y)
            local startY = startPos.y
            local startX = startPos.x
            local endX, endY = self.targetFruit.x, self.targetFruit.y

            -- Define the positionOpenCheck function
            local function positionOpenCheck(pos)
                return self.world:tileIsAliveAtPosition(pos.x, pos.y)
            end

            local pathfinder = Luafinding(Vector(startX, startY), Vector(endX, endY), positionOpenCheck, false)
            self.path = pathfinder:GetPath()
            if PATH_DEBUG and self.path then
                print("Got path for AI " .. self.id .. ": " .. #self.path)
                print(pathfinder:__tostring())
            else
                -- complain because you can't path, if target is on a dead cell
                self:complain()
            end
            self.pathIndex = 1
        end

        if self.path and #self.path > 0 then
            self.complaining = false -- Reset complaining status
            local nextStep = self.path[self.pathIndex]
            local targetPos = Util.tileToWorldSpace(nextStep.x, nextStep.y)
            local directionX = targetPos.x - self.x
            local directionY = targetPos.y - self.y
            local length = math.sqrt(directionX ^ 2 + directionY ^ 2)
            if length > 0 then
                directionX = directionX / length
                directionY = directionY / length
            end

            self.x = self.x + directionX * dt * Character.AI_SPEED
            self.y = self.y + directionY * dt * Character.AI_SPEED

            -- Check if reached the next step
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
        else
            -- If no path, try to find a new path
            self.path = nil
        end
    end
    if PATH_DEBUG then
        self:debugFruitPathing()
    end
end

return Character
