
local UI = {}
UI.__index = UI

local gridHSize = 20
local gridVSize = 16
local plainCursor = love.graphics.newImage("assets/images/UI/cursor_plain.png")
local digCursor = love.graphics.newImage("assets/images/UI/dig_icon.png")
local exitButtonImage = love.graphics.newImage("assets/images/UI/exit_button.png")
local reloadButtonImage = love.graphics.newImage("assets/images/UI/reload_button.png")
local changeSeedButtonImage = love.graphics.newImage("assets/images/UI/seed_button.png")

love.mouse.setVisible(false)

function UI:new(abilities, camera, scoring)
    self.abilities = abilities
    self.camera = camera
    self.scoring = scoring

    local self = setmetatable({}, UI)
    self.width = WINDOW_WIDTH
    self.height = WINDOW_HEIGHT
    self.gridWidth = self.width / gridHSize
    self.gridHeight = self.height / gridVSize
    self.buttons = {}
    self.cursorImage = plainCursor

    self.isWaitingForInput = false

    love.graphics.setFont(love.graphics.newFont('assets/fonts/commodore64.ttf', 12))
    return self
end

function UI:screenToUIGridSpace(x, y)
    return {
        x = math.floor(x / self.gridWidth),
        y = math.floor(y / self.gridHeight),
    }
end

-- UI coordinate space is 16x20, so we need to convert screen space to UI space for mouse clicks
-- to determine which UI coordinates were clicked
function UI:clickedButton(x, y)
    local grid = self:screenToUIGridSpace(x, y)
    if UI_DEBUG then
        local uipos = self:screenToUIGridSpace(x, y)
        print("Clicked coordinates: (screen coords: " .. x .. ", " .. y .. ") "
            .. "(ui grid: " .. uipos.x .. ", " .. uipos.y .. "), (button grid: " .. grid.x .. ", " .. grid.y .. ")")
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
        print(clickedButton.buttonType .. " button clicked: " .. clickedButton.label)
    end
    if clickedButton.buttonType == BUTTON_TYPE_ABILITY then
        self.abilities:selectAbility(clickedButton.label)
        self:setCursorImage(clickedButton.label)
    elseif clickedButton.buttonType == BUTTON_TYPE_SYSTEM then
        if clickedButton.label == SYSTEM_EXIT then
            love.event.quit()
        end
        if clickedButton.label == SYSTEM_RELOAD then
            clickedButton.actionClosure()
        end
        if clickedButton.label == SYSTEM_CHANGE_SEED then
            clickedButton.actionClosure()
        end
    end
    return clickedButton.label
end

local function getTypeFromLabel(label)
    if label == ABILITY_DIG or
        label == ABILITY_EXPLODE or
        label == ABILITY_LINE or
        label == ABILITY_DRAG or
        label == ABILITY_SELECT then
        return BUTTON_TYPE_ABILITY
    elseif label == SYSTEM_EXIT or
        label == SYSTEM_RELOAD or
        label == SYSTEM_CHANGE_SEED then
        return BUTTON_TYPE_SYSTEM
    end
    return nil
end

local function getImageFromLabel(label)
    if label == ABILITY_SELECT then
        return plainCursor
    end
    if label == ABILITY_DIG then
        return digCursor
    end
    if label == SYSTEM_EXIT then
        return exitButtonImage
    end
    if label == SYSTEM_RELOAD then
        return reloadButtonImage
    end
    if label == SYSTEM_CHANGE_SEED then
        return changeSeedButtonImage
    end
    return nil
end

-- The x and y of the button determine it's placement on screen
-- From UI space X axis - 1 to 16 being the top row, and the Y axis 1 to 20 being the left column
-- The label is the text that will be displayed on the button
-- Pass a closure to run it on click
function UI:addButton(label, x, y, actionClosure)
    local button = {
        label = label,
        x = x,
        y = y,
        buttonType = getTypeFromLabel(label),
        image = getImageFromLabel(label),
        actionClosure = actionClosure,
    }
    table.insert(self.buttons, button)
    return button
end

function UI:draw()
    local buttonWidth = self.width / gridHSize
    local buttonHeight = self.height / gridVSize

    for i, button in ipairs(self.buttons) do
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(
            button.image, button.x * buttonWidth, button.y * buttonHeight, 0,
            buttonWidth / button.image:getWidth(), buttonHeight / button.image:getHeight())
    end

    -- highlight button hovered on
    local x, y = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1)
    local btn = self:getHoveredButton(x, y)
    if btn then
        love.graphics.rectangle("line", btn.x * buttonWidth, btn.y * buttonHeight, buttonWidth,
            buttonHeight)
        -- show the label of the hovered button
        local textWidth = love.graphics.getFont():getWidth(btn.label)
        local textHeight = love.graphics.getFont():getHeight(btn.label)
        love.graphics.setColor(.5, .8, .6)
        love.graphics.print(
            btn.label, btn.x * buttonWidth + (buttonWidth - textWidth) / 2,
            btn.y * buttonHeight + (buttonHeight - textHeight) / 2)
    end

    -- draw score
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. self.scoring:getFinalScore(), 10, 10)

    -- draw cursor last!
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.cursorImage, love.mouse.getX(), love.mouse.getY())
end

function UI:getHoveredButton(x, y)
    local grid = self:screenToUIGridSpace(x, y)
    for _, button in ipairs(self.buttons) do
        if grid.x == button.x and grid.y == button.y then
            return button
        end
    end
    return nil
end

function UI:getHoveredTile(x, y)
    return self.camera:toTileSpace(x, y)
end

function UI:setCursorImage(ability)
    local image
    if ability == ABILITY_DIG then
        image = digCursor
    elseif ability == ABILITY_SELECT then
        image = plainCursor
    else
        image = plainCursor
    end
    self.cursorImage = image
end

return UI
