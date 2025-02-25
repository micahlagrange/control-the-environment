love.graphics.setDefaultFilter("nearest", "nearest")

local tiles     = {}

-- libs
local Character = require("libs.character")

-- src classes
local Util      = require("src.util")
require("src.constants")
local Camera       = require("src.camera")
local camera       = Camera:new(0, 0, ZOOM_LEVEL)
local World        = require("src.world")
local world        = World:new(tiles, camera)
local Scoring      = require("src.scoring")
local scoring      = Scoring:new()
local Abilities    = require("src.abilities")
local abilities    = Abilities:new(world, scoring)

-- UI
local UI           = require("src.ui")
local ui           = UI:new(abilities, camera, scoring)

-- Locals
local aiCharacters = {}
local fruitImages  = {}
local playerView   = Character:new(world, WORLD_WIDTH / 2, WORLD_HEIGHT / 2, CHARACTER_SIZE, CHARACTER_SIZE, scoring)
local dragging     = false
local inputActive  = false
local inputText    = ""


local seed                = DEFAULT_SEED
local worldWidth          = WORLD_WIDTH
local worldHeight         = WORLD_HEIGHT
local worldUpdateLimit    = WORLD_UPDATE_LIMIT
local worldAutomataRatio  = WORLD_AUTOMATA_RATIO
local groundUpdateLimit   = GROUND_UPDATE_LIMIT
local groundAutomataRatio = GROUND_AUTOMATA_RATIO
local levelsPassed        = 0

local function getMaxCapitalists()
    return math.floor(worldWidth * worldHeight / 200000)
end

local function getMaxFruit()
    return getMaxCapitalists() * 2
end

local function seedStringToInt(seed)
    return tonumber(seed) or seed:byte(1, -1)
end

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
    love.math.setRandomSeed(seedStringToInt(seed) + x * 1000 + y)
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


local function isCharacterPositionValid(x, y)
    local tile = Util.worldToTileSpace(x, y)
    return Util.isTileAlive(tiles, tile.x, tile.y)
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
        for x = 1, width do
            for y = 1, height do
                grid[x][y].Alive = newGrid[x][y].Alive
            end
        end
    end
    return grid
end

