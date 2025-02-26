Scoring = {}
Scoring.__index = Scoring

function Scoring:new()
    local self = setmetatable({}, Scoring)
    self.complaints = 0
    self.icks = 0
    self.actions = 0
    self.fruits = 0
    self.score = 0

    self.ability_score = 0
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
    self.ability_score = self.ability_score + 1
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

function Scoring:upgradeAvailable(label)
    if label == ABILITY_DIG then return true end
    if label == ABILITY_EXPLODE then
        return self.ability_score > 5 or UI_DEBUG
    end
end

function Scoring:useUpgrade()
    self.ability_score = self.ability_score - 1
end


return Scoring
