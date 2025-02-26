local Buttons = {}
Buttons.__index = Buttons

local plainCursor = love.graphics.newImage("assets/images/UI/plain_cursor.png")
local plainButtonImage = love.graphics.newImage("assets/images/UI/plain_btn.png")
local digButtonImage = love.graphics.newImage("assets/images/UI/dig_icon.png")
local digCursor = love.graphics.newImage("assets/images/UI/dig_cursor.png")
local exitButtonImage = love.graphics.newImage("assets/images/UI/exit_button.png")
local reloadButtonImage = love.graphics.newImage("assets/images/UI/reload_button.png")
local changeSeedButtonImage = love.graphics.newImage("assets/images/UI/seed_button.png")
local increaseUpdatesButtonImage = love.graphics.newImage("assets/images/UI/increase_world_updates_btn.png")
local decreaseUpdatesButtonImage = love.graphics.newImage("assets/images/UI/decrease_world_updates_btn.png")
local increaseAutomataRatioButtonImage = love.graphics.newImage("assets/images/UI/increase_automata_ratio_btn.png")
local decreaseAutomataRatioButtonImage = love.graphics.newImage("assets/images/UI/decrease_automata_ratio_btn.png")
local explodeButtonImage = love.graphics.newImage("assets/images/UI/explod_btn.png")
local explodeCursor = love.graphics.newImage("assets/images/UI/explod_cursor.png")
-- local lineButtonImage = love.graphics.newImage("assets/images/UI/line_icon.png")
-- local lineCursor = love.graphics.newImage("assets/images/UI/line_cursor.png")
-- local dragButtonImage = love.graphics.newImage("assets/images/UI/drag_icon.png")
-- local dragCursor = love.graphics.newImage("assets/images/UI/drag_cursor.png")

local buttonTypes = {
    {
        label = ABILITY_SELECT,
        buttonType = BUTTON_TYPE_ABILITY,
        icon = plainButtonImage,
        cursor = plainCursor,
    },
    {
        label = ABILITY_DIG,
        buttonType = BUTTON_TYPE_ABILITY,
        icon = digButtonImage,
        cursor = digCursor,
    },
    {
        label = ABILITY_EXPLODE,
        buttonType = BUTTON_TYPE_ABILITY,
        icon = explodeButtonImage,
        cursor = explodeCursor,
    },
    {
        label = ABILITY_LINE,
        buttonType = BUTTON_TYPE_ABILITY,
        icon = plainButtonImage,
        cursor = plainCursor,
    },
    {
        label = ABILITY_DRAG,
        buttonType = BUTTON_TYPE_ABILITY,
        icon = plainButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_EXIT,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = exitButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_RELOAD,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = reloadButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_CHANGE_SEED,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = changeSeedButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_INCREASE_UPDATES,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = increaseUpdatesButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_DECREASE_UPDATES,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = decreaseUpdatesButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_INCREASE_AUTOMATA_RATIO,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = increaseAutomataRatioButtonImage,
        cursor = plainCursor,
    },
    {
        label = SYSTEM_DECREASE_AUTOMATA_RATIO,
        buttonType = BUTTON_TYPE_SYSTEM,
        icon = decreaseAutomataRatioButtonImage,
        cursor = plainCursor,
    },
}

function Buttons:new(label, x, y, buttonType, icon, cursor, actionClosure)
    local self = setmetatable({}, Buttons)
    self.label = label
    self.x = x
    self.y = y
    self.buttonType = buttonType
    self.icon = icon
    self.cursor = cursor
    self.actionClosure = actionClosure
    return self
end

function Buttons:buttonFromLabel(label, x, y, actionClosure)
    for _, btn in ipairs(buttonTypes) do
        if btn.label == label then
            return self:new(label, x, y, btn.buttonType, btn.icon, btn.cursor, actionClosure)
        end
    end
    return nil
end

return Buttons
