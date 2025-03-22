local wf = require 'libraries.windfield'
local moonshine = require 'libraries.moonshine'
local anim8 = require 'libraries.anim8'

local card = require 'modules.card'
local background = require 'modules.background'  -- Ensure background is required
local spawner = require 'modules.spawner'
local utility = require 'modules.utility'
local spritesheets = require 'modules.spritesheets'
local cardbehaviour = require 'modules.cardbehaviour'

local game = {}

-- SFX for card appearance and hover
local cardThrowSfx = love.audio.newSource("source/SFX/cardthrow.wav", "static")
local cardSelectSfx = love.audio.newSource("source/SFX/cardselect.wav", "static")

-- Variables to track SFX for card appearance and hover
local cardsSoundPlayed = false  -- global flag reset each time cards are drawn
local lastHoveredCardIndex = nil

-- Global game state variables
local world
local possibleCards = {}
local chosenCards = {}
local boughtCards = {}
local amountCards = 3
local hoveredCardIndex = nil
local timer = 0
local cardY = 400
local gameFont
local Money = 10

-- Options for the background
background.doDrawBg = false
background.drawEffects = true

local gradientTime = 0
local stars = {}
local currentBgColor = {0.05, 0.05, 0.1}
local targetBgColor = {
    math.random(1, 255)/255,
    math.random(1, 255)/255,
    math.random(1, 255)/255
}
local colorTransitionSpeed = 1

local cardAnimations = {}   -- each entry will also get a .soundPlayed flag
local hoverScale = 1.1
local hoverSpeed = 10

local removedCardIndex = nil
local removalTimer = 0
local removalDuration = 0.5

local playButton = {
    x = 350,
    y = 200,
    width = 100,
    height = 50,
    text = "Start",
    hovered = false,
    clicked = false,
    scale = 1,
    targetScale = 1,
    color = {0.2, 0.6, 0.2},
    clickTimer = 0,
    visible = true
}

-- Player, boss, and related variables
player = nil
ground = nil
isSpawned = false
playerX = 120
playerY = 300
playerSpeed = 3

-- Jumping
local jumpForce = 2500
canJump = false
local isJumping = false  -- For the jump animation

playerHealth = 100
playerMaxHealth = 100
attackDamage = 10
attackSpeed = 1
attackBonus = 0

playerFlipX = 2

Poison = false
TwoFaced = false

boss = nil
difficulty = 1
winPMoney = math.random(1, difficulty)
worldGravity = 800

local maxBoughtCards = 5

math.randomseed(os.time())

-- Attack system
local attackCooldown = 0.2
local playerAttackTimer = attackCooldown
local isAttacking = false  -- Track if we're currently attacking

-- Popups
winPopup = false
losePopup = false
pausePopup = false

local winButtons = {
    restart = { x = 300, y = 250, w = 200, h = 50, text = "Next Run" },
    mainmenu = { x = 300, y = 320, w = 200, h = 50, text = "Main Menu" }
}
local loseButtons = {
    restart = { x = 250, y = 300, w = 300, h = 60, text = "Restart" },
    mainmenu = { x = 250, y = 380, w = 300, h = 60, text = "Main Menu" }
}
local pauseButtons = {
    resume = { x = 300, y = 250, w = 200, h = 50, text = "Resume" },
    mainmenu = { x = 300, y = 320, w = 200, h = 50, text = "Main Menu" }
}

----------------------------------------------------------------
-- Reset the entire game state
----------------------------------------------------------------
function game.resetGameState()
    possibleCards = card.getPossibleCards()
    chosenCards = {}
    boughtCards = {}
    amountCards = 3
    winPMoney = math.random(1, difficulty)
    hoveredCardIndex = nil
    timer = 0
    Money = 10
    gradientTime = 0
    currentBgColor = {0.05, 0.05, 0.1}
    targetBgColor = {
        math.random(1,255)/255,
        math.random(1,255)/255,
        math.random(1,255)/255
    }
    cardAnimations = {}
    removedCardIndex = nil
    removalTimer = 0

    playButton.visible = true
    playButton.clicked = false
    playButton.scale = 1
    playButton.targetScale = 1

    isSpawned = false
    player = nil
    ground = nil
    boss = nil
    playerHealth = 100
    Poison = false
    TwoFaced = false
    worldGravity = 800
    maxBoughtCards = 5
    winPopup = false
    losePopup = false
    pausePopup = false

    canJump = false
    isJumping = false
    isAttacking = false
    playerAttackTimer = attackCooldown

    -- Reset card SFX tracking variables
    cardsSoundPlayed = false
    lastHoveredCardIndex = nil

    world = wf.newWorld(0, worldGravity, true)
    background.doDrawBg = false
    background.drawEffects = true
    world:addCollisionClass("Ground")
    world:addCollisionClass("PlayerTrigger")
    world:addCollisionClass("Boss")

    card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
