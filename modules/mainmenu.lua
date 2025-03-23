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
local buttonSpacing = 20 -- Reduced spacing between buttons
local hoverColor = {0.2, 0.6, 1, 0.8} -- Cosmic blue hover color
local normalColor = {0.1, 0.3, 0.6} -- Darker cosmic blue normal color
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

local version = "v0.40-JamEdition"

-- Load main menu theme music as a streaming source and set to loop
local mainTheme = love.audio.newSource("source/Music/maintheme.wav", "stream")
mainTheme:setLooping(true)

-- Load the button hover SFX (blipSelect)
local buttonSelectSfx = love.audio.newSource("source/SFX/blipSelect.wav", "static")
local lastHoveredButtonIndex = nil

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
    local screenH = love.graphics.getHeight()
    local startX = 50 -- Buttons on the left side
    local startY = 300 -- Buttons lowered

    local menuItems = {"Play", "Credits", "Quit"}
    local buttonWidths = {220, 180, 140} -- Different widths for Play, Credits, Quit
    for i, text in ipairs(menuItems) do
        table.insert(buttons, {
            text = text,
            x = startX,
            y = startY + (i - 1) * (buttonHeight + buttonSpacing),
            w = buttonWidths[i],
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
        table.insert(stars, {x = love.math.random(0, screenW), y = love.math.random(0, screenH), speed = love.math.random(5, 20) / 10})
    end

    -- Start main menu music
    mainTheme:play()
end

function mainmenu.update(dt)
    background.update(dt)

    if clickedButton then
        clickedTimer = clickedTimer - dt
        if clickedTimer <= 0 then
            clickedButton = nil
        end
    end

    wiggleTimer = wiggleTimer + dt * 2

    -- Update stars for background
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > love.graphics.getHeight() then
            star.y = 0
            star.x = love.math.random(0, love.graphics.getWidth())
        end
    end

    -- Check for hover over buttons and play SFX if needed
    local mx, my = love.mouse.getPosition()
    local hoveredIndex = nil
    for i, btn in ipairs(buttons) do
        if mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h then
            hoveredIndex = i
            break
        end
    end
    if hoveredIndex and hoveredIndex ~= lastHoveredButtonIndex then
        buttonSelectSfx:play()
    end
    lastHoveredButtonIndex = hoveredIndex
end

function mainmenu.draw()
    effect(function()
        background.draw({0.02, 0.02, 0.05}, 0, stars) -- Darker cosmic background
        drawMenu()
    end)
end

function drawMenu()
    local banner = love.graphics.newImage("source/Sprites/banner.png")
    local bannerScale = 0.5 -- Adjust scale as needed
    local bannerX = (love.graphics.getWidth() / 2) - (banner:getWidth() * bannerScale / 2) -- Centered at the top
    local bannerY = 50 -- Banner at the top

    love.graphics.setColor(1, 1, 1, 0.9) -- Adjusted transparency for the banner
    love.graphics.draw(banner, bannerX, bannerY, 0, bannerScale, bannerScale)

    love.graphics.setFont(gameFont)
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(buttons) do
        local isHovered = mx > button.x and mx < button.x + button.w and my > button.y and my < button.y + button.h
        local isClicked = (clickedButton == button)
        local color = normalColor
        local scale = 1

        -- Hover feedback: Slightly scale up and change color
        if isHovered then
            scale = 1.05
            color = hoverColor
        end

        -- Click feedback: Flash white briefly
        if isClicked then
            color = {1, 1, 1} -- White flash
        end

        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", button.x + 4, button.y + 4, button.w, button.h, 10, 10)

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, button.x, button.y + (button.h / 4), button.w, "center")
    end

    drawCard() -- Draw the card in its static position

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf(version, love.graphics.getWidth() - 200, love.graphics.getHeight() - 40, 200, "right")
end

function drawCard()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2 + 150

    local wiggleX = math.sin(wiggleTimer) * 0.05
    local wiggleY = math.cos(wiggleTimer) * 0.05

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(wiggleX)
    love.graphics.scale(1, 1 + wiggleY)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", -cardWidth/2, -cardHeight/2, cardWidth, cardHeight, 12, 12)
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
                    mainTheme:stop() -- Stop main menu music when starting game
                elseif btn.action == "quit" then
                    love.event.quit()
                elseif btn.action == "credits" then
                    currentState = "credits"
                    credits.load()
                    mainTheme:stop() -- Stop main menu music
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
