local wf = require 'libraries.windfield'
local moonshine = require 'libraries.moonshine'

local card = require 'modules.card'
local background = require 'modules.background'
local spawner = require 'modules.spawner'
local utility = require 'modules.utility'

local game = {}

-- Global game state variables (cards, money, etc.)
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

local gradientTime = 0
local stars = {}
local currentBgColor = {0.05, 0.05, 0.1}
local targetBgColor ={math.random(1, 255) / 255, math.random(1, 255) / 255, math.random(1, 255) / 255}
local colorTransitionSpeed = 1

local cardAnimations = {}

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

-- Player, boss, and related variables.
player = nil
ground = nil
isSpawned = false
playerX = 120
playerY = 300
playerSpeed = 3
canJump = false

playerHealth = 100
playerMaxHealth = 100
attackDamage = 10
attackSpeed = 1
attackBonus = 0

Poison = false
TwoFaced = false

boss = nil  -- Will be assigned a boss instance from our boss module
difficulty = 1
winPMoney = math.random(1, difficulty)
worldGravity = 800

local maxBoughtCards = 5

math.randomseed(os.time())

-- Win popup variables and buttons
local winPopup = false
local winButtons = {
    restart = { x = 300, y = 250, w = 200, h = 50, text = "Next Run" },
    mainmenu = { x = 300, y = 320, w = 200, h = 50, text = "Main Menu" }
}

local loseButtons = {
    restart = { x = 250, y = 300, w = 300, h = 60, text = "Restart" },
    mainmenu = { x = 250, y = 380, w = 300, h = 60, text = "Main Menu" }
}

-- Pause popup variables and buttons
local pausePopup = false
local pauseButtons = {
    resume   = { x = 300, y = 250, w = 200, h = 50, text = "Resume" },
    mainmenu = { x = 300, y = 320, w = 200, h = 50, text = "Main Menu" }
}

----------------------------------------------------------------
-- Reset the entire game state (initial state)
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
    targetBgColor = {math.random(1, 255) / 255, math.random(1, 255) / 255, math.random(1, 255) / 255}
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
    pausePopup = false

    world = wf.newWorld(0, worldGravity, true)
    world:addCollisionClass("Ground")
    world:addCollisionClass("PlayerTrigger")
    world:addCollisionClass("Boss")

    card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
end

----------------------------------------------------------------
-- Load
----------------------------------------------------------------
function game.load()
    love.window.setTitle("LÖVEJAM25")
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

    Poison = false
    TwoFaced = false
    winPopup = false
    pausePopup = false
end

----------------------------------------------------------------
-- Update
----------------------------------------------------------------
function game.update(dt)
    world:update(dt)

    -- Pause, win, or lose popup stops game updates
    if pausePopup or winPopup or losePopup then
        return
    end

    if isSpawned then
        playerTrigger:setPosition(player:getX(), player:getY())

        if boss then
            if boss.Durability <= 0 then
                if TwoFaced then
                    boss.Durability = 50
                    TwoFaced = false
                else
                    game.fightWin()  -- Trigger win popup
                    boss = nil
                end
            end
        end

        -- Check for player death
        if playerHealth <= 1 then
            if utility.tableContains(boughtCards, "Second Wind") then
                playerHealth = 50
                boughtCards = {}
            else
                losePopup = true  -- Trigger lose popup
                isSpawned = false
            end
        end

        -- Player movement
        if love.keyboard.isDown('a') then
            player:setX(playerX - playerSpeed)
            playerX = playerX - playerSpeed
            if Poison then
                playerHealth = playerHealth - math.random(0.1, 1)
            end
        elseif love.keyboard.isDown('d') then
            player:setX(playerX + playerSpeed)
            playerX = playerX + playerSpeed
            if Poison then
                playerHealth = playerHealth - math.random(0.1, 1)
            end
        end

        -- Card effects
        if utility.tableContains(boughtCards, "Antidote") then
            Poison = false
        elseif utility.tableContains(boughtCards, "Resilience") and math.random(1, 10) > 5 then
            Poison = false
        end

        if utility.tableContains(boughtCards, "Quickthinking") then
            playerSpeed = 6
        else
            playerSpeed = 3
        end

        if utility.tableContains(boughtCards, "Mushroom") then
            if math.random(1, 10) > 6 then
                Poison = true
            else
                playerHealth = playerHealth + 50
            end
            utility.tableRemove(boughtCards, "Mushroom")
        end

        if utility.tableContains(boughtCards, "UNO Reverse") and Poison then
            if boss then boss.bossPoison = true end
            Poison = false
        else
            if boss then boss.bossPoison = false end
        end

        if utility.tableContains(boughtCards, "BUY BUY BUY") then
            amountCards = 5
        else
            amountCards = 3
        end

        if utility.tableContains(boughtCards, "GL1T5H") then
            maxBoughtCards = 7
        else
            maxBoughtCards = 5
        end

        if utility.tableContains(boughtCards, "Lucky Draw") then
            if #boughtCards < maxBoughtCards then
                if #possibleCards > 0 then
                    local randomIndex = love.math.random(1, #possibleCards)
                    local randomCard = possibleCards[randomIndex]
                    table.insert(boughtCards, randomCard)
                    print("Lucky Draw: Added " .. randomCard.Name .. " to boughtCards!")
                    for i, cardData in ipairs(boughtCards) do
                        if cardData.Name == "Lucky Draw" then
                            table.remove(boughtCards, i)
                            break
                        end
                    end
                else
                    print("No cards left in possibleCards for Lucky Draw!")
                end
            else
                print("Maximum number of cards reached! Cannot use Lucky Draw.")
            end
        end

        if utility.tableContains(boughtCards, "Fly like a Bunny") then
            worldGravity = 700
        elseif utility.tableContains(boughtCards, "Who's Newton?") then
            worldGravity = -800
        else
            worldGravity = 800
        end

        world:setGravity(0, worldGravity)
    end

    -- Background star field
    gradientTime = gradientTime + dt * 0.1
    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > 600 then
            star.y = 0
            star.x = love.math.random(0, 800)
        end
    end

    -- Card animations
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

    -- Card hover detection
    local mx, my = love.mouse.getPosition()
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

    -- Play button logic
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
        end
    end
    playButton.scale = playButton.scale + (playButton.targetScale - playButton.scale) * 10 * dt

    -- Update boss logic if present
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

        -- Draw shadow for "Money" text
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Money: $" .. Money, 2, 17, 800, "center")

        -- Draw actual "Money" text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Money: $" .. Money, 0, 15, 800, "center")

        -- Draw shadow for "Cards" text
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 2, 52, 800, "center")

        -- Draw actual "Cards" text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 0, 50, 800, "center")

        if not isSpawned then
            love.graphics.printf("Run: ".. difficulty, 0, 150, 800, "center")
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

    love.graphics.setColor(1,1,1,1)
    world:draw()