end

----------------------------------------------------------------
-- Load
----------------------------------------------------------------
function game.load()
    love.window.setTitle("Spade Knight")
    world = wf.newWorld(0, worldGravity, true)
    world:addCollisionClass("Ground")
    world:addCollisionClass("PlayerTrigger")
    world:addCollisionClass("Boss")

    gameFont = love.graphics.newFont("source/fonts/Jersey10.ttf", 25)
    love.graphics.setFont(gameFont)

    effect = moonshine(moonshine.effects.filmgrain)
        .chain(moonshine.effects.vignette)
        .chain(moonshine.effects.scanlines)
        .chain(moonshine.effects.chromasep)

    effect.vignette.opacity = 0.55
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2
    effect.chromasep.radius = 1.5

    possibleCards = card.getPossibleCards()
    for i, cardData in ipairs(possibleCards) do
        if not cardData.Sprite then
            print("ERROR: Failed to load sprite for card: " .. cardData.Name)
        end
    end

    for i = 1, 100 do
        table.insert(stars, {
            x = love.math.random(0, 800),
            y = love.math.random(0, 600),
            speed = love.math.random(5, 15) / 10
        })
    end

    card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
    cardsSoundPlayed = false
    lastHoveredCardIndex = nil
    Poison = false
    TwoFaced = false
    winPopup = false
    losePopup = false
    pausePopup = false
end

