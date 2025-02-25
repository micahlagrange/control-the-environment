require("src.constants")

local Abilities = {}
Abilities.__index = Abilities

function Abilities:new(world, scoring)
    local self   = setmetatable({}, Abilities)
    self.world   = world
    self.scoring = scoring

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
    elseif ability == ABILITY_SELECT then
        self:readyAbility(ABILITY_SELECT)
    else
        self.selectedAbility = nil
        if UI_DEBUG then
            print("Invalid ability selected")
        end
    end
end

function Abilities:readyAbility(ability)
    self.selectedAbility = ability
end

function Abilities:getHighlightColor()
    if self.selectedAbility == ABILITY_DIG then
        return {1, 0, 0, .3}
    elseif self.selectedAbility == ABILITY_EXPLODE then
        return {1, 0, 0, .3}
    elseif self.selectedAbility == ABILITY_LINE then
        return {1, 0, 0, .3}
    elseif self.selectedAbility == ABILITY_DRAG then
        return {1, 0, 0, .3}
    elseif self.selectedAbility == ABILITY_SELECT then
        return {1, 1, 1, .3}
    else
        return {1, 1, 1, .3}
    end
end

function Abilities:useAbility()
    if self.selectedAbility == ABILITY_DIG then
        self.dig = self.dig - 1
        -- set the clicked tile to be an Alive cell
        self.world:breakWallTileAtMouse()
        self.scoring:incrementActions()
    elseif self.selectedAbility == ABILITY_EXPLODE then
        self.explode = self.explode - 1
    elseif self.selectedAbility == ABILITY_LINE then
        self.line = self.line - 1
    elseif self.selectedAbility == ABILITY_DRAG then
        self.drag = self.drag - 1
    end
end

return Abilities
