local UI = {}
UI.__index = UI

function UI:new()
    local self = setmetatable({}, UI)
    self.buttons = {}
    return self
end

-- UI coordinate space is 16x16, so we need to convert screen space to UI space for mouse clicks
-- to determine which UI coordinates were clicked
function UI:clickedTile(x, y)
    local tileX = math.floor(x / 16)
    local tileY = math.floor(y / 16)
    return tileX, tileY
end

-- The x and y of the button determine it's placement on screen
-- From UI space X axis - 1 to 16 being the top row, and the Y axis 1 to 16 being the left column
-- The label is the text that will be displayed on the button
function UI:addButton(label, x, y)
    local button = {
        x = x,
        y = y,
        label = label,
    }
    table.insert(self.buttons, button)
    return button
end

function UI:draw()
    for i, button in ipairs(self.buttons) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", button.x * 16, button.y * 16, 16 * #button.label, 16)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(button.label, button.x * 16, button.y * 16)
    end
end

return UI