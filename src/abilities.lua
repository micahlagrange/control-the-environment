local Abilities = {}

function Abilities:new()
    local self   = setmetatable({}, Abilities)
    -- Each ability is not equipped by default
    -- When an ability is used, it's counter goes down. once it reaches zero you can no longer use it
    -- default values
    self.dig     = 11
    self.explode = 0
    self.line    = 0
    self.drag    = 0
    return self
end

-- user clicked an ability button, load it into the cursor
function Abilities:selectAbility(ability)
    if ability == ABILITY_DIG then
        if self.dig > 0 then
            self:readyAbility(ABILITY_DIG)
        end
    elseif ability == ABILITY_EXPLODE then
        if self.explode > 0 then
            self:readyAbility(ABILITY_EXPLODE)
        end
    elseif ability == ABILITY_LINE then
        if self.line > 0 then
            self:readyAbility(ABILITY_LINE)
        end
    elseif ability == ABILITY_DRAG then
        if self.drag > 0 then
            self:readyAbility(ABILITY_DRAG)
        end
    end
end


return Abilities
