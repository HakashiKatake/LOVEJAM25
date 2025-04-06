local game = require 'modules.game'
local moonshine = require 'libraries.moonshine'
local lfs = love.filesystem
local background = require 'modules.background'
local credits = require 'modules.credits'
local utility = require 'modules.utility'
local fullscreen = require 'modules.fullscreen'

background.doDrawBg = false

local mainmenu = {}

local buttons = {}
local effect
local gameFont
local gameFontLarge

local buttonWidth, buttonHeight = 180, 60
local buttonSpacing = 20
local hoverColor = {0.2, 0.6, 1, 0.8}
local normalColor = {0.1, 0.3, 0.6}
local clickedFlashDuration = 0.15
local clickedTimer, clickedButton = 0, nil

local cardImage, currentCardImage
local easterEggFiles = {}
local cardWidth, cardHeight = 120, 190

local konamiSequence = {"up", "up", "down", "down", "left", "right", "left", "right", "b", "a"}
local konamiIndex = 1

local wiggleTimer = 0
local stars = {}

local version = "v0.57-FirstEdition"

-- Enhanced Now Playing effects
local nowPlayingText = "Now Playing: Shuffle the Deck by MemoDev"
local nowPlayingTimers = {}
local nowPlayingOffsets = {}
local dancePhase = 0
local danceSpeed = 0
local isDancing = false
local danceTimer = 0
local danceDuration = 0
local flashTimer = 0
local flashDuration = 1.2
local flashIntensity = 0
local flashColor = {1, 1, 0.7}

-- Title animation variables
local titleScale = 1
local titleScaleDirection = 1
local titleScaleSpeed = 0.2
local titleRotation = 0
local titleRotationSpeed = 0.5
local titleYOffset = 0
local titleBobSpeed = .05
local titleBobAmount = 3

local mainTheme = love.audio.newSource("source/Music/maintheme.mp3", "stream")
mainTheme:setLooping(true)

local buttonSelectSfx = love.audio.newSource("source/SFX/blipSelect.wav", "static")
local buttonClickSfx = love.audio.newSource("source/SFX/click.wav", "static")
local lastHoveredButtonIndex = nil

function mainmenu.load()
    love.window.setTitle("Knight Spade")
    fullscreen.init()

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
    local startX = 50
    local startY = 300

    local menuItems = {"Play", "Credits", "Quit"}
    local buttonWidths = {220, 180, 140}
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

    -- Initialize Now Playing effects
    for i = 1, #nowPlayingText do
        nowPlayingTimers[i] = love.math.random() * 2 * math.pi
        nowPlayingOffsets[i] = 0
    end
    
    danceTimer = love.math.random(2, 5)
    danceDuration = love.math.random(3, 6)

    mainTheme:play()
end

function mainmenu.update(dt)
    background.update(dt)
    
    -- Update title animation
    titleScale = titleScale + titleScaleDirection * titleScaleSpeed * dt
    if titleScale > 1.05 or titleScale < 0.95 then
        titleScaleDirection = titleScaleDirection * -1
    end
    
    titleRotation = titleRotation + titleRotationSpeed * dt
    if titleRotation > 0.05 or titleRotation < -0.05 then
        titleRotationSpeed = titleRotationSpeed * -1
    end
    
    titleYOffset = math.sin(love.timer.getTime() * titleBobSpeed) * titleBobAmount

    -- Handle dance sessions
    if isDancing then
        dancePhase = dancePhase + dt * danceSpeed
        danceTimer = danceTimer - dt
        
        if danceTimer <= 0 then
            isDancing = false
            danceTimer = love.math.random(8, 15)
        end
    else
        danceTimer = danceTimer - dt
        if danceTimer <= 0 then
            isDancing = false
            danceSpeed = love.math.random(3, 6)
            danceDuration = love.math.random(4, 8)
            danceTimer = danceDuration
            dancePhase = 0
        end
    end

    -- Update character dancing
    for i = 1, #nowPlayingText do
        nowPlayingTimers[i] = nowPlayingTimers[i] + dt * (isDancing and danceSpeed or 1)
        local wave = math.sin(nowPlayingTimers[i] + i * 0.2)
        nowPlayingOffsets[i] = wave * (isDancing and 8 or 3)
    end

    -- Update flash effect
    if flashTimer > 0 then
        flashTimer = flashTimer - dt
        flashIntensity = math.sin((1 - (flashTimer / flashDuration)) * math.pi)
    elseif love.math.random() < (isDancing and 0.02 or 0.005) then
        flashTimer = flashDuration
        flashIntensity = 0
    end

    if clickedButton then
        clickedTimer = clickedTimer - dt
        if clickedTimer <= 0 then
            clickedButton = nil
        end
    end

    wiggleTimer = wiggleTimer + dt * 2

    -- Update stars
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > love.graphics.getHeight() then
            star.y = 0
            star.x = love.math.random(0, love.graphics.getWidth())
        end
    end

    -- Check button hover
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
        fullscreen.apply()
        
        background.draw({0.02, 0.02, 0.05}, 0, stars)
        drawMenu()

        fullscreen.clear()
    end)
