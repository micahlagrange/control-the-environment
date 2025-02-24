UI_DEBUG = false
PATH_DEBUG = false
DEBUG = false
MAP_DEBUG = false
SCALE = 1

WINDOW_WIDTH = 1200
WINDOW_HEIGHT = 800
WORLD_WIDTH = 600
WORLD_HEIGHT = 600
TILE_SIZE = 16
WORLD_AUTOMATA_RATIO = 38
WORLD_UPDATE_LIMIT = 3
GROUND_AUTOMATA_RATIO = 29
GROUND_UPDATE_LIMIT = 20
CHARACTER_SIZE = TILE_SIZE * .8
PLAYER_VIEW_MOVE_SPEED = 1000
ZOOM_LEVEL = 2 -- Configurable zoom level

function love.conf(t)
    t.title = "GameNameGoesHere"
    t.version = "11.4" -- It's a lie, we actually use 11.5 but itch.io throws a dumb error!
    t.console = false
    t.window.width = WINDOW_WIDTH
    t.window.height = WINDOW_HEIGHT
    t.window.vsync = 0
end
