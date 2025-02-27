local spritesheet = require("src.spritesheet")
local anim8 = require("libs.anim8")

local UI = {}
UI.__index = UI

local Buttons = require("src.buttons")

local gridHSize = 20
local gridVSize = 16
love.mouse.setVisible(false)

local plainCursor = Buttons:buttonFromLabel(ABILITY_DIG).cursor

local zoomIconImage = love.graphics.newImage("assets/images/UI/scroll_zoom_icon.png")
local zoomIconGrid = spritesheet.NewAnim8Grid(zoomIconImage, 16, 16)
local zoomIconAnim = anim8.newAnimation(zoomIconGrid('1-3', 1), 0.3)
local panIconImage = love.graphics.newImage("assets/images/UI/map_move_icon.png")
local panIconGrid = spritesheet.NewAnim8Grid(panIconImage, 16, 16)
local panIconAnim = anim8.newAnimation(panIconGrid('1-3', 1), 0.3)

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

function UI:UIGridToScreenSpace(x, y)
    return {
        x = x * self.gridWidth,
        y = y * self.gridHeight,
    }
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
    if clickedButton.buttonType == BUTTON_TYPE_ABILITY and self.scoring:upgradeAvailable(clickedButton.label) then
        self.abilities:selectAbility(clickedButton.label)
        self.cursorImage = clickedButton.cursor
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
        if clickedButton.label == SYSTEM_INCREASE_UPDATES then
            clickedButton.actionClosure()
        end
        if clickedButton.label == SYSTEM_DECREASE_UPDATES then
            clickedButton.actionClosure()
        end
        if clickedButton.label == SYSTEM_INCREASE_AUTOMATA_RATIO then
            clickedButton.actionClosure()
        end
        if clickedButton.label == SYSTEM_DECREASE_AUTOMATA_RATIO then
            clickedButton.actionClosure()
        end
    end
    return clickedButton.label
end

-- The x and y of the button determine it's placement on screen
-- From UI space X axis - 1 to 16 being the top row, and the Y axis 1 to 20 being the left column
-- The label is the text that will be displayed on the button
-- Pass a closure to run it on click
function UI:addButton(label, x, y, actionClosure)
    local button = Buttons:buttonFromLabel(label, x, y, actionClosure)
    table.insert(self.buttons, button)
    return button
end

function UI:draw()
    local buttonWidth = self.width / gridHSize
    local buttonHeight = self.height / gridVSize

    for i, button in ipairs(self.buttons) do
        if self.scoring:upgradeAvailable(button.label) or button.buttonType ~= BUTTON_TYPE_ABILITY or button.label == ABILITY_SELECT then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                button.icon, button.x * buttonWidth, button.y * buttonHeight, 0,
                buttonWidth / button.icon:getWidth(), buttonHeight / button.icon:getHeight())
        end
    end

    -- highlight button hovered on
    local x, y = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1)
    local btn = self:getHoveredButton(x, y)
    if btn and self.scoring:upgradeAvailable(btn.label) then
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

    love.graphics.setColor(1, 1, 1)
    -- draw score
    love.graphics.print(
    "Score: " ..
    self.scoring:getFinalScore() ..
    "     Tool level: " .. self.scoring:toolLevel() + 1 .. "      Wins: " .. self.scoring.levelsWon, 10, 10)

    -- draw cursor last!
    if self.abilities.selectedAbility == ABILITY_SELECT then
        -- additional check if ability expired and we need to go back to selector
        self.cursorImage = plainCursor
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.cursorImage, love.mouse.getX(), love.mouse.getY(), 0, 2, 2)

    -- alert
    if self.alertShown then
        local alertPosition = { x = 60, y = 40 }
        local alertColor = { .9, .3, .3 }
        love.graphics.setColor(alertColor)
        love.graphics.print(self.alertText, alertPosition.x, alertPosition.y)
    end

    if self.iconAnimation and self.animIconImage then
        local corner = self:UIGridToScreenSpace(19, 2)
        love.graphics.setColor(1, 1, 1)
        self.iconAnimation:draw(self.animIconImage, corner.x, corner.y, 0, 2, 2)
    end
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

function UI:alert(text, iconActionName)
    self.alertTimer = 10
    self.alertShown = true
    self.alertText = text
    if iconActionName == "zoom" then
        self.iconAnimation = zoomIconAnim
        self.animIconImage = zoomIconImage
    end
    if iconActionName == "pan" then
        self.iconAnimation = panIconAnim
        self.animIconImage = panIconImage
    end
end

function UI:update(dt)
    self.alertTimer = self.alertTimer - dt
    if self.alertTimer <= 0 then
        self.alertShown = false
        self.iconAnimation = nil
    end
    if self.iconAnimation then
        self.iconAnimation:update(dt)
    end
end

return UI