----------------------------------------------------------------
-- Update
----------------------------------------------------------------
function game.update(dt)
    world:update(dt)

    -- If background has update functions, call them (if defined)
    if background.updateAnimationFrame then background.updateAnimationFrame(dt) end
    if background.update then background.update(dt) end

    if pausePopup or winPopup or losePopup then
        return
    end

    if playerAttackTimer < attackCooldown then
        playerAttackTimer = playerAttackTimer + dt
    end

    if isSpawned then
        playerTrigger:setPosition(player:getX(), player:getY())

        -- Simple ground check: if player's velocity is near 0 and near ground, allow jump
        if ground and player then
            local gx, gy = ground:getPosition()
            local vx, vy = player:getLinearVelocity()
            if math.abs(vy) < 1 and player:getY() >= gy - 60 then
                canJump = true
                if isJumping then
                    isJumping = false
                end
            end
        end

        if boss and boss.Durability then
            if boss.Durability <= 0 then
                if TwoFaced then
                    boss.Durability = 50
                    TwoFaced = false
                else
                    game.fightWin()
                    boss = nil
                end
            end
        end

        -- Choose animation: Attack > Jump > Run/Idle
        if isAttacking then
            spritesheets.currentAnim = spritesheets.attackAnim
        elseif isJumping then
            spritesheets.currentAnim = spritesheets.jumpAnim
        else
            if love.keyboard.isDown('a') or love.keyboard.isDown('d') then
                spritesheets.currentAnim = spritesheets.runAnim
            else
                spritesheets.currentAnim = spritesheets.idleAnim
            end
        end

        spritesheets.currentAnim:update(dt)

        if isAttacking then
            if spritesheets.currentAnim.position == #spritesheets.currentAnim.frames then
                isAttacking = false
                spritesheets.attackAnim:gotoFrame(1)
                spritesheets.attackAnim:pause()
            end
        end

        if playerHealth <= 1 then
            if utility.tableContains(boughtCards, "Second Wind") then
                playerHealth = 50
                boughtCards = {}
            else
                losePopup = true
                isSpawned = false
            end
        end

        if love.keyboard.isDown('a') then
            player:setX(playerX - playerSpeed)
            playerX = playerX - playerSpeed
            playerFlipX = -2
            if Poison then
                playerHealth = playerHealth - math.random(0.1, 1)
            end
        elseif love.keyboard.isDown('d') then
            playerFlipX = 2
            player:setX(playerX + playerSpeed)
            playerX = playerX + playerSpeed
            if Poison then
                playerHealth = playerHealth - math.random(0.1, 1)
            end
        end

        world:setGravity(0, worldGravity)

        -- Call card behaviour logic from separate module
        playerSpeed, playerHealth, maxBoughtCards, worldGravity, amountCards =
            cardbehaviour.checkCardBehaviour(boughtCards, possibleCards, playerSpeed, playerHealth, maxBoughtCards, worldGravity, amountCards, boss)

        -- For each card animation, if its elapsed time exceeds its delay and sound hasn't been played, play cardThrowSfx
        for _, anim in ipairs(cardAnimations) do
            if not anim.soundPlayed and anim.elapsed >= anim.delay then
                cardThrowSfx:play()
                anim.soundPlayed = true
            end
        end
    end

    -- Hover sound: if hoveredCardIndex changes, play cardSelectSfx
    local mx, my = love.mouse.getPosition()
    if hoveredCardIndex and hoveredCardIndex ~= lastHoveredCardIndex then
        cardSelectSfx:play()
    end
    lastHoveredCardIndex = hoveredCardIndex

    gradientTime = gradientTime + dt * 0.1
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > 600 then
            star.y = 0
            star.x = love.math.random(0, 800)
        end
    end

    for i = #cardAnimations, 1, -1 do
        local anim = cardAnimations[i]
        if anim.elapsed < anim.delay then
            anim.elapsed = anim.elapsed + dt
        else
            anim.currentY = anim.currentY - (anim.currentY - anim.targetY) * 0.1
        end

        if hoveredCardIndex == i then
            anim.hoverScale = hoverScale
        else
            anim.hoverScale = 1
        end
        anim.scale = anim.scale + (anim.hoverScale - anim.scale) * hoverSpeed * dt

        if removedCardIndex == i then
            removalTimer = removalTimer + dt
            anim.alpha = 1 - (removalTimer / removalDuration)
            anim.scale = anim.scale * 0.9

            if removalTimer >= removalDuration then
                table.remove(chosenCards, i)
                table.remove(cardAnimations, i)
                removedCardIndex = nil
                removalTimer = 0
            end
        end
    end

    hoveredCardIndex = nil
    local startX = (800 - (amountCards * 120)) / 2
    for i, cardData in ipairs(chosenCards) do
        local x = startX + (i - 1) * 120
        local y = cardAnimations[i].currentY
        local cardWidth = 100 * cardAnimations[i].scale
        local cardHeight = 140 * cardAnimations[i].scale
        if mx > x - (cardWidth - 100) / 2 and mx < x + (cardWidth + 100) / 2 and
           my > y - (cardHeight - 140) / 2 and my < y + (cardHeight + 140) / 2 then
            hoveredCardIndex = i
            timer = timer + dt
        end
    end
    if not hoveredCardIndex then
        timer = 0
    end

    playButton.hovered = mx > playButton.x and mx < playButton.x + playButton.width and
                         my > playButton.y and my < playButton.y + playButton.height
    playButton.targetScale = playButton.hovered and 1.1 or 1

    if playButton.clicked then
        playButton.targetScale = 0.9
        playButton.clickTimer = playButton.clickTimer - dt
        if playButton.clickTimer <= 0 then
            playButton.clicked = false
            playButton.visible = false
            chosenCards = {}
            cardAnimations = {}
            game.beginFight()
            background.doDrawBg = true
            background.drawEffects = false
        end
    end
    playButton.scale = playButton.scale + (playButton.targetScale - playButton.scale) * 10 * dt

    if boss and player then
        boss:update(dt, player)
    end
end

----------------------------------------------------------------
-- Draw
----------------------------------------------------------------
function game.draw()
    effect(function()
        background.draw(currentBgColor, gradientTime, stars)
        world:setQueryDebugDrawing(true)

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Money: $" .. Money, 2, 17, 800, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Money: $" .. Money, 0, 15, 800, "center")

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 2, 52, 800, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 0, 50, 800, "center")

        if not isSpawned then
            love.graphics.printf("Run: " .. difficulty, 0, 150, 800, "center")
        end

        if player then
            local px, py = player:getX(), player:getY()
            local frame = spritesheets.currentAnim
            local sprite
            if isAttacking then
                sprite = spritesheets.playerAttackSheet
            elseif isJumping then
                sprite = spritesheets.playerJumpSheet
            else
                sprite = spritesheets.playerRunSheet
            end
            if sprite and frame then
                local sw, sh = frame:getDimensions()
                local ox = (playerFlipX < 0) and (sw / 2) or (sw / 2)
                frame:draw(sprite, px, py - 10, 0, playerFlipX, 2, ox, sh / 2)
            end
        end

        if player then
            local px, py = player:getX(), player:getY()
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", px - 25, py - 40, 50, 6)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", px - 25, py - 40, (playerHealth / playerMaxHealth) * 50, 6)
        end

        if boss then
            boss:draw()
        end

        if #boughtCards > 0 then
            love.graphics.setColor(1, 1, 1)
            local yOffset = 80
            for i, cardData in ipairs(boughtCards) do
                local cardText = "[" .. i .. "]: " .. cardData.Name
                love.graphics.printf(cardText, 0, yOffset, 800, "left")
                yOffset = yOffset + 20
            end
        end

        card.drawCardsUI(chosenCards, cardAnimations, hoveredCardIndex, timer, gameFont)
        card.drawPlayButton(playButton, gameFont)

        if winPopup then
            game.drawWinPopup()
        elseif losePopup then
            game.drawLosePopup()
        elseif pausePopup then
            game.drawPausePopup()
        end
    end)

    love.graphics.setColor(1, 1, 1, 1)
    -- Uncomment to draw physics bodies:
    -- world:draw()
