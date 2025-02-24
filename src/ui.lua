local UI = {}
UI.__index = UI

local plainCursor = love.graphics.newImage("assets/images/UI/cursor_plain.png")
local digCursor = love.graphics.newImage("assets/images/UI/dig_icon.png")

function UI:new(abilities)
    love.mouse.setVisible(false)

    local self = setmetatable({}, UI)
    self.width = WINDOW_WIDTH
    self.height = WINDOW_HEIGHT
    self.gridWidth = self.width / 16
    self.gridHeight = self.height / 16
    self.buttons = {}
    self.cursorImage = plainCursor
    self.abilities = abilities
    return self
end

function UI:screenToUIGridSpace(x, y)
    return {
        x = math.floor(x / self.gridWidth),
        y = math.floor(y / self.gridHeight),
    }
end

-- UI coordinate space is 16x16, so we need to convert screen space to UI space for mouse clicks
-- to determine which UI coordinates were clicked
function UI:clickedButton(x, y)
    local grid = self:screenToUIGridSpace(x, y)
    if UI_DEBUG then
        local uipos = self:screenToUIGridSpace(x, y)
        print("Clicked coordinates: (screen coords: " .. x .. ", " .. y .. ") "
            .. "(ui grid: " .. uipos.x .. ", " .. uipos.y .. ")")
    end
    for _, button in ipairs(self.buttons) do
        if grid.x == button.x and grid.y == button.y then
            return button
        end
    end
    return nil
end

function UI:doButtonClick(clickedButton)
    if UI_DEBUG then
        print("Button clicked: " .. clickedButton.label)
    end
    if clickedButton.buttonType == BUTTON_TYPE_ABILITY then
        self.abilities:selectAbility(clickedButton.label)
    end
    if clickedButton.buttonType == BUTTON_TYPE_SYSTEM then
        if clickedButton.label == SYSTEM_EXIT then
            love.event.quit()
        end
    end
    return clickedButton.label
end

local function getTypeFromLabel(label)
    if label == ABILITY_DIG or label == ABILITY_EXPLODE or label == ABILITY_LINE or label == ABILITY_DRAG then
        return BUTTON_TYPE_ABILITY
    end
    if label == SYSTEM_EXIT then
        return BUTTON_TYPE_SYSTEM
    end
    return nil
end

-- The x and y of the button determine it's placement on screen
-- From UI space X axis - 0 to 15 being the top row, and the Y axis 0 to 15 being the left column
-- The label is the text that will be displayed on the button
function UI:addButton(label, x, y)
    local button = {
        label = label,
        x = x,
        y = y,
        buttonType = getTypeFromLabel(label)
    }
    table.insert(self.buttons, button)
    return button
end

function UI:draw()
    local buttonWidth = self.width / 16
    local buttonHeight = self.height / 16

    for i, button in ipairs(self.buttons) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", button.x * buttonWidth, button.y * buttonHeight, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", button.x * buttonWidth, button.y * buttonHeight, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(button.label)
        local textHeight = love.graphics.getFont():getHeight(button.label)
        love.graphics.print(button.label, button.x * buttonWidth + (buttonWidth - textWidth) / 2,
            button.y * buttonHeight + (buttonHeight - textHeight) / 2)
    end

    -- draw cursor last!
    love.graphics.draw(self.cursorImage, love.mouse.getX(), love.mouse.getY())
end

function UI:setCursorImage(ability)
    local image
    if ability == ABILITY_DIG then
        image = digCursor
    else
        image = plainCursor
    end
    self.cursorImage = image
end

return UI