local function GenerateWorld()
    -- nasty globals
    Fruits = {}
    local width = worldWidth / TILE_SIZE
    local height = worldHeight / TILE_SIZE

    for x = 1, width do
        if not tiles[x] then
            tiles[x] = {}
        end
        for y = 1, height do
            if not tiles[x][y] then
                tiles[x][y] = { Alive = randomInt(0, 100) < worldAutomataRatio }
            else
                tiles[x][y].Alive = randomInt(0, 100) < worldAutomataRatio
            end
        end
    end

    applyCellularAutomata(tiles, width, height, worldUpdateLimit, 3, 3)

    -- Add AI characters
    if DEBUG then
        print("Adding " .. getMaxCapitalists() .. " AI characters")
    end
    -- Empty out aiCharacters without reassigning the table
    for i = #aiCharacters, 1, -1 do
        aiCharacters[i] = nil
    end

    for i = 1, getMaxCapitalists() do
        local aiCharacter
        repeat
            aiCharacter = Character:new(
                world,
                randomInt(1, worldWidth),
                randomInt(1, worldHeight),
                CHARACTER_SIZE,
                CHARACTER_SIZE,
                scoring
            )
        until isCharacterPositionValid(aiCharacter.x, aiCharacter.y)
        aiCharacter.id = #aiCharacters + 1
        table.insert(aiCharacters, aiCharacter)
    end

    -- Add fruit
    repeat
        local x = randomInt(1, width)
        local y = randomInt(1, height)
        if not tiles[x] or not tiles[x][y] then
            -- no idea why, but it fails here when the seed contains only 's' or 'i' .......
            print("Invalid tile at " .. x .. ", " .. y)
        else
            if tiles[x][y].Alive or love.math.random() < 0.85 then -- 85% chance of spawning fruit on a dead cell
                local fruitIndex = randomInt(1, #fruitImages)
                local fruitImage = fruitImages[fruitIndex]
                table.insert(Fruits, { x = x, y = y, image = fruitImage })
            end
        end
    until #Fruits >= getMaxFruit()
end

local function GenerateGroundColors()
    GroundColors = {}
    local width = worldHeight / TILE_SIZE
    local height = worldHeight / TILE_SIZE

    for x = 1, width do
        GroundColors[x] = {}
        for y = 1, height do
            GroundColors[x][y] = { Alive = randomInt(0, 100) < groundAutomataRatio }
        end
    end

    GroundColors = applyCellularAutomata(GroundColors, width, height, groundUpdateLimit, 3, 3)
end

local function startGame()
    print("Starting game with seed: " .. seed)
    love.math.setRandomSeed(seedStringToInt(seed)) -- set the seed for reproducibility, always coerce it to a number

    scoring:reset()
    GenerateWorld()
    GenerateGroundColors()
end

local function nextLevel()
    levelsPassed = levelsPassed + 1
    love.math.setRandomSeed(seedStringToInt(seed) + levelsPassed)

    if worldAutomataRatio > 1 then
        worldAutomataRatio = worldAutomataRatio - 1
    end

    -- increase world area by 10%
    worldWidth = worldWidth * 1.1
    worldHeight = worldHeight * 1.1

    GenerateWorld()
    GenerateGroundColors()
end

local function updatePlayerView(dt)
    local dx, dy = 0, 0
    if not inputActive then
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
local fruitUpdateInterval = 1 -- seconds
local giveUpTimer = 0

local function updateAICharacters(dt)
    fruitUpdateTimer = fruitUpdateTimer + dt
    giveUpTimer = giveUpTimer + dt
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

local function startGameWithNewSeed(newSeed)
    seed = newSeed
    startGame()
end

local function increaseWorldAutomataRatio()
    if worldAutomataRatio < 100 then
        worldAutomataRatio = worldAutomataRatio + 1
        startGame()
    end
end

local function decreaseWorldAutomataRatio()
    if worldAutomataRatio > 1 then
        worldAutomataRatio = worldAutomataRatio - 1
        startGame()
    end
end

local function increaseWorldUpdateLimit()
    if worldUpdateLimit < 100 then
        worldUpdateLimit = worldUpdateLimit + 1
        startGame()
    end
end

local function decreaseWorldUpdateLimit()
    if worldUpdateLimit > 1 then
        worldUpdateLimit = worldUpdateLimit - 1
        startGame()
    end
end

-- LOVE FUNCTIONS

function love.load(arg)
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    loadFruitImages()
    startGame()
    ui:addButton(ABILITY_SELECT, 1, 1)
    ui:addButton(ABILITY_DIG, 1, 3)
    ui:addButton(SYSTEM_EXIT, 19, 15)
    ui:addButton(SYSTEM_RELOAD, 19, 1, function() startGame() end)
    ui:addButton(SYSTEM_CHANGE_SEED, 19, 3, function()
        inputActive = true
        inputText = ""
    end)
    ui:addButton(SYSTEM_INCREASE_UPDATES, 18, 1, increaseWorldUpdateLimit)
    ui:addButton(SYSTEM_DECREASE_UPDATES, 18, 2, decreaseWorldUpdateLimit)
    ui:addButton(SYSTEM_INCREASE_AUTOMATA_RATIO, 18, 3, increaseWorldAutomataRatio)
    ui:addButton(SYSTEM_DECREASE_AUTOMATA_RATIO, 18, 4, decreaseWorldAutomataRatio)
end

function love.update(dt)
    if not inputActive then
        updatePlayerView(dt)
        updateAICharacters(dt)

        -- Update camera position
        camera:update(dt, playerView.x, playerView.y, playerView.width, playerView.height, WINDOW_WIDTH, WINDOW_HEIGHT)
    end

    if #Fruits <= 0 then nextLevel() end
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
            if ANIMATION_DEBUG then
                -- Highlight the whole tile with transparent white
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("fill", (fruit.x - 1) * TILE_SIZE, (fruit.y - 1) * TILE_SIZE, TILE_SIZE,
                    TILE_SIZE)

                -- Draw the tile coordinates below the fruit
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("(" .. fruit.x .. ", " .. fruit.y .. ")", (fruit.x - 1) * TILE_SIZE,
                    (fruit.y) * TILE_SIZE)
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
    end
    if MAP_DEBUG then
        world:drawTileDebugSquares()
    end

    -- highlight the hovered tile or button
    local x, y = love.mouse.getPosition()
    local hoveredTile = ui:getHoveredTile(x, y)
    local highlightColor = abilities:getHighlightColor() or { 1, 1, 1, .5 }
    love.graphics.setColor(highlightColor)
    if hoveredTile then
        love.graphics.rectangle("fill", (hoveredTile.x - 1) * TILE_SIZE, (hoveredTile.y - 1) * TILE_SIZE, TILE_SIZE,
            TILE_SIZE)
    end
    camera:reset()
    -- draw ui last
    ui:draw()

    -- display world update limit
    love.graphics.print("passes: " .. worldUpdateLimit, WINDOW_WIDTH - 100, 5)
    love.graphics.print("ratio: " .. worldAutomataRatio, WINDOW_WIDTH - 100, 20)

    if inputActive then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Enter new seed: " .. inputText, 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, "center")
    end
end

function love.keypressed(key)
    if inputActive then
        if key == "return" or key == "kpenter" then
            inputActive = false
            startGameWithNewSeed(inputText)
        elseif key == "backspace" then
            inputText = inputText:sub(1, -2)
        end
    end
end

function love.textinput(t)
    if inputActive then
        inputText = inputText .. t
    end
end

function love.keyreleased(key)
    if not inputActive then
        if key == "escape" then
            love.event.quit()
        elseif key == "=" or key == "+" then
            camera:zoom(1.1)
        elseif key == "-" then
            camera:zoom(0.9)
        end
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
        world:debugClick(x, y)
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
