local background = {}

function background.draw(currentBgColor, gradientTime, stars)
    -- Gradient parameters
    local gradientAmplitude = 0.2  -- Controls the intensity of the gradient effect
    local gradientFrequency = 0.005 -- Controls the speed of the gradient effect

    -- Draw the gradient background
    for y = 0, 600, 2 do
        -- Calculate the color variation using a sine wave
        local colorVariation = (math.sin(gradientTime + y * gradientFrequency) + 1) / 2

        -- Adjust the background color based on the variation
        love.graphics.setColor(
            currentBgColor[1] + colorVariation * gradientAmplitude,
            currentBgColor[2] + colorVariation * gradientAmplitude,
            currentBgColor[3] + colorVariation * (gradientAmplitude + 0.1)  -- Slightly stronger effect on the blue channel
        )

        -- Draw a horizontal line for the gradient
        love.graphics.rectangle("fill", 0, y, 800, 2)
    end

    -- Draw the stars
    love.graphics.setColor(1, 1, 1, 0.8)  -- Set star color once
    for _, star in ipairs(stars) do
        love.graphics.points(star.x, star.y)
    end
end

return background