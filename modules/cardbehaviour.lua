local utility = require 'modules.utility'

local cardbehaviour = {}

function cardbehaviour.checkCardBehaviour(boughtCards, possibleCards, playerSpeed, playerHealth, maxBoughtCards, worldGravity, amountCards, boss)
    -- Card effects:
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

    if utility.tableContains(boughtCards, "Strength") or utility.tableContains(boughtCards, "RGB") then
        attackDamage = 15
    else
        attackDamage = 20
    end

    if utility.tableContains(boughtCards, "Quickhand") or utility.tableContains(boughtCards, "RGB") then
        attackSpeed = 3
    else
        attackSpeed = 1
    end

    if utility.tableContains(boughtCards, "Vampiric Strike") then
        if boss then
            boss.Durability = boss.Durability - boss.Durability * 0,15
            attackSpeed = 0.4
        end
    end
 

    if utility.tableContains(boughtCards, "Time Warp") then
        if boss.Durability > 50 and playerHealth < 50 then
            playerHealth = playerHealth + 20
            utility.tableRemove(boughtCards, "Time Warp")
        end 
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

    -- Return updated values
    return playerSpeed, playerHealth, maxBoughtCards, worldGravity, amountCards
end

return cardbehaviour