end

function drawMenu()
    local banner = love.graphics.newImage("source/Sprites/banner.png")
    local bannerScale = 0.5
    local bannerX = (love.graphics.getWidth() / 2) - (banner:getWidth() * bannerScale / 2)
    local bannerY = 50 + titleYOffset

    -- Draw animated title
    love.graphics.push()
    love.graphics.translate(bannerX + banner:getWidth() * bannerScale / 2, bannerY + banner:getHeight() * bannerScale / 2)
    love.graphics.rotate(titleRotation)
    love.graphics.scale(titleScale, titleScale)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.draw(banner, -banner:getWidth() * bannerScale / 2, -banner:getHeight() * bannerScale / 2, 0, bannerScale, bannerScale)
    love.graphics.pop()

    love.graphics.setFont(gameFont)
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(buttons) do
        local isHovered = mx > button.x and mx < button.x + button.w and my > button.y and my < button.y + button.h
        local isClicked = (clickedButton == button)
        local color = normalColor
        local scale = 1
        local outlineWidth = 0

        if isHovered then
            scale = 1.05
            color = hoverColor
            outlineWidth = 3
        end

        if isClicked then
            color = {1, 1, 1}
        end

        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", button.x + 4, button.y + 4, button.w, button.h, 10, 10)

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 10, 10)
        
        -- Draw outline if hovered
        if outlineWidth > 0 then
            love.graphics.setLineWidth(outlineWidth)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 10, 10)
            love.graphics.setLineWidth(1)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, button.x, button.y + (button.h / 4), button.w, "center")
    end

    drawCard()

    -- Draw version text
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf(version, love.graphics.getWidth() - 200, love.graphics.getHeight() - 30, 200, "right")
    
    -- Draw Now Playing text with full width calculation
    local textWidth = gameFont:getWidth(nowPlayingText)
    local textX = love.graphics.getWidth() - textWidth - 170
    local textY = love.graphics.getHeight() - 580
    
    love.graphics.setFont(gameFont)
    for i = 1, #nowPlayingText do
        local char = nowPlayingText:sub(i, i)
        local charWidth = gameFont:getWidth(char)
        
        -- Apply flash effect
        if flashTimer > 0 then
            local flashAmount = flashIntensity * 0.8
            love.graphics.setColor(
                flashColor[1] * flashAmount + (1 - flashAmount),
                flashColor[2] * flashAmount + (1 - flashAmount),
                flashColor[3] * flashAmount + (1 - flashAmount),
                0.8
            )
        else
            local danceIntensity = isDancing and 0.8 or 0.6
            love.graphics.setColor(1, 1, 1, danceIntensity)
        end
        
        -- Enhanced effects during dance
        if isDancing then
            local scale = 1 + math.sin(nowPlayingTimers[i] * 0.5) * 0.1
            local rotation = math.sin(nowPlayingTimers[i] * 0.7) * 0.1
            love.graphics.push()
            love.graphics.translate(textX + charWidth/2, textY + nowPlayingOffsets[i])
            love.graphics.rotate(rotation)
            love.graphics.scale(scale, scale)
            love.graphics.print(char, -charWidth/2, -gameFont:getHeight()/2)
            love.graphics.pop()
        else
            love.graphics.print(char, textX, textY + nowPlayingOffsets[i])
        end
        
        textX = textX + charWidth
    end
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
                buttonClickSfx:play()

                if btn.action == "play" then
                    currentState = "game"
                    game.load()
                    setModifier()
                    mainTheme:stop()
                elseif btn.action == "quit" then
                    love.event.quit()
                elseif btn.action == "credits" then
                    currentState = "credits"
                    credits.load()
                    mainTheme:stop()
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