Scoring = {}
Scoring.__index = Scoring

function Scoring:new()
    local self = setmetatable({}, Scoring)
    self.complaints = 0
    self.icks = 0
    self.actions = 0
    self.fruits = 0
    self.score = 0
    return self
end

function Scoring:incrementComplaints()
    self.complaints = self.complaints + 10
end

function Scoring:incrementIcks()
    self.icks = self.icks + 5
end

function Scoring:incrementActions()
    self.actions = self.actions + 5
end

function Scoring:incrementFruits()
    self.fruits = self.fruits + 50
end

function Scoring:getFinalScore()
    return self.fruits - (self.complaints + self.icks + self.actions)
end

function Scoring:reset()
    self.complaints = 0
    self.icks = 0
    self.actions = 0
    self.fruits = 0
    self.score = 0
end

return Scoring
