local game = require 'modules.game'
local moonshine = require 'libraries.moonshine'
local lfs = love.filesystem
local background = require 'modules.background'
local credits = require 'modules.credits'
local utility = require 'modules.utility'

background.doDrawBg = false

local mainmenu = {}

local buttons = {}
local effect
local gameFont
local gameFontLarge

local buttonWidth, buttonHeight = 180, 60
local buttonSpacing = 35
local hoverColor = {0.4, 1, 0.4, 0.6}
local normalColor = {0.4, 1, 0.4}
local clickedFlashDuration = 0.15
local clickedTimer, clickedButton = 0, nil

local cardImage, currentCardImage
local easterEggFiles = {}
local cardWidth, cardHeight = 120, 190

local konamiSequence = {"up", "up", "down", "down", "left", "right", "left", "right", "b", "a"}
local konamiIndex = 1

local cardTargetDX, cardTargetDY = 0, 0
local cardCurrentDX, cardCurrentDY = 0, 0
local wiggleTimer = 0
local stars = {}

function mainmenu.load()
    love.window.setTitle("Spade Knight")

    gameFont = love.graphics.newFont("source/fonts/Jersey10.ttf", 28)
    gameFontLarge = love.graphics.newFont("source/fonts/Jersey10.ttf", 72)
    love.graphics.setFont(gameFont)

    effect = moonshine(moonshine.effects.filmgrain)
    .chain(moonshine.effects.vignette)
    .chain(moonshine.effects.scanlines)
    .chain(moonshine.effects.chromasep)

    effect.vignette.opacity = 0.55
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2
    effect.filmgrain.size = 2
    effect.chromasep.radius = 1.5

    local screenW = love.graphics.getWidth()
    local totalWidth = (buttonWidth * 3) + (buttonSpacing * 2)
    local startX = (screenW / 2) - (totalWidth / 2)
    local startY = 200

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

    for i = 1, 200 do
        table.insert(stars, {x = love.math.random(0, screenW), y = love.math.random(0, love.graphics.getHeight()), speed = love.math.random(5, 20) / 10})
    end
end

function mainmenu.update(dt)
    background.updateAnimationFrame(dt) -- Update animation state
    background.update(dt) -- Update background logic
    
    if clickedButton then
        clickedTimer = clickedTimer - dt
        if clickedTimer <= 0 then
            clickedButton = nil
        end
    end

    wiggleTimer = wiggleTimer + dt * 2

    local mx, my = love.mouse.getPosition()
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 150  -- Adjusted cy to lower the card

    cardTargetDX = (mx - cx) / 90
    cardTargetDY = (my - cy) / 90

    cardCurrentDX = cardCurrentDX + (cardTargetDX - cardCurrentDX) * 5 * dt
    cardCurrentDY = cardCurrentDY + (cardTargetDY - cardCurrentDY) * 5 * dt

    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > love.graphics.getHeight() then
            star.y = 0
            star.x = love.math.random(0, love.graphics.getWidth())
        end
    end
end

function mainmenu.draw()
    effect(function()
        background.draw({0.05, 0.05, 0.1}, 0, stars)
        drawMenu()
    end)
end

function drawMenu()
    love.graphics.setFont(gameFontLarge)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Spade Knight", 0, 80 + math.sin(wiggleTimer) * 5, love.graphics.getWidth(), "center")

    love.graphics.setFont(gameFont)
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(buttons) do
        local isHovered = mx > button.x and mx < button.x + button.w and my > button.y and my < button.y + button.h
        local isClicked = (clickedButton == button)
        local color = normalColor
        local scale = 1

        if isClicked then
            color = {1, 1, 1}
        elseif isHovered then
            color = hoverColor
            scale = 1.1 + math.sin(wiggleTimer * 2) * 0.02
        end

        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", button.x + 4, button.y + 4, button.w, button.h, 10, 10)

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, button.x, button.y + (button.h / 4), button.w, "center")
    end

    drawCard(mx, my)
end

function drawCard(mx, my)
    local cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 150  -- Adjusted cy to lower the card

    local wiggleX = math.sin(wiggleTimer) * 0.05
    local wiggleY = math.cos(wiggleTimer) * 0.05

    local lift = math.sqrt(cardCurrentDX^2 + cardCurrentDY^2) * 30

    love.graphics.push()
    love.graphics.translate(cx, cy - lift)
    love.graphics.rotate(cardCurrentDX * 0.2 + wiggleX)
    love.graphics.scale(1, 1 + cardCurrentDY * 0.05 + wiggleY)

    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", -cardWidth/2, -cardHeight/2 + 8, cardWidth, cardHeight, 12, 12)

    love.graphics.setColor(1, 1, 1)
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