end

----------------------------------------------------------------
-- Draw Win Popup with Hover Effects
----------------------------------------------------------------
function game.drawWinPopup()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("You Win!", 2, 132, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("You Win!", 0, 130, love.graphics.getWidth(), "center")

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Money Earned: $" .. winPMoney, 2, 192, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Money Earned: $" .. winPMoney, 0, 190, love.graphics.getWidth(), "center")

    local mx, my = love.mouse.getPosition()
    for key, btn in pairs(winButtons) do
        local scale = 1
        if mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h then
            scale = 1.07
        end
        local horizontalPadding = 60
        local paddedW = btn.w + horizontalPadding
        local drawX = btn.x - ((paddedW * (scale - 1)) / 2) - (horizontalPadding / 2)
        local drawY = btn.y - (btn.h * (scale - 1)) / 2
        local drawW = paddedW * scale
        local drawH = btn.h * scale

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 12, 12)

        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 12, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf(btn.text, drawX, drawY + (drawH / 3.2), drawW, "center")
    end
end

----------------------------------------------------------------
-- Draw Lose Popup with Hover Effects
----------------------------------------------------------------
function game.drawLosePopup()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("You Lost!", 2, 112, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("You Lost!", 0, 110, love.graphics.getWidth(), "center")

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Runs Survived: " .. (difficulty - 1), 2, 172, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Runs Survived: " .. (difficulty - 1), 0, 170, love.graphics.getWidth(), "center")

    local mx, my = love.mouse.getPosition()
    for key, btn in pairs(loseButtons) do
        local scale = 1
        if mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h then
            scale = 1.07
        end
        local horizontalPadding = 60
        local paddedW = btn.w + horizontalPadding
        local drawX = btn.x - ((paddedW * (scale - 1)) / 2) - (horizontalPadding / 2)
        local drawY = btn.y - (btn.h * (scale - 1)) / 2
        local drawW = paddedW * scale
        local drawH = btn.h * scale

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 12, 12)

        love.graphics.setColor(0.6, 0.2, 0.2)
        love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 12, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf(btn.text, drawX, drawY + (drawH / 3.2), drawW, "center")
    end
end

----------------------------------------------------------------
-- Draw Pause Popup with Hover Effects
----------------------------------------------------------------
function game.drawPausePopup()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Paused", 2, 152, love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Paused", 0, 150, love.graphics.getWidth(), "center")

    local mx, my = love.mouse.getPosition()
    for key, btn in pairs(pauseButtons) do
        local scale = 1
        if mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h then
            scale = 1.07
        end
        local drawX = btn.x - (btn.w * (scale - 1)) / 2
        local drawY = btn.y - (btn.h * (scale - 1)) / 2
        local drawW = btn.w * scale
        local drawH = btn.h * scale

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 8, 8)

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(btn.text, drawX, drawY + (drawH / 4), drawW, "center")
    end
end

