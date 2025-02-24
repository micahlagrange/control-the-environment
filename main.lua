love.graphics.setDefaultFilter("nearest", "nearest")

local tiles = {}

-- libs
local Character = require("libs.character")

-- src classes
require("src.constants")
local Camera       = require("libs.camera")
local camera       = Camera:new(0, 0, ZOOM_LEVEL)
local World        = require("src.world")
local world        = World:new(tiles, camera)
local Abilities    = require("src.abilities")
local abilities    = Abilities:new(world)
local UI           = require("src.ui")
local ui           = UI:new(abilities)

-- Locals
local aiCharacters = {}
local fruitImages  = {}
local playerView   = Character:new(world, 0, 0, CHARACTER_SIZE, CHARACTER_SIZE)

local seed         = DEFAULT_SEED

-- Constants / vars
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
    local seed = tonumber(seed) or seed:byte(1, -1)
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

local aiCharacterImage

local function loadAICharacterImage()
    aiCharacterImage = love.graphics.newImage("assets/images/guys/whitecollar.png")
end

local function isCharacterInLiveCell(x, y)
    return tiles[math.floor(x / TILE_SIZE) + 1] and tiles[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1] and
        tiles[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1].Alive
end

local function isCharacterPositionValid(x, y)
    return isCharacterInLiveCell(x, y) and
        isCharacterInLiveCell(x + playerView.width, y) and
        isCharacterInLiveCell(x, y + playerView.height) and
        isCharacterInLiveCell(x + playerView.width, y + playerView.height)
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
    -- tiles = {} -- empty the world OOPS THIS BROKE IT?
    local width = WORLD_WIDTH / TILE_SIZE
    local height = WORLD_HEIGHT / TILE_SIZE

    for x = 1, width do
        tiles[x] = {}
        for y = 1, height do
            tiles[x][y] = { Alive = randomInt(0, 100) < WORLD_AUTOMATA_RATIO }
        end
    end

    tiles = applyCellularAutomata(tiles, width, height, WORLD_UPDATE_LIMIT, 3, 3)

    -- Ensure the playerView spawns in a live cell
    repeat
        playerView.x = randomInt(1, WORLD_WIDTH)
        playerView.y = randomInt(1, WORLD_HEIGHT)
    until isCharacterPositionValid(playerView.x, playerView.y)

    -- Add AI characters
    for i = 1, 5 do
        local aiCharacter
        repeat
            aiCharacter = Character:new(
                world,
                randomInt(1, WORLD_WIDTH),
                randomInt(1, WORLD_HEIGHT),
                CHARACTER_SIZE,
                CHARACTER_SIZE,
                aiCharacterImage
            )
        until isCharacterPositionValid(aiCharacter.x, aiCharacter.y)
        aiCharacter.id = #aiCharacters + 1
        table.insert(aiCharacters, aiCharacter)
    end

    -- Add fruit to a percentage of the cells
    for x = 1, width do
        for y = 1, height do
            if #Fruits < MAX_FRUIT and love.math.random() < FRUIT_PERCENTAGE then
                if tiles[x][y].Alive or love.math.random() < 0.5 then
                    local fruitIndex = randomInt(1, #fruitImages)
                    local fruitImage = fruitImages[fruitIndex]
                    table.insert(Fruits, { x = x, y = y, image = fruitImage })
                end
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
            GroundColors[x][y] = { Alive = randomInt(0, 100) < GROUND_AUTOMATA_RATIO }
        end
    end

    GroundColors = applyCellularAutomata(GroundColors, width, height, GROUND_UPDATE_LIMIT, 3, 3)
end

local function startGame()
    love.math.setRandomSeed(tonumber(seed) or seed:byte(1, -1)) -- set the seed for reproducibility, always coerce it to a number

    loadAICharacterImage()
    GenerateWorld()
    GenerateGroundColors()
end

local function updatePlayerView(dt)
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
    dx, dy = dx * PLAYER_VIEW_MOVE_SPEED * dt, dy * PLAYER_VIEW_MOVE_SPEED * dt

    -- Calculate new position
    local newX = playerView.x + dx
    local newY = playerView.y + dy

    playerView.x = newX
    playerView.y = newY
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

local dragging = false

function love.load(arg)
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    loadFruitImages()
    startGame()
    ui:addButton(ABILITY_DIG, 4, 15)
    ui:addButton(SYSTEM_EXIT, 15, 0)
end

function love.update(dt)
    updatePlayerView(dt)
    updateAICharacters(dt)

    -- Update camera position
    camera:update(dt, playerView.x, playerView.y, playerView.width, playerView.height, WINDOW_WIDTH, WINDOW_HEIGHT)
end

function love.draw(dt)
    camera:apply()

    for x = 1, #tiles do
        for y = 1, #tiles[x] do
            local tile = tiles[x][y]
            if tile.Alive then
                local groundCell = GroundColors[x][y]
                if groundCell.Alive then
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

    -- Draw AI characters
    for _, aiCharacter in ipairs(aiCharacters) do
        aiCharacter:draw()
    end

    if DEBUG then
        -- Draw debug box around playerView
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", playerView.x, playerView.y, playerView.width, playerView.height)
        -- Draw debug squares on world tiles
        world:drawTileDebugSquares()
    end

    camera:reset()
    -- draw ui last
    ui:draw()
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "=" or key == "+" then
        camera:zoom(1.1)
    elseif key == "-" then
        camera:zoom(0.9)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        camera:zoom(1.1)
    elseif y < 0 then
        camera:zoom(0.9)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        local clickedButton = ui:clickedButton(x, y)
        if clickedButton then
            ui:doButtonClick(clickedButton)
        elseif abilities.selectedAbility then
            abilities:useAbility(x, y)
        end
    end
    if button == 2 and dragging then
        dragging = false
    end
end

function love.mousepressed(x, y, button)
    if button == 2 then
        dragging = true
    end
end

function love.mousemoved(x, y, dx, dy)
    if dragging then
        playerView.x = playerView.x - dx
        playerView.y = playerView.y - dy
    end
end
