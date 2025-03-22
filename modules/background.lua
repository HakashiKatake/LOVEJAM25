local background = {}

-- Configuration
background.doDrawBg = true
background.starCount = 200  -- Number of stars
background.starSpeed = 20   -- Speed of star movement
background.gridSize = 50    -- Size of the grid cells
background.gridSpeed = 5    -- Speed of grid movement
background.spiralCount = 3  -- Number of spirals
background.spiralSpeed = 1  -- Speed of spiral rotation
background.spiralRadius = 300 -- Radius of spirals
background.drawEffects = true -- Whether to draw grid, spirals, gradient, and stars

-- Animation state
local gradientTime = 0 -- Used for gradient animation

-- Load assets
local bgImage = love.graphics.newImage("source/Sprites/Background/Background.png")

-- Initialize stars
local stars = {}
for i = 1, background.starCount do
    stars[i] = {
        x = math.random(0, 800),
        y = math.random(0, 600),
        size = math.random(1, 3),
        alpha = math.random(0.5, 1),
        speed = math.random(1, 3)
    }
end

-- Initialize grid
local grid = {}
for x = 0, 800, background.gridSize do
    for y = 0, 600, background.gridSize do
        table.insert(grid, { x = x, y = y })
    end
end

-- Initialize spirals
local spirals = {}
for i = 1, background.spiralCount do
    spirals[i] = {
        angle = math.random(0, 360),
        radius = math.random(100, background.spiralRadius),
        speed = math.random(0.5, 1.5)
    }
end

-- Function to update animation state
function background.updateAnimationFrame(dt)
    gradientTime = gradientTime + dt -- Update gradient animation time
end

function background.update(dt)
    -- Update stars (move them downward and reset when they go off-screen)
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed * background.starSpeed * dt
        if star.y > 600 then
            star.y = 0
            star.x = math.random(0, 800)
        end
    end

    -- Update grid (move it diagonally)
    for _, cell in ipairs(grid) do
        cell.x = cell.x - background.gridSpeed * dt
        cell.y = cell.y - background.gridSpeed * dt
        if cell.x < 0 then cell.x = 800 end
        if cell.y < 0 then cell.y = 600 end
    end

    -- Update spirals (rotate them)
    for _, spiral in ipairs(spirals) do
        spiral.angle = spiral.angle + spiral.speed * background.spiralSpeed * dt
        if spiral.angle > 360 then spiral.angle = spiral.angle - 360 end
    end
end

function background.draw(currentBgColor)
    -- 1) Draw the background image (scaled to fit the screen)
    if background.doDrawBg then
        love.graphics.setColor(1, 1, 1, 1)
        local scaleX = 800 / bgImage:getWidth()
        local scaleY = 600 / bgImage:getHeight()
        love.graphics.draw(bgImage, 0, 0, 0, scaleX, scaleY)
    end

    -- 2) Draw effects (grid, stars, spirals, and gradient) if enabled
    if background.drawEffects then
        -- Draw a subtle grid overlay (animated diagonally)
        love.graphics.setColor(1, 1, 1, 0.1)
        for _, cell in ipairs(grid) do
            love.graphics.rectangle("line", cell.x, cell.y, background.gridSize, background.gridSize)
        end

        -- Draw stars (animated downward with twinkling effect)
        love.graphics.setColor(1, 1, 1, 1)
        for _, star in ipairs(stars) do
            local alpha = star.alpha * (0.8 + 0.2 * math.sin(love.timer.getTime() * star.speed))
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.circle("fill", star.x, star.y, star.size)
        end

        -- Draw spirals (rotating procedural shapes)
        love.graphics.setColor(1, 1, 1, 0.3)
        for _, spiral in ipairs(spirals) do
            local centerX, centerY = 400, 300
            for i = 1, 360, 10 do
                local angle = math.rad(spiral.angle + i)
                local x = centerX + spiral.radius * math.cos(angle) * (i / 360)
                local y = centerY + spiral.radius * math.sin(angle) * (i / 360)
                love.graphics.circle("fill", x, y, 2 * (i / 360))
            end
        end

        -- Draw a subtle gradient overlay (animated over time)
        local gradientAmplitude = 0.2
        local gradientFrequency = 0.005
        for y = 0, 600, 2 do
            local colorVariation = (math.sin(gradientTime + y * gradientFrequency) + 1) / 2
            love.graphics.setColor(
                currentBgColor[1] + colorVariation * gradientAmplitude,
                currentBgColor[2] + colorVariation * gradientAmplitude,
                currentBgColor[3] + colorVariation * (gradientAmplitude + 0.1),
                0.3  -- Semi-transparent gradient
            )
            love.graphics.rectangle("fill", 0, y, 800, 2)
        end
    end
end

return background