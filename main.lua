love.graphics.setDefaultFilter("nearest", "nearest")




local SEED = 'jonny' -- define a seed variable
local character = { x = 0, y = 0, dx = 0, dy = 0, width = CHARACTER_SIZE, height = CHARACTER_SIZE }
local camera = { x = 0, y = 0, scale = ZOOM_LEVEL }
local fruits = {}
local fruitImages = {}

local function randomInt(min, max)
    return math.floor(love.math.random() * (max - min + 1) + min)
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
    return World[math.floor(x / TILE_SIZE) + 1] and World[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1] and World[math.floor(x / TILE_SIZE) + 1][math.floor(y / TILE_SIZE) + 1].Alive
end

local function isCharacterPositionValid(x, y)
    return isCharacterInLiveCell(x, y) and
           isCharacterInLiveCell(x + character.width, y) and
           isCharacterInLiveCell(x, y + character.height) and
           isCharacterInLiveCell(x + character.width, y + character.height)
end

local function GenerateWorld()
    World = {}

    for x = 1, WORLD_WIDTH / TILE_SIZE do
        World[x] = {}
        for y = 1, WORLD_HEIGHT / TILE_SIZE do
            local value = randomInt(0, 100)
            if value < AUTOMATA_RATIO_PERCENT then
                World[x][y] = { Alive = true }
            else
                World[x][y] = { Alive = false }
            end
        end
    end

    WorldTimer = 0
    WorldUpdateCounter = 0

    -- Update the world to finish the generation
    while WorldUpdateCounter ~= WorldUpdateLimit do
        for x = 1, #World do
            for y = 1, #World[x] do
                local tile = World[x][y]
                local neighborsAlive = 0
                for i = 0, 9 do
                    if i ~= 4 then
                        local xi = math.floor(i % 3) - 1
                        local yi = math.floor(i / 3) - 1

                        if World[x + xi] and World[x + xi][y + yi] and World[x + xi][y + yi].Alive then
                            neighborsAlive = neighborsAlive + 1
                        end
                    end
                end

                if tile.Alive and neighborsAlive < 3 then
                    World[x][y].Alive = false
                end
                if not tile.Alive and neighborsAlive > 5 then
                    World[x][y].Alive = true
                end
            end
        end

        WorldUpdateCounter = WorldUpdateCounter + 1
    end

    -- Ensure the character spawns in a live cell
    repeat
        character.x = randomInt(1, WORLD_WIDTH)
        character.y = randomInt(1, WORLD_HEIGHT)
    until isCharacterPositionValid(character.x, character.y)

    -- Add fruits to a percentage of the live cells
    for x = 1, #World do
        for y = 1, #World[x] do
            if World[x][y].Alive and love.math.random() < FRUIT_PERCENTAGE then
                local fruitIndex = randomInt(1, #fruitImages)
                local fruitImage = fruitImages[fruitIndex]
                table.insert(fruits, { x = x, y = y, image = fruitImage })
            end
        end
    end
end

local function startGame()
    love.math.setRandomSeed(tonumber(SEED) or SEED:byte(1, -1)) -- set the seed for reproducibility, always coerce it to a number

    WorldTimer = 0
    WorldTimerLimit = 0.001
    WorldUpdateCounter = 0
    WorldUpdateLimit = 2

    GenerateWorld()
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

function love.load(arg)
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    loadFruitImages()
    startGame()
end

function love.update(dt)
    updatePlayerMovement(dt)

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
                love.graphics.setColor(1, 1, 1)          -- changed from 255, 255, 255 to 1, 1, 1
            else
                love.graphics.setColor(0.39, 0.39, 0.39) -- changed from 100, 100, 100 to 0.39, 0.39, 0.39
            end
            love.graphics.rectangle("fill", ((x - 1) * TILE_SIZE), ((y - 1) * TILE_SIZE), TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw fruits
    for _, fruit in ipairs(fruits) do
        if fruit.image then
            love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
            love.graphics.draw(fruit.image, (fruit.x - 1) * TILE_SIZE, (fruit.y - 1) * TILE_SIZE)
        end
    end

    -- Draw character
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", character.x + 1, character.y + 1, character.width - 2, character.height - 2)

    -- Draw debug box around character
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("line", character.x, character.y, character.width, character.height)

    love.graphics.pop() -- Restore the previous coordinate transformation state
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    end
end
