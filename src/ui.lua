local UI = {}
UI.__index = UI

function UI:new()
    local self = setmetatable({}, UI)
    self.width = WINDOW_WIDTH
    self.height = WINDOW_HEIGHT
    self.gridWidth = self.width / 16
    self.gridHeight = self.height / 16
    self.buttons = {}
    return self
end

-- UI coordinate space is 16x16, so we need to convert screen space to UI space for mouse clicks
-- to determine which UI coordinates were clicked
function UI:clickedButton(x, y)
    local gridX = math.floor(x / self.gridWidth)
    local gridY = math.floor(y / self.gridHeight)
    if UI_DEBUG then
        print("Clicked: " .. gridX .. ", " .. gridY)
    end
    for _, button in ipairs(self.buttons) do
        if gridX == button.x and gridY == button.y then
            return button.label
        end
    end
end

-- The x and y of the button determine it's placement on screen
-- From UI space X axis - 0 to 15 being the top row, and the Y axis 0 to 15 being the left column
-- The label is the text that will be displayed on the button
function UI:addButton(label, x, y)
    local button = {
        label = label,
        x = x,
        y = y,
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
end

return UI
