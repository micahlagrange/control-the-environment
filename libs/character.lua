local Character = {}
Character.__index = Character

function Character:new(x, y, width, height)
    local self = setmetatable({}, Character)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.path = nil
    self.pathIndex = 1
    return self
end

function Character:update(dt)
    -- Override this method for specific character behavior
end

function Character:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
end

function Character:setPath(path)
    self.path = path
    self.pathIndex = 1
end

function Character:moveToNextStep()
    if self.path and self.path[self.pathIndex] then
        local step = self.path[self.pathIndex]
        self.x = step.x
        self.y = step.y
        self.pathIndex = self.pathIndex + 1
    end
end

return Character
