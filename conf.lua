DEBUG = true
SCALE = 1
WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768
TILE_SIZE = 16
AUTOMATA_RATIO_PERCENT = 50

function love.conf(t)
    t.title = "GameNameGoesHere"
    t.version = "11.4" -- It's a lie, we actually use 11.5 but itch.io throws a dumb error!
    t.console = true
    t.window.width = WINDOW_WIDTH
    t.window.height = WINDOW_HEIGHT
    t.window.vsync = 0
end