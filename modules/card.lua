local card = {}

function card.getPossibleCards()
    return {
        {Name = "Antidote", Description = "Poison Immunity", Price = 5, Sprite = love.graphics.newImage("source/Sprites/Cards/antidote.png")},
        {Name = "Resilience", Description = "2/1 Chance to be immune to next potion", Price = 4, Sprite = love.graphics.newImage("source/Sprites/Cards/resilience.png")},
        {Name = "Strength", Description = "Boost to Attack Damage", Price = 6, Sprite = love.graphics.newImage("source/Sprites/Cards/strength.png")},
        {Name = "Quickhand", Description = "Boost to Attack Speed", Price = 7, Sprite = love.graphics.newImage("source/Sprites/Cards/quickhand.png")},
        {Name = "Quickthinking", Description = "Boost to Speed", Price = 3, Sprite = love.graphics.newImage("source/Sprites/Cards/quickthinking.png")},
        {Name = "RGB", Description = "Boost to everything (lasts 10-20 seconds)", Price = 15, Sprite = love.graphics.newImage("source/Sprites/Cards/rgb.png")},
        {Name = "Who's Newton?", Description = "Reverse Gravity", Price = 3, Sprite = love.graphics.newImage("source/Sprites/Cards/newton.png")},
        {Name = "UNO Reverse", Description = "Apply current effect to the boss (lasts 10-20 seconds)", Price = 6, Sprite = love.graphics.newImage("source/Sprites/Cards/uno_reverse.png")},
        {Name = "Thorns", Description = "Reflects a portion of damage taken", Price = 8, Sprite = love.graphics.newImage("source/Sprites/Cards/thorns.png")},
        {Name = "Vampiric Strike", Description = "Steal health equal to 15% of in return of lower attack damage", Price = 8, Sprite = love.graphics.newImage("source/Sprites/Cards/vampiric_strike.png")},
        --{Name = "Phase Shift", Description = "Temporary invincibility (3-5 seconds)", Price = 9, Sprite = love.graphics.newImage("source/Sprites/Cards/phase_shift.png")},
        {Name = "Second Wind", Description = "Revive with 50% health after dying, lose all the cards you have", Price = 16, Sprite = love.graphics.newImage("source/Sprites/Cards/second_wind.png")},
        {Name = "Lucky Draw", Description = "Randomly gain one positive effect", Price = 5, Sprite = love.graphics.newImage("source/Sprites/Cards/lucky_draw.png")},
        {Name = "Haste", Description = "Gain the ability of Dashing", Price = 9, Sprite = love.graphics.newImage("source/Sprites/Cards/haste.png")},
        {Name = "Time Warp", Description = "Get back 20 Health if Boss Health > 50 and Player Health < 50", Price = 12, Sprite = love.graphics.newImage("source/Sprites/Cards/time_warp.png")},
        -- {Name = "Shield Wall", Description = "Take 50% less damage for 10 seconds", Price = 10, Sprite = love.graphics.newImage("source/Sprites/Cards/shield_wall.png")},
        -- {Name = "Berserk", Description = "Double attack damage but take 25% more damage", Price = 8, Sprite = love.graphics.newImage("source/Sprites/Cards/berserk.png")},
        {Name = "Mushroom", Description = "50% chance poisoning, 50% get more health", Price = 5, Sprite = love.graphics.newImage("source/Sprites/Cards/mushroom.png")},
        {Name = "Fly like a Bunny", Description = "Boosted Jump Height", Price = 6, Sprite = love.graphics.newImage("source/Sprites/Cards/fly_like_a_bunny.png")},
        {Name = "GL1T5H", Description = "???", Price = 20, Sprite = love.graphics.newImage("source/Sprites/Cards/glitch.png")}, 
        {Name = "BUY BUY BUY", Description = "Get 2 more additional cards in the shop", Price = 15, Sprite = love.graphics.newImage("source/Sprites/Cards/bbb.png")},
        {Name = "Sheild", Description = "+20 Health", Price = 10, Sprite = love.graphics.newImage("source/Sprites/Cards/shield.png")}
    }
end

function card.drawCards(amountCards, possibleCards, chosenCards, cardAnimations, cardY)
    -- Clear previous selections
    for i = #chosenCards, 1, -1 do table.remove(chosenCards, i) end
    for i = #cardAnimations, 1, -1 do table.remove(cardAnimations, i) end

    for i = 1, amountCards do
        local index = love.math.random(1, #possibleCards)
        table.insert(chosenCards, possibleCards[index])
        table.insert(cardAnimations, {
            currentY = 600,  
            targetY = cardY, 
            delay = i * 0.2, 
            elapsed = 0,     
            scale = 1,       
            hoverScale = 1,  
            alpha = 1,       
        })
    end
end

function card.drawCardsUI(chosenCards, cardAnimations, hoveredCardIndex, timer, gameFont)
    local startX = (800 - (#chosenCards * 120)) / 2  
    for i, cardData in ipairs(chosenCards) do
        local x = startX + (i - 1) * 120
        local y = cardAnimations[i].currentY - 20
        local scale = cardAnimations[i].scale
        local alpha = cardAnimations[i].alpha

        love.graphics.push()
        love.graphics.translate(x + 50 * (1 - scale), y + 70 * (1 - scale))
        love.graphics.scale(scale)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", 0, 0, 100, 140, 10, 10)

        if cardData.Sprite then
            local spriteWidth = cardData.Sprite:getWidth()
            local spriteHeight = cardData.Sprite:getHeight()
            local scaleX = 100 / spriteWidth  
            local scaleY = 180 / spriteHeight 
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(cardData.Sprite, 0, 0, 0, scaleX, scaleY)
        end

        love.graphics.setColor(1, 1, 1, 1)
        local nameHeight = gameFont:getHeight() * math.ceil(gameFont:getWidth(cardData.Name) / 100)
        love.graphics.printf(cardData.Name, 0, - (nameHeight + 10), 100, "center")
        love.graphics.printf("$" .. cardData.Price, 0, 180, 100, "center")
        love.graphics.pop()
    end

    if hoveredCardIndex and timer > 0.5 then
        local cardData = chosenCards[hoveredCardIndex]
        love.graphics.setColor(1, 1, 1)
        local descWidth = math.max(250, gameFont:getWidth(cardData.Description) + 20)
        local descHeight = gameFont:getHeight() * math.ceil(gameFont:getWidth(cardData.Description) / (descWidth - 20)) + 20
        local descX = (800 - descWidth) / 2
        local descY = (600 - descHeight) / 2

        love.graphics.rectangle("fill", descX, descY, descWidth, descHeight, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(cardData.Description, descX + 10, descY + 10, descWidth - 20, "center")
    end
end

function card.drawPlayButton(playButton, gameFont)
    if playButton.visible then
        love.graphics.push()
        love.graphics.translate(playButton.x + playButton.width / 2, playButton.y + playButton.height / 2)
        love.graphics.scale(playButton.scale)
        love.graphics.setColor(playButton.color)
        love.graphics.rectangle("fill", -playButton.width / 2, -playButton.height / 2, playButton.width, playButton.height, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(playButton.text, -playButton.width / 2, -playButton.height / 2 + 15, playButton.width, "center")
        love.graphics.pop()
    end
end

return card