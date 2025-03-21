local background = {}

-- Load the background image
local bgImage = love.graphics.newImage("source/Sprites/Background/Background.png")

function background.draw(currentBgColor, gradientTime, stars)
    -- Draw the background image (scaled to the window size 800x600)
    love.graphics.setColor(1, 1, 1, 1)
    local scaleX = 800 / bgImage:getWidth()
    local scaleY = 600 / bgImage:getHeight()
    love.graphics.draw(bgImage, 0, 0, 0, scaleX, scaleY)
    
    -- Draw a gradient overlay
    local gradientAmplitude = 0.2  -- Intensity of gradient
    local gradientFrequency = 0.005 -- Speed of gradient effect
    for y = 0, 600, 2 do
        local colorVariation = (math.sin(gradientTime + y * gradientFrequency) + 1) / 2
        love.graphics.setColor(
            currentBgColor[1] + colorVariation * gradientAmplitude,
            currentBgColor[2] + colorVariation * gradientAmplitude,
            currentBgColor[3] + colorVariation * (gradientAmplitude + 0.1)
        )
        love.graphics.rectangle("fill", 0, y, 800, 2)
    end

    -- Draw the stars on top
    love.graphics.setColor(1, 1, 1, 0.8)
    for _, star in ipairs(stars) do
        love.graphics.points(star.x, star.y)
    end
end

return background
