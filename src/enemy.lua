local spritesheet = require('src.spritesheet')
local object = require('libs.classic')

math.randomseed(os.time())

ENEMY_SPEED = 300
ENEMY_SCALE = 2
ENEMY_SPAWN = {
    x = WINDOW_WIDTH - TILE_SIZE + math.random(20, 90),
    y = (WINDOW_HEIGHT / 2)
}

local Enemy = {} -- module
local enemy = object:extend()
local enemies = {}

SNEK = 'snek'
MEDUSA = 'medusa'
EYE = 'eye'
CAR = 'car'

local clearable = {}

local medusaDelay = 30.34
local snekDelay = 7.1055
local eyeDelay = 14.1138
local carDelay = 28.0188

local snektimer = 0
local medusatimer = 15
local eyeTimer = 10
local carTimer = 5

local difficultyDelay = 30
local difficultyTimer = difficultyDelay
local difficultyIncrement = 1

local announceMessage = ""
local announceDelay = 5
local announceTimer = announceDelay

function Enemy.New(entity, enemyType)
    local e = enemy(entity, enemyType)
    table.insert(enemies, e)
    return e
end

local function enemySprite(enemyType)
    local enemyTypeSpriteMap = {}
    enemyTypeSpriteMap[MEDUSA] = 'assets/images/medusa-anims.png'
    enemyTypeSpriteMap[EYE] = 'assets/images/eye-anims.png'
    enemyTypeSpriteMap[CAR] = 'assets/images/car-anims.png'
    enemyTypeSpriteMap[SNEK] = 'assets/images/snek-anims.png'
    return enemyTypeSpriteMap[enemyType]
end

function enemy:new(entity, enemyType)
    self.name = math.random(99999999)
    print("new " .. enemyType .. ": " .. self.name)
    self.enemyType = enemyType
    self.image = love.graphics.newImage(enemySprite(enemyType))
    self.animGrid = spritesheet.NewAnim8Grid(self.image, TILE_SIZE, TILE_SIZE)
    self.animations = {}
    self.animations.idle = Anim8.newAnimation(self.animGrid('1-6', 1), 0.2)
    self.animations.walk = Anim8.newAnimation(self.animGrid('1-4', 2), 0.1)
    self.animations.attac = Anim8.newAnimation(self.animGrid('1-5', 3), 0.1, function() self:resetAnim() end)
    self.animations.frozen = Anim8.newAnimation(self.animGrid('1-1', 1), 0.5, 'pauseAtEnd')
    self.animations.ded = Anim8.newAnimation(self.animGrid('2-3', 4), 0.3, 'pauseAtEnd')
    self.currentAnim8 = self.animations.walk

    self.x = entity.x
    if enemyType == EYE then
        self.y = entity.y - EyeVerticalAdjustment
    else
        self.y = entity.y
    end

    self.scaleX, self.scaleY = ENEMY_SCALE, ENEMY_SCALE
    self.width = TILE_SIZE * ENEMY_SCALE
    self.height = TILE_SIZE * ENEMY_SCALE

    self.frequency = math.random(523, 999) / 100000
    self.amplitude = WINDOW_HEIGHT / 2 + math.random(5, 20)
    self.speed = (ENEMY_SPEED + math.random(1, 40))

    print('speed ' .. self.speed .. ' amp ' .. self.amplitude .. ' freq ' .. self.frequency)
end

local function announce(message)
    announceTimer = announceDelay
    announceMessage = message
end

local function showAnnouncement(dt)
    if announceTimer > 0 then
        love.graphics.setColor(1,1,1)
        love.graphics.print(announceMessage, WINDOW_WIDTH / 6, WINDOW_HEIGHT / 2 + 30)
    end
end

local function pickSpawnEnemy(dt)
    difficultyTimer = difficultyTimer - dt
    if difficultyTimer <= 0 then
        difficultyTimer = difficultyDelay
        announce("DIFFICULTY INCREASE")
        snekDelay = snekDelay - difficultyIncrement
        medusaDelay = medusaDelay - difficultyIncrement
        carDelay = carDelay - difficultyIncrement
        eyeDelay = eyeDelay - difficultyIncrement
        if snekDelay < 1 then snekDelay = 1 end
        if carDelay < 1 then carDelay = 1 end
        if medusaDelay < 1 then medusaDelay = 1 end
        if eyeDelay < 1 then eyeDelay = 1 end
    end

    snektimer = snektimer - dt
    if snektimer <= 0 then
        Enemy.New(ENEMY_SPAWN, SNEK)
        snektimer = snekDelay
    end

    medusatimer = medusatimer - dt
    if medusatimer <= 0 then
        Enemy.New(ENEMY_SPAWN, MEDUSA)
        medusatimer = medusaDelay
    end

    eyeTimer = eyeTimer - dt
    if eyeTimer <= 0 then
        Enemy.New(ENEMY_SPAWN, EYE)
        eyeTimer = eyeDelay
    end

    carTimer = carTimer - dt
    if carTimer <= 0 then
        Enemy.New(ENEMY_SPAWN, CAR)
        carTimer = carDelay
    end
end

function enemy:attak()
    if self.frozen then return false end

    self.currentAnim8 = self.animations.attac
    return true
end

function enemy:resetAnim()
    self.currentAnim8 = self.animations.frozen
end

function enemy:hit(isBullet)
    if self.frozen then
        -- player or bullet kills
        self.currentAnim8 = self.animations.ded
        self.dead = true
    else
        if isBullet then
            self.frozen = true
        end
    end
end

function enemy:draw()
    love.graphics.setColor(1, 1, 1)
    self.currentAnim8:draw(
        self.image,
        self.x,
        self.y - self.height,
        0,
        self.scaleX,
        self.scaleY)
end

function enemy:checkCollision(playerX, playerY)
    local x1 = self.x
    local y1 = self.y
    local w1 = self.width
    local h1 = self.height

    local x2 = playerX
    local y2 = playerY + TILE_SIZE
    local w2 = TILE_SIZE
    local h2 = TILE_SIZE

    return x1 < x2 + w2 and
        x2 < x1 + w1 and
        y1 < y2 + h2 and
        y2 < y1 + h1
end

local medusaVerticalAdjustment = 380
EyeVerticalAdjustment = 34

function enemy:movementCalc(dt)
    if self.x < -(TILE_SIZE * 3) then
        table.insert(clearable, self.name)
    end

    if self.enemyType == MEDUSA then
        self.y = medusaVerticalAdjustment + (
            self.amplitude *
            math.sin(self.frequency * self.x)
        )
        self.x = self.x - (self.speed * dt)
    else
        self.x = self.x - dt * self.speed
    end
end

function enemy:update(dt, playerX, playerY)
    local collided = false
    if self:checkCollision(playerX, playerY) then
        self:attak()
        collided = true
    end
    self.currentAnim8:update(dt)

    if self.dead then return end

    self:movementCalc(dt)

    return collided
end

function Enemy.DrawEnemies()
    showAnnouncement()
    for _, e in ipairs(enemies) do
        e:draw()
    end
end

local function clearDead()
    for i, e in ipairs(enemies) do
        for j, name in ipairs(clearable) do
            if e.name == name then
                print("delete dead " .. name)
                table.remove(clearable, j)
                table.remove(enemies, i)
                return
            end
        end
    end
end

function Enemy.UpdateEnemies(dt, playerX, playerY)
    pickSpawnEnemy(dt)
    announceTimer = announceTimer - dt
    local collided = false
    for _, e in ipairs(enemies) do
        clearDead()
        local ec = e:update(dt, playerX, playerY)
        if ec then collided = true end
    end
    return collided
end

return Enemy
