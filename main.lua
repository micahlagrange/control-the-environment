local AUTOMATA_RATIO_PERCENT = 45
local SEED = 'defaultseed' -- define a seed variable

local function randomInt(min, max)
    return love.math.random() * (max - min + 1) + min
end

local function GenerateWorld()
    World = {}

    for x = 1, WINDOW_WIDTH / TILE_SIZE do
        World[x] = {}
        for y = 1, WINDOW_HEIGHT / TILE_SIZE do
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
end

function love.load(arg)
    love.math.setRandomSeed(tonumber(SEED) or SEED:byte(1, -1)) -- set the seed for reproducibility, always coerce it to a number
    WorldTimer = 0
    WorldTimerLimit = 0.001
    WorldUpdateCounter = 0
    WorldUpdateLimit = 2

    GenerateWorld()
end

function love.update(dt)
    if WorldUpdateCounter ~= WorldUpdateLimit and WorldTimer >= WorldTimerLimit then
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

        WorldTimer = WorldTimer - WorldTimerLimit
        WorldUpdateCounter = WorldUpdateCounter + 1
    end

    WorldTimer = WorldTimer + dt
end

function love.draw(dt)
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
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    end
end
