DEBUG = false
SCALE = 1

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
WORLD_WIDTH = 1200
WORLD_HEIGHT = 1200
TILE_SIZE = 16
AUTOMATA_RATIO_PERCENT = 45
CHARACTER_SIZE = TILE_SIZE * 0.8
FRUIT_PERCENTAGE = 0.009 -- Configurable fruit percentage
ZOOM_LEVEL = 2 -- Configurable zoom level

function love.conf(t)
    t.title = "GameNameGoesHere"
    t.version = "11.4" -- It's a lie, we actually use 11.5 but itch.io throws a dumb error!
    t.console = true
    t.window.width = WINDOW_WIDTH
    t.window.height = WINDOW_HEIGHT
    t.window.vsync = 0
end
