local game = require 'modules.game'
local moonshine = require 'libraries.moonshine'
local lfs = love.filesystem
local background = require 'modules.background'
local credits = require 'modules.credits'

local mainmenu = {}

local buttons = {}
local effect
local gameFont
local gameFontLarge

local buttonWidth = 160  -- Button width
local buttonHeight = 50  -- Button height
local buttonSpacing = 25 -- Spacing between buttons
local hoverColor = {0.4, 0.8, 1}
local normalColor = {0.2, 0.6, 1}
local clickedFlashDuration = 0.15
local clickedTimer = 0
local clickedButton = nil

local cardImage
local easterEggFiles = {}
local currentCardImage
local cardWidth, cardHeight = 160, 230  

local konamiSequence = {"up","up","down","down","left","right","left","right","b","a"}
local konamiIndex = 1

function mainmenu.load()
    love.window.setTitle("LÖVEJAM25")
    gameFont = love.graphics.newFont("source/fonts/Jersey10.ttf", 28)
    gameFontLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 69)
    love.graphics.setFont(gameFont)

    effect = moonshine(moonshine.effects.filmgrain)
        .chain(moonshine.effects.vignette)
        .chain(moonshine.effects.scanlines)
        .chain(moonshine.effects.chromasep)

    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2

    local screenW, _ = love.graphics.getDimensions()
    local totalWidth = (buttonWidth * 3) + (buttonSpacing * 2)
    local startX = (screenW / 2) - (totalWidth / 2)
    local startY = 150

    local menuItems = {"Play", "Credits", "Quit"}
    for i, text in ipairs(menuItems) do
        table.insert(buttons, {
            text = text,
            x = startX + (i - 1) * (buttonWidth + buttonSpacing),
            y = startY,
            w = buttonWidth,
            h = buttonHeight,
            action = text:lower()
        })
    end

    cardImage = love.graphics.newImage("source/Sprites/Cards/maincard.png")
    currentCardImage = cardImage

    for _, file in ipairs(lfs.getDirectoryItems("source/Sprites/Eastereggs")) do
        if file:match("%.png$") then
            table.insert(easterEggFiles, file)
        end
    end
end

function mainmenu.update(dt)
    if clickedButton then
        clickedTimer = clickedTimer - dt
        if clickedTimer <= 0 then
            clickedButton = nil
        end
    end
end

function mainmenu.draw()
    local gradientTime = 0
    local stars = {}
    local currentBgColor = {0.1, 0.1, 0.2}  
    local targetBgColor = {0.1, 0.1, 0.2}   
    local colorTransitionSpeed = 1       

    background.draw(currentBgColor, gradientTime, stars)
    for i = 1, 200 do
        table.insert(stars, {x = love.math.random(0, love.graphics.getWidth()), y = love.math.random(0, love.graphics.getHeight())})
    end
    

    if effect then
        effect(function()
            drawMenu()
        end)
    else
        drawMenu()
    end
end

function drawMenu()
    love.graphics.setFont(gameFontLarge)
    love.graphics.printf("LÖVEJAM25", 0, 60, love.graphics.getWidth(), "center")
    love.graphics.setFont(gameFont)

    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(buttons) do
        local isHovered = mx > button.x and mx < button.x + button.w and my > button.y and my < button.y + button.h
        local isClicked = (clickedButton == button)
        local color = {0.1, 0.8, 0.1}
        local scale = 1

        if isClicked then
            color = {1, 1, 1}
        elseif isHovered then
            color = {0.4, 1, 0.4}
            scale = 1.07
        end

        local drawX = button.x - (button.w * (scale - 1)) / 2
        local drawY = button.y - (button.h * (scale - 1)) / 2
        local drawW = button.w * scale
        local drawH = button.h * scale

        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", drawX + 4, drawY + 4, drawW, drawH, 8, 8)  -- Reduced corner rounding

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 8, 8)  -- Reduced corner rounding

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, drawX, drawY + (drawH / 4), drawW, "center")
    end

    local mx, my = love.mouse.getPosition()
    drawCard(mx, my)
end

function drawCard(mx, my)
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2 + 100

    -- Adjust responsiveness for smoother movement
    local dx = (mx - cx) / 80  -- Smoother responsiveness
    local dy = (my - cy) / 80  -- Smoother responsiveness

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(-dx * 0.15)  -- Smoother rotation
    love.graphics.scale(1, 1 + dy * 0.03)  -- Smoother scaling
    love.graphics.draw(currentCardImage, -cardWidth/2, -cardHeight/2, 0, cardWidth / currentCardImage:getWidth(), cardHeight / currentCardImage:getHeight())
    love.graphics.pop()
end

function mainmenu.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(buttons) do
            if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                clickedButton = btn
                clickedTimer = clickedFlashDuration

                if btn.action == "play" then
                    currentState = "game"
                    game.load()
                elseif btn.action == "quit" then
                    love.event.quit()
                elseif btn.action == "credits" then
                    currentState = "credits"
                    credits.load()  
                end
            end
        end
    end
end

function mainmenu.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == konamiSequence[konamiIndex] then
        konamiIndex = konamiIndex + 1
        if konamiIndex > #konamiSequence then
            if #easterEggFiles > 0 then
                local randomFile = easterEggFiles[love.math.random(#easterEggFiles)]
                currentCardImage = love.graphics.newImage("source/Sprites/Eastereggs/" .. randomFile)
            end
            konamiIndex = 1
        end
    else
        konamiIndex = 1
    end
end

return mainmenu