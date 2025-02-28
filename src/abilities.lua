require("src.constants")

-- local Audio = require("src.audio")
local Abilities = {}
Abilities.__index = Abilities

function Abilities:new(world, scoring)
    local self   = setmetatable({}, Abilities)
    self.world   = world
    self.scoring = scoring
    return self
end

-- user clicked an ability button, load it into the cursor
function Abilities:selectAbility(ability)
    if UI_DEBUG then print("Selecting: " .. ability) end
    if ability == ABILITY_DIG then
        self:readyAbility(ABILITY_DIG)
    elseif ability == ABILITY_EXPLODE then
        self:readyAbility(ABILITY_EXPLODE)
    elseif ability == ABILITY_LINE then
        self:readyAbility(ABILITY_LINE)
    elseif ability == ABILITY_DRAG then
        self:readyAbility(ABILITY_DRAG)
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
        return { 1, 0, 0, .3 }
    elseif self.selectedAbility == ABILITY_EXPLODE then
        return { 1, 0, 0, .3 }
    elseif self.selectedAbility == ABILITY_LINE then
        return { 1, 0, 0, .3 }
    elseif self.selectedAbility == ABILITY_DRAG then
        return { 1, 0, 0, .3 }
    elseif self.selectedAbility == ABILITY_SELECT then
        return { 1, 1, 1, .3 }
    else
        return { 1, 1, 1, .3 }
    end
end

function Abilities:unready()
    self:readyAbility(ABILITY_DIG)
end

function Abilities:useAbility()
    if self.selectedAbility == ABILITY_DIG then
        Audio.playSFX("mine")
        -- set the clicked tile to be an Alive cell
        self.world:breakWallTileAtMouse()
        self.scoring:incrementActions()
    elseif self.selectedAbility == ABILITY_EXPLODE then
        Audio.playSFX("explode")
        self.world:breakWallTileAndSurroundingAtMouse()
        self.scoring:incrementActions()
        self.scoring:useUpgrade()
        if not self.scoring:upgradeAvailable(ABILITY_EXPLODE) then
            self:unready()
        end
    elseif self.selectedAbility == ABILITY_LINE then
        Audio.playSFX("linemine")
        self.world:breakLineAtMouse()
        self.scoring:incrementActions()
        self.scoring:useUpgrade()
        if not self.scoring:upgradeAvailable(ABILITY_LINE) then
            self:unready()
        end
    elseif self.selectedAbility == ABILITY_DRAG then
        self.drag = self.drag - 1
    end
end

return Abilities
