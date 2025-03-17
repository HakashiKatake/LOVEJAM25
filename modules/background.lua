local background = {}

function background.draw(currentBgColor, gradientTime, stars)
    for i = 0, 600, 2 do
        local c = (math.sin(gradientTime + i * 0.005) + 1) / 2  
        love.graphics.setColor(
            currentBgColor[1] + c * 0.2,
            currentBgColor[2] + c * 0.2,
            currentBgColor[3] + c * 0.3
        )
        love.graphics.rectangle("fill", 0, i, 800, 2)
    end

    for _, star in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.points(star.x, star.y)
    end
end

return background
