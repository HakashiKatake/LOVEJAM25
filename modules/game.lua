local wf = require 'libraries.windfield'
local moonshine = require 'libraries.moonshine'
local card = require 'modules.card'
local background = require 'modules.background'
local spawner = require 'modules.spawner'
local utility = require 'modules.utility'

local game = {}

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
    text = "Play",  
    hovered = false,  
    clicked = false,  
    scale = 1,  
    targetScale = 1,  
    color = {0.2, 0.6, 0.2},  
    clickTimer = 0,  
    visible = true  
}

-- These will be set by our spawner module
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

boss = nil
bossHealth = 300
bossMaxHealth = 300
bossResistance = 2
bossShield = 50

playerTrigger = nil

worldGravity = 800

local maxBoughtCards = 5

function game.load()
    love.window.setTitle("LÖVEJAM25")
    love.window.setMode(800, 600)
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
    effect.filmgrain.size = 3
    effect.scanlines.opacity = 0.2

    -- Load card data from the card module
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

    -- Setup initial card selection
    card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
end

function game.update(dt)
    world:update(dt)

    if isSpawned then
        playerTrigger:setPosition(player:getX(), player:getY())

        if love.keyboard.isDown('a') then
            player:setX(playerX - playerSpeed)
            playerX = playerX - playerSpeed
        elseif love.keyboard.isDown('d') then
            player:setX(playerX + playerSpeed)
            playerX = playerX + playerSpeed
            player:applyLinearImpulse(0, -100)
        end

        if utility.tableContains(boughtCards, "Quickthinking") then
            playerSpeed = 6
        else
            playerSpeed = 3
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

        -- Handle Lucky Draw card effect
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

    if love.keyboard.isDown('escape') then
        love.event.quit()
    end

    gradientTime = gradientTime + dt * 0.1

    for _, star in ipairs(stars) do
        star.y = star.y + star.speed
        if star.y > 600 then
            star.y = 0
            star.x = love.math.random(0, 800)
        end
    end

    -- Use backward iteration for safe removal
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

    -- Update hovered card state
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

    -- Update play button state
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
end

function game.draw()
    background.draw(currentBgColor, gradientTime, stars)
    world:setQueryDebugDrawing(true)

    effect(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Money: $" .. Money, 0, 15, 800, "center")
        love.graphics.printf("Cards: " .. #boughtCards .. "/" .. maxBoughtCards, 0, 50, 800, "center")

        if player then
            local px, py = player:getX(), player:getY()
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", px - 25, py - 40, 50, 6)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", px - 25, py - 40, (playerHealth / playerMaxHealth) * 50, 6)
        end

        if boss then
            local barWidth = 300
            local barHeight = 20
            local barX = (800 - barWidth) / 2
            local barY = 20

            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", barX, barY, (bossHealth / bossMaxHealth) * barWidth, barHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("BOSS", barX, barY - 4, barWidth, "center")
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
end

function game.mousepressed(x, y, button)
    if button == 1 then  
        if isSpawned and boss and playerTrigger then
            if playerTrigger:enter('Boss') then
                bossHealth = bossHealth - (attackDamage + attackBonus)
                print("Boss hit! Health: " .. bossHealth)
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
    elseif key == 'q' then
        boughtCards = {}
    elseif key == '-' then
        bossHealth = bossHealth - 10
    elseif key == '=' then
        playerHealth = playerHealth - 10
    elseif key == 'space' and canJump then
        player:applyLinearImpulse(0, -2300)
    elseif key == '1' then
        Money = Money + 10
    end
end

function game.beginFight()
    targetBgColor = { love.math.random(), love.math.random(), love.math.random() }
    spawner.spawnPlayer(world, playerX, playerY)
    spawner.spawnGround(world)
    spawner.spawnBoss(world)
end

return game