end

----------------------------------------------------------------
-- Draw Win Popup with Hover Effects
----------------------------------------------------------------
function game.drawWinPopup()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw shadow for "You Win!" text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("You Win!", 2, 132, love.graphics.getWidth(), "center")

    -- Draw actual "You Win!" text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("You Win!", 0, 130, love.graphics.getWidth(), "center")

    -- Draw shadow for "Money Earned" text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Money Earned: $" .. winPMoney, 2, 192, love.graphics.getWidth(), "center")

    -- Draw actual "Money Earned" text
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

        -- Draw button shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 12, 12)

        -- Draw actual button
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

    -- Draw shadow for "You Lost!" text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("You Lost!", 2, 112, love.graphics.getWidth(), "center")

    -- Draw actual "You Lost!" text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("You Lost!", 0, 110, love.graphics.getWidth(), "center")

    -- Draw shadow for "Runs Survived" text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Runs Survived: " .. (difficulty - 1), 2, 172, love.graphics.getWidth(), "center")

    -- Draw actual "Runs Survived" text
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

        -- Draw button shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 12, 12)

        -- Draw actual button
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

    -- Draw shadow for "Paused" text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Paused", 2, 152, love.graphics.getWidth(), "center")

    -- Draw actual "Paused" text
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

        -- Draw button shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", drawX + 5, drawY + 5, drawW, drawH, 8, 8)

        -- Draw actual button
        love.graphics.setColor(0.2, 0.6, 0.2)
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
        -- Pause popup handling
        if pausePopup then
            for key, btn in pairs(pauseButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "resume" then
                        pausePopup = false
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "mainmenu"
                    end
                    return
                end
            end
        end

        -- Win popup handling
        if winPopup then
            for key, btn in pairs(winButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "restart" then
                        local prevCards = {}
                        local prevMoney = {}

                        prevCards = boughtCards
                        prevMoney = Money

                        player = nil
                        boss = nil
                        winPopup = false
                        
                        game.resetGameState()

                        Money = prevMoney + winPMoney
                        boughtCards = prevCards
                        difficulty = difficulty + 1
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "mainmenu"
                    end
                    return
                end
            end
        end

        -- Lose popup handling
        if losePopup then
            for key, btn in pairs(loseButtons) do
                if x > btn.x and x < btn.x + btn.w and y > btn.y and y < btn.y + btn.h then
                    if key == "restart" then
                        game.resetGameState()
                        losePopup = false
                    elseif key == "mainmenu" then
                        game.resetGameState()
                        currentState = "mainmenu"
                    end
                    return
                end
            end
        end

        -- Play button handling
        if playButton.visible and x > playButton.x and x < playButton.x + playButton.width and
           y > playButton.y and y < playButton.y + playButton.height then
            playButton.clicked = true
            playButton.clickTimer = 0.1
        else
            -- Card selection handling
            local startX = (800 - (amountCards * 120)) / 2
            for i, cardData in ipairs(chosenCards) do
                local cardX = startX + (i - 1) * 120
                local cardY = cardAnimations[i].currentY  -- Use the animated Y position
                local cardWidth = 100 * cardAnimations[i].scale
                local cardHeight = 140 * cardAnimations[i].scale

                -- Check if the mouse is within the card's bounds
                if x > cardX - (cardWidth - 100) / 2 and x < cardX + (cardWidth + 100) / 2 and
                   y > cardY - (cardHeight - 140) / 2 and y < cardY + (cardHeight + 140) / 2 then
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

            -- Sell card handling
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
    elseif key == 'q' then
        boughtCards = {}
    elseif key == '-' then
        if boss then boss:takeDamage(30) end
    elseif key == '=' then
        playerHealth = playerHealth - 10
    elseif key == 'space' and canJump then
        player:applyLinearImpulse(0, -2300)
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
-- Called when the boss is defeated
----------------------------------------------------------------
function game.fightWin()
    winPopup = true
end

return game