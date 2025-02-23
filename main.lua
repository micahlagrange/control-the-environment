local Character = require("libs/character")

love.graphics.setDefaultFilter("nearest", "nearest")

local SEED = 'jonny' -- define a seed variable
local character = Character:new(0, 0, CHARACTER_SIZE, CHARACTER_SIZE)
local aiCharacters = {}
local camera = { x = 0, y = 0, scale = ZOOM_LEVEL }
local fruitImages = {}

local GRASS_COLORS = {
    "#94a35b",
    "#849151",
    "#737f47",
}

local DIRT_COLORS = {
    "#a38f5b",
    "#917f51",
    "#7f6f47"
}

local WALL_COLORS = {
    "#3B3B3B",
    "#2F2F2F",
    "#232323",
    "#4F4F4F"
}

local function hexToRgb(hex)
    hex = hex:gsub("#", "") -- Remove the '#' character if present
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    return r, g, b
end

local function randomInt(min, max)
    return math.floor(love.math.random() * (max - min + 1) + min)
end

local function getTileColor(colorTable, x, y)
    local seed = tonumber(SEED) or SEED:byte(1, -1)
    love.math.setRandomSeed(seed + x * 1000 + y)
    local index = randomInt(1, #colorTable)
    return hexToRgb(colorTable[index])
end

local function loadFruitImages()
    local files = love.filesystem.getDirectoryItems("assets/images/yummy_prizes")
    for _, file in ipairs(files) do
        if file:match("%.png$") and file ~= "yummy_prizes2.png" then
            local image = love.graphics.newImage("assets/images/yummy_prizes/" .. file)
            if image then
                table.insert(fruitImages, image)
            end
        end
    end
end

local function isCharacterInLiveCell(x, y)
    return World[math.floor(x / TILE_SIZE) + 1] and World[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1] and
        World[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1].Alive
end

local function isCharacterPositionValid(x, y)
    return isCharacterInLiveCell(x, y) and
        isCharacterInLiveCell(x + character.width, y) and
        isCharacterInLiveCell(x, y + character.height) and
        isCharacterInLiveCell(x + character.width, y + character.height)
end

local function applyCellularAutomata(grid, width, height, passes, birthLimit, deathLimit)
    for pass = 1, passes do
        local newGrid = {}
        for x = 1, width do
            newGrid[x] = {}
            for y = 1, height do
                local aliveNeighbors = 0
                for i = -1, 1 do
                    for j = -1, 1 do
                        if not (i == 0 and j == 0) then
                            local nx, ny = x + i, y + j
                            if nx > 0 and nx <= width and ny > 0 and ny <= height and grid[nx][ny].Alive then
                                aliveNeighbors = aliveNeighbors + 1
                            end
                        end
                    end
                end
                if grid[x][y].Alive then
                    newGrid[x][y] = { Alive = aliveNeighbors >= deathLimit }
                else
                    newGrid[x][y] = { Alive = aliveNeighbors > birthLimit }
                end
            end
        end
        grid = newGrid
    end
    return grid
end

local function GenerateWorld()
    -- nasty globals
    Fruits = {}
    World = {}
    local width = WORLD_WIDTH / TILE_SIZE
    local height = WORLD_HEIGHT / TILE_SIZE

    for x = 1, width do
        World[x] = {}
        for y = 1, height do
            World[x][y] = { Alive = randomInt(0, 100) < AUTOMATA_RATIO_PERCENT }
        end
    end

    World = applyCellularAutomata(World, width, height, WorldUpdateLimit, 3, 3)

    -- Ensure the character spawns in a live cell
    repeat
        character.x = randomInt(1, WORLD_WIDTH)
        character.y = randomInt(1, WORLD_HEIGHT)
    until isCharacterPositionValid(character.x, character.y)

    -- Add AI characters
    for i = 1, 5 do
        local aiCharacter = Character:new(
            randomInt(1, WORLD_WIDTH),
            randomInt(1, WORLD_HEIGHT),
            CHARACTER_SIZE,
            CHARACTER_SIZE
        )
        aiCharacter.id = i
        table.insert(aiCharacters, aiCharacter)
    end

    -- Add fruit to a percentage of the live cells
    for x = 1, width do
        for y = 1, height do
            if World[x][y].Alive and love.math.random() < FRUIT_PERCENTAGE then
                local fruitIndex = randomInt(1, #fruitImages)
                local fruitImage = fruitImages[fruitIndex]
                table.insert(Fruits, { x = x, y = y, image = fruitImage })
            end
        end
    end
end

local function GenerateGroundColors()
    GroundColors = {}
    local width = WORLD_WIDTH / TILE_SIZE
    local height = WORLD_HEIGHT / TILE_SIZE

    for x = 1, width do
        GroundColors[x] = {}
        for y = 1, height do
            GroundColors[x][y] = { Lush = randomInt(0, 100) < 78 }
        end
    end

    GroundColors = applyCellularAutomata(GroundColors, width, height, WorldTimerLimit, 3, 3)
end

local function startGame()
    love.math.setRandomSeed(tonumber(SEED) or SEED:byte(1, -1)) -- set the seed for reproducibility, always coerce it to a number

    WorldTimer = 0
    WorldTimerLimit = 0.001
    WorldUpdateCounter = 0
    WorldUpdateLimit = 2
    GroundUpdateLimit = 20

    GenerateWorld()
    GenerateGroundColors()
end

local function updatePlayerMovement(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        dy = dy - 1
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        dy = dy + 1
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        dx = dx - 1
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        dx = dx + 1
    end

    -- Normalize the movement vector
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
        dx, dy = dx / length, dy / length
    end

    -- Apply movement speed
    dx, dy = dx * 100 * dt, dy * 100 * dt

    -- Calculate new position
    local newX = character.x + dx
    local newY = character.y + dy

    -- Check for collision with dead cells
    if isCharacterPositionValid(newX, newY) then
        character.x = newX
        character.y = newY
    end
end

local fruitUpdateTimer = 0
local fruitUpdateInterval = 2 -- seconds

local function updateAICharacters(dt)
    fruitUpdateTimer = fruitUpdateTimer + dt
    if fruitUpdateTimer >= fruitUpdateInterval then
        for _, aiCharacter in ipairs(aiCharacters) do
            aiCharacter:chooseNearestFruit()
        end
        fruitUpdateTimer = 0
    end

    for _, aiCharacter in ipairs(aiCharacters) do
        aiCharacter:update(dt)
    end
end

function love.load(arg)
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    loadFruitImages()
    startGame()
end

function love.update(dt)
    updatePlayerMovement(dt)
    updateAICharacters(dt)

    -- Update camera position with linear interpolation for smoothing
    camera.x = camera.x + (character.x - camera.x - (WINDOW_WIDTH / 2) / camera.scale) * 0.1
    camera.y = camera.y + (character.y - camera.y - (WINDOW_HEIGHT / 2) / camera.scale) * 0.1

    WorldTimer = WorldTimer + dt
end

function love.draw(dt)
    love.graphics.push() -- Save the current coordinate transformation state
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.x, -camera.y)

    for x = 1, #World do
        for y = 1, #World[x] do
            local tile = World[x][y]
            if tile.Alive then
                local groundCell = GroundColors[x][y]
                if groundCell.Lush then
                    love.graphics.setColor(getTileColor(GRASS_COLORS, x, y))
                else
                    love.graphics.setColor(getTileColor(DIRT_COLORS, x, y))
                end
            else
                love.graphics.setColor(getTileColor(WALL_COLORS, x, y))
            end
            love.graphics.rectangle("fill", ((x - 1) * TILE_SIZE), ((y - 1) * TILE_SIZE), TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw Fruits
    for _, fruit in ipairs(Fruits) do
        if fruit.image then
            love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
            love.graphics.draw(fruit.image, (fruit.x - 1) * TILE_SIZE, (fruit.y - 1) * TILE_SIZE)
            if DEBUG then
                -- Draw debug box around fruit
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("line", (fruit.x - 1) * TILE_SIZE, (fruit.y - 1) * TILE_SIZE, TILE_SIZE,
                    TILE_SIZE)
            end
        end
    end

    -- Draw character
    character:draw()

    -- Draw AI characters
    for _, aiCharacter in ipairs(aiCharacters) do
        aiCharacter:draw()
    end

    if DEBUG then
        -- Draw debug box around character
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", character.x, character.y, character.width, character.height)
    end

    love.graphics.pop() -- Restore the previous coordinate transformation state
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    end
end
