-- fullscreen.lua
local fullscreen = {}

-- Default screen size
local defaultWidth = 800
local defaultHeight = 600

-- Scaling information
local SCALE = {
    x = 1,
    y = 1,
    offsetX = 0,
    offsetY = 0
}

function fullscreen.init()
    -- Enable fullscreen mode
    --[[local fullscreenMode = true
    local _, _, flags = love.window.getMode()
    love.window.setMode(0, 0, {fullscreen = fullscreenMode, resizable = false})

    -- Get the current screen dimensions
    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- Calculate scaling factors
    local scaleX = screenWidth / defaultWidth
    local scaleY = screenHeight / defaultHeight
    local scale = math.min(scaleX, scaleY) -- Maintain aspect ratio

    -- Store scaling information
    SCALE.x = scale
    SCALE.y = scale
    SCALE.offsetX = (screenWidth - defaultWidth * scale) / 2
    SCALE.offsetY = (screenHeight - defaultHeight * scale) / 2

    -- Optional: Set default filter for pixel art
    love.graphics.setDefaultFilter("nearest", "nearest")]]
end

function fullscreen.apply()
    -- Apply scaling and offset to maintain aspect ratio
    --[[love.graphics.push()
    love.graphics.translate(SCALE.offsetX, SCALE.offsetY)
    love.graphics.scale(SCALE.x, SCALE.y)]]
end

function fullscreen.clear()
    -- Clear the scaling transformation
    --love.graphics.pop()
end

-- Optional: Handle window resizing (if you allow resizing)
function fullscreen.resize(width, height)
    -- Recalculate scaling factors
   --[[local scaleX = width / defaultWidth
    local scaleY = height / defaultHeight
    local scale = math.min(scaleX, scaleY)

    SCALE.x = scale
    SCALE.y = scale
    SCALE.offsetX = (width - defaultWidth * scale) / 2
    SCALE.offsetY = (height - defaultHeight * scale) / 2]]
end

return fullscreen  