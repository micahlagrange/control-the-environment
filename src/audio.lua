require('src.soundmanager')

local interruptSfxSource
local Audio = {}
local currentBGM
local pauseTimer = 0

local files = {
    achievement = 'assets/audio/success.mp3',
    explode = {
        'assets/audio/explode1.mp3',
        'assets/audio/explode2.mp3',
        'assets/audio/explode3.mp3',
    },
    mine = {
        'assets/audio/mine1.mp3',
        'assets/audio/mine2.mp3',
        'assets/audio/mine3.mp3',
        'assets/audio/mine4.mp3',
        'assets/audio/mine5.mp3',
    },
    linemine = 'assets/audio/line_mine.mp3',
    complaining = 'assets/audio/tension1.mp3',
    crunch = {
        'assets/audio/crunch.mp3',
        'assets/audio/crunch2.mp3',
        'assets/audio/slurp.mp3'
    },
    ick = {
        'assets/audio/quick blips.mp3',
    },
    click = 'assets/audio/click.mp3',
    settled = 'assets/audio/settled.mp3',
    doot = {
        'assets/audio/doot1.mp3',
        'assets/audio/doot23.mp3',
    },
    win = 'assets/audio/win.mp3',
    theme = 'assets/audio/Detached Floor.wav',
}

local idx = 1
local function getFile(name)
    if type(files[name]) == 'table' then
        local file = files[name][idx % #files[name] + 1]
        if idx > 10000 then
            idx = 1
        else
            idx = idx + 1
        end
        return file
    end
    return files[name]
end

function Audio.playSFX(name)
    return love.audio.play(getFile(name), 'static', false)
end

function Audio.playBGM(name)
    Audio.stopMusic()
    currentBGM = love.audio.play(files[name], 'stream', true)
    return name
end

function Audio.stopMusic()
    love.audio.stop(currentBGM)
end

function Audio.update(dt)
    love.audio.update()

    if pauseTimer > 0 then
        pauseTimer = pauseTimer - dt
        if pauseTimer <= 0 then
            currentBGM:play()
        end
    end
end

local monoSrc
function Audio.monoSFX(name)
    if monoSrc then monoSrc:stop() end
    monoSrc = love.audio.newSource(getFile(name), 'static')
    return love.audio.play(monoSrc)
end

function Audio.interruptMusicSFX(name)
    currentBGM:pause()
    interruptSfxSource = Audio.playSFX(name)
    if not interruptSfxSource then return end
    pauseTimer = interruptSfxSource:getDuration()
end

return Audio