----------------------------------------------------------------
-- Mouse pressed
----------------------------------------------------------------
function game.mousepressed(x, y, button)
    if button == 1 then
        if pausePopup then
            for key, btn in pairs(pauseButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "resume" then
                        pausePopup = false
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "menu"
                    end
                    return
                end
            end
        end

        if winPopup then
            for key, btn in pairs(winButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "restart" then
                        local prevCards = boughtCards
                        local prevMoney = Money
                        player = nil
                        boss = nil
                        winPopup = false
                        
                        game.resetGameState()
                        
                        Money = prevMoney + winPMoney
                        boughtCards = prevCards
                        difficulty = difficulty + 1
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "menu"
                    end
                    return
                end
            end
        end

        if losePopup then
            for key, btn in pairs(loseButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "restart" then
                        game.resetGameState()
                        losePopup = false
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "menu"
                    end
                    return
                end
            end
        end

        if isSpawned and boss and playerTrigger then
            if playerTrigger:enter('Boss') then
                boss:takeDamage(attackDamage + attackBonus)
                print("Boss hit! Health: " .. boss.Durability)
            end
        end

        if playButton.visible and x > playButton.x and x < playButton.x + playButton.width and
           y > playButton.y and y < playButton.y + playButton.height then
            playButton.clicked = true
            playButton.clickTimer = 0.1
        else
            local startX = (800 - (amountCards * 120)) / 2
            for i, cardData in ipairs(chosenCards) do
                local cardX = startX + (i - 1) * 120
                local cardY = cardAnimations[i].currentY
                if x > cardX and x < cardX + 100 and y > cardY and y < cardY + 140 then
                    if Money >= cardData.Price then
                        if #boughtCards < maxBoughtCards then
                            Money = Money - cardData.Price
                            table.insert(boughtCards, cardData)
                            table.remove(possibleCards, i)
                            removedCardIndex = i
                        else
                            print("Maximum number of cards reached!")
                        end
                    else
                        print("Not enough money!")
                    end
                    break
                end
            end

            for i, cardData in ipairs(boughtCards) do
                local cardX = 10
                local cardY = 80 + (i - 1) * 20
                if x > cardX and x < cardX + 200 and y > cardY and y < cardY + 20 then
                    local sellPrice = math.floor(cardData.Price / 3)
                    Money = Money + sellPrice
                    table.remove(boughtCards, i)
                    table.insert(possibleCards, cardData)
                    print("Sold " .. cardData.Name .. " for $" .. sellPrice)
                    break
                end
            end
        end
    end
end

----------------------------------------------------------------
-- Key pressed
----------------------------------------------------------------
function game.keypressed(key)
    if pausePopup or winPopup then
        if key == 'escape' then
            pausePopup = false
        end
        return
    end

    if key == 'r' then
        card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
    elseif key == 'escape' then
        if isSpawned and not winPopup then
            pausePopup = not pausePopup
        else
            love.window.close()
        end
    elseif key == 'y' then
        spritesheets.currentAnim = spritesheets.idleAnim
    elseif key == 'q' then
        boughtCards = {}
    elseif key == '-' then
        if boss then boss:takeDamage(30) end
    elseif key == '=' then
        playerHealth = playerHealth - 10
    elseif key == 'space' then
        -- Jump: if can jump and not already jumping or attacking
        if canJump and not isJumping and not isAttacking then
            local vx, vy = player:getLinearVelocity()
            if math.abs(vy) < 0.1 then
                player:applyLinearImpulse(0, -jumpForce)
                canJump = false
                isJumping = true
                spritesheets.currentAnim = spritesheets.jumpAnim
            end
        end
    elseif key == 'z' then
        -- Melee attack: if not attacking and cooldown met
        if (not isAttacking) and (playerAttackTimer >= attackCooldown) then
            isAttacking = true
            playerAttackTimer = 0
            spritesheets.currentAnim = spritesheets.attackAnim
            spritesheets.attackAnim:gotoFrame(1)
            spritesheets.attackAnim:resume()

            if boss and player then
                local bx, by = boss.collider:getPosition()
                local px, py = player:getX(), player:getY()
                -- Increased hit radius from 70 to 120
                local dist = math.sqrt((px - bx)^2 + (py - by)^2)
                if dist < 120 then
                    boss:takeDamage(attackDamage + attackBonus)
                    print("Player melee attacked boss! Boss health: " .. boss.Durability)
                end
            end
        end
    elseif key == '1' then
        Money = Money + 10
    elseif key == '2' then
        Poison = not Poison
    elseif key == '3' then
        game.fightWin()
    end
end

----------------------------------------------------------------
-- Begin the fight
----------------------------------------------------------------
function game.beginFight()
    background.doDrawBg = true
    background.drawEffects = false
    targetBgColor = { love.math.random(), love.math.random(), love.math.random() }
    spawner.spawnPlayer(world, playerX, playerY)
    spawner.spawnGround(world)
    spawner.spawnBoss(world)

    if boss then
        boss.bossPoison = false
    end
    isSpawned = true
    playButton.visible = false
end

----------------------------------------------------------------
-- Called when boss is defeated
----------------------------------------------------------------
function game.fightWin()
    winPopup = true
    background.drawEffects = true
    background.doDrawBg = false
end

return game
