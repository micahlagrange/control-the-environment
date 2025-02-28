local Luafinding         = require("libs.luafinding")
local Util               = require("src.util")
local Audio              = require("src.audio")
local Character          = {}
local Vector             = require("libs.vector")
Character.__index        = Character

Character.AI_SPEED       = 50 -- Set AI speed variable

local walkLeftRightImage = love.graphics.newImage("assets/images/guys/whitecollarwalk.png")
local walkUpImage        = love.graphics.newImage("assets/images/guys/upwalk.png")
local walkDownImage      = love.graphics.newImage("assets/images/guys/downwalk.png")

function Character:new(world, x, y, width, height, scoring)
    local self = setmetatable({}, Character)

    self.scoring = scoring

    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.path = nil
    self.pathIndex = 1
    self.id = nil            -- Add identifier property
    self.targetFruit = nil   -- Add targetFruit property
    self.complaining = false -- Add complaining property
    self.icks = {}           -- Add icks property
    self.leftrightanimation = {
        image = walkLeftRightImage,
        frameWidth = 16,
        frameHeight = 16,
        currentFrame = 1,
        totalFrames = 4,
        frameDuration = 0.1,
        time = 0
    }
    self.downanimation = {
        image = walkDownImage,
        frameWidth = 16,
        frameHeight = 16,
        currentFrame = 1,
        totalFrames = 4,
        frameDuration = 0.1,
        time = 0
    }
    self.upanimation = {
        image = walkUpImage,
        frameWidth = 16,
        frameHeight = 16,
        currentFrame = 1,
        totalFrames = 4,
        frameDuration = 0.1,
        time = 0,
    }
    self.animation = self.leftrightanimation
    self.world = world
    self.bornTime = love.timer.getTime()
    self.frustrationThreshold = 12
    return self
end

function Character:secondsWithoutTarget()
    local now = love.timer.getTime()
    return now - self.bornTime
end

function Character:getFrustrated()
    if not self.complaining and self:secondsWithoutTarget() > self.frustrationThreshold then
        self:complain()
    end
end

function Character:addIck(x, y)
    table.insert(self.icks, { x = x, y = y, timestamp = love.timer.getTime() })
    self.scoring:incrementIcks()
end

function Character:targetGivesIck(target)
    for i = #self.icks, 1, -1 do
        if love.timer.getTime() - self.icks[i].timestamp > 10 then
            table.remove(self.icks, i)
        end
    end
    for _, ick in ipairs(self.icks) do
        if ick.x == target.x and ick.y == target.y then
            return true
        end
    end
    return false
end

function Character:updateAnimation(dt)
    self.animation.time = self.animation.time + dt
    local offset = self.animation.offset or 0
    if self.animation.time >= self.animation.frameDuration then
        self.animation.time = self.animation.time - self.animation.frameDuration
        self.animation.currentFrame = self.animation.currentFrame % self.animation.totalFrames + 1
    end
end

function Character:pos()
    local tile = Util.worldToTileSpace(self.x, self.y)
    return { x = tile.x, y = tile.y }
end

function Character:newPathfinderToTarget(target)
    if not self:pos() then return false end
    return Luafinding(Vector(self:pos().x, self:pos().y), Vector(target.x, target.y),
        function(pos) return self.world:tileIsAliveAtPosition(pos.x, pos.y) end, true)
end

function Character:chooseNearestFruit()
    if self.targetFruit then return end

    local nearestFruit = nil
    local nearestDistance = math.huge

    for _, fruit in ipairs(Fruits) do
        local fruitPos = Util.tileToWorldSpace(fruit.x, fruit.y)
        local distance = math.sqrt((self.x - fruitPos.x) ^ 2 + (self.y - fruitPos.y) ^ 2)
        if distance < nearestDistance and not fruit.claimed then
            local pathfinder = self:newPathfinderToTarget(fruit)
            -- enable diagonalMovement
            if pathfinder:GetPath() then
                nearestDistance = distance
                nearestFruit = fruit
                self.pathfinder = pathfinder
                Audio.playSFX("settled")
                self.bornTime = math.huge
                if PATH_DEBUG then
                    print("got pathfinder for " .. fruit.x .. ", " .. fruit.y)
                end
            end
        end
    end
    if nearestFruit then
        nearestFruit.claimed = love.timer.getTime()
        self.targetFruit = nearestFruit
    end
end

function Character:complain()
    if self.complaining == false then
        self.scoring:incrementComplaints()
    end
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
    self:getFrustrated()
end

function Character:draw()
    love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
    local scaleX = 1
    local visualScaleX = 3          -- Scale factor for visual size
    local visualScaleY = 3          -- Scale factor for visual size
    if self.path and #self.path > 0 then
        local nextStep = self.path[self.pathIndex]
        if nextStep.x < self:pos().x then
            self.animation = self.leftrightanimation
        elseif nextStep.x > self:pos().x then
            self.animation = self.leftrightanimation
            scaleX = -1 -- Flip horizontally if moving right, since we only have a left walking version
        elseif nextStep.y > self:pos().y then
            self.animation = self.downanimation
        elseif nextStep.y == self:pos().y and nextStep.x == self:pos().x then
            -- target is in the same tile, just keep the same animation
        else
            self.animation = self.upanimation
        end
    end
    local frameX = (self.animation.currentFrame - 1) * self.animation.frameWidth
    love.graphics.draw(self.animation.image,
        love.graphics.newQuad(frameX, 0, self.animation.frameWidth, self.animation.frameHeight,
            self.animation.image:getDimensions()), self.x + self.width / 2, self.y - self.height * (visualScaleY / 2),
        0,
        scaleX * visualScaleX * (self.width / self.animation.frameWidth),
        visualScaleY * (self.height / self.animation.frameHeight),
        self.animation.frameWidth / 2, 0)

    -- Draw a circle above the AI character's head
    if self.complaining then
        love.graphics.setColor(1, 0, 0, 0.5) -- Red for complaining
    elseif self.targetFruit then
        love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for having a target fruit
    else
        love.graphics.setColor(0, 0, 1, 0.5) -- Blue for no target fruit
    end
    local circleX = self.x + self.width / 2
    local circleY = self.y - self.height - 15
    local circleRadius = self.width * 0.10 * visualScaleX
    love.graphics.circle("fill", circleX, circleY, circleRadius)

    -- debu
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

    -- Draw debug text for nextStep and currentTilePos
    if ANIMATION_DEBUG and self.path and #self.path > 0 then
        local nextStep = self.path[self.pathIndex]
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Next: (" .. nextStep.x .. ", " .. nextStep.y .. ")", self.x, self.y + self.height + 10)
        love.graphics.print("Current: (" .. self:pos().x .. ", " .. self:pos().y .. ")", self.x, self.y - 20)
        love.graphics.print("Target: (" .. self.targetFruit.x .. ", " .. self.targetFruit.y .. ")", self.x, self.y - 30)
    end
    if ANIMATION_DEBUG then
        -- Draw a larger point on the tile the AI character is standing on
        love.graphics.setColor(1, 0, 0)
        local tileCenterX = (self:pos().x - 1) * TILE_SIZE + TILE_SIZE / 2
        local tileCenterY = (self:pos().y - 1) * TILE_SIZE + TILE_SIZE / 2
        love.graphics.circle("fill", tileCenterX, tileCenterY, 3)
    end
end

function Character:giveUpOnTarget()
    if self.targetFruit then
        self.targetFruit.claimed = nil
        self.targetFruit = nil
        self.path = nil
    end
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
        if self.pathfinder then
            if PATH_DEBUG then
                print("tostr " .. self.pathfinder:__tostring())
            end
            if not self.path or #self.path == 0 then
                self.path = self.pathfinder:GetPath()
                self.pathIndex = 1
            end
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
                        if PATH_DEBUG then
                            print("Reached target fruit at " .. self.targetFruit.x .. ", " .. self.targetFruit.y)
                        end
                        self.scoring:incrementFruits()
                        Util.removeEntityAtTile(Fruits, self.targetFruit.x, self.targetFruit.y)
                        self.targetFruit = nil
                        self.path = nil
                        self.bornTime = love.timer.getTime()
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
