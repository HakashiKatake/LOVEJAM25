shove = require 'libraries.shove'
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
local currentBgColor = {0.1, 0.1, 0.2}  
local targetBgColor = {0.1, 0.1, 0.2}   
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

boss = nil  -- will be assigned a boss instance from our boss module

worldGravity = 800

local maxBoughtCards = 5

math.randomseed(os.time())

function game.resetGameState()
    -- Reset all game state variables to their initial values
    possibleCards = card.getPossibleCards()
    chosenCards = {}
    boughtCards = {}
    amountCards = 3
    hoveredCardIndex = nil
    timer = 0
    Money = 10
    gradientTime = 0
    currentBgColor = {0.1, 0.1, 0.2}
    targetBgColor = {0.1, 0.1, 0.2}
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

    -- Reinitialize the world
    world = wf.newWorld(0, worldGravity, true)
    world:addCollisionClass("Ground")
    world:addCollisionClass("PlayerTrigger")
    world:addCollisionClass("Boss")

    -- Reinitialize cards
    card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
end

function game.load()
    love.window.setTitle("LÖVEJAM25")
    world = wf.newWorld(0, worldGravity, true) 

    shove.setResolution(800, 600, {fitMethod = "aspect"})
    shove.setWindowMode(800, 600, {resizable = false})

    world:addCollisionClass("Ground")  
    world:addCollisionClass("PlayerTrigger")  
    world:addCollisionClass("Boss") 

    gameFont = love.graphics.newFont("source/fonts/Jersey10.ttf", 25)
    love.graphics.setFont(gameFont)

    effect = moonshine(moonshine.effects.filmgrain)
        .chain(moonshine.effects.vignette)
        .chain(moonshine.effects.scanlines)
        .chain(moonshine.effects.chromasep)
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2

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

    -- Initialize Poison and TwoFaced states
    Poison = false
    TwoFaced = false
end

function game.update(dt)
    world:update(dt)

    if isSpawned then
        playerTrigger:setPosition(player:getX(), player:getY())

        if boss.Durability <= 1 and TwoFaced then
            boss.Durability = 50
            TwoFaced = false
        end

        if boss.Durability <= 1 and not TwoFaced then
            game.fightWin()
        end

        if playerHealth <= 1 and not utility.tableContains(boughtCards, "Second Wind") then
            love.window.close()
        end

        if playerHealth <= 1 and utility.tableContains(boughtCards, "Second Wind") then
            playerHealth = 50
            boughtCards = {}
        end

        if playerHealth <= 1 and not utility.tableContains(boughtCards, "Second Wind") then
            love.window.close()
        end

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

        -- Update Poison state based on cards
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
            boss.bossPoison = true
            Poison = false
        else
            boss.bossPoison = false
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

        -- Additional card effects (like Lucky Draw, gravity changes, etc.)
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

    gradientTime = gradientTime + dt * 0.1

    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > 600 then
            star.y = 0
            star.x = love.math.random(0, 800)
        end
    end

    -- Update card animations with backward iteration for safe removal.
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

    -- Update hovered card state.
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

    -- Update play button state.
    local mx, my = love.mouse.getPosition()
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

    -- Update the boss if it exists.
    if boss and player then
        boss:update(dt, player)
    end
end

function game.draw()
    shove.beginDraw()
        background.draw(currentBgColor, gradientTime, stars)
        world:setQueryDebugDrawing(true)

        effect(function()
            love.graphics.setColor(1, 1, 1)
            if Poison and not isSpawned then
                love.graphics.printf("Smells weird...", 0, 170, 800, "center")
            elseif TwoFaced and not isSpawned then
                love.graphics.printf("I hear shrieking...", 0, 170, 800, "center")
            end
            if isSpawned then
                -- do nothing
            else
                love.graphics.printf("Money: $" .. Money, 0, 15, 800, "center")
            end
            love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 0, 50, 800, "center")

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
        end)

        love.graphics.setColor(1,1,1,1)
        world:draw()
    shove.endDraw()
end

function game.mousepressed(x, y, button)
    if button == 1 then  
        if isSpawned and boss and playerTrigger then
            if playerTrigger:enter('Boss') then
                boss.Durability = boss.Durability - (attackDamage + attackBonus)
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

function game.keypressed(key)
    if key == 'r' then
        card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
    elseif key == 'escape' then
        love.window.close()
    elseif key == 'q' then
        boughtCards = {}
    elseif key == '-' then
        boss.Durability = boss.Durability - 30
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

function game.beginFight()
    targetBgColor = { love.math.random(), love.math.random(), love.math.random() }
    spawner.spawnPlayer(world, playerX, playerY)
    spawner.spawnGround(world)
    spawner.spawnBoss(world)  -- spawn the boss via the spawner module

    boss.bossPoison = false
end

function game.fightWin()
    local lastMoney = Money
    local lastCards = boughtCards
    game.resetGameState()
    Money = lastMoney + math.random(1, 7)
    boughtCards = lastCards

    Poison = false
    TwoFaced = false
end

return game