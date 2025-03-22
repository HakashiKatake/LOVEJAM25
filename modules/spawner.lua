local spawner = {}
local Boss = require("modules.boss")

function spawner.spawnGround(world)
    ground = world:newRectangleCollider(0, 550, 800, 50)
    ground:setType('static')
    ground:setCollisionClass('Ground')
end

function spawner.spawnPlayer(world, playerX, playerY)
    isSpawned = true
    player = world:newRectangleCollider(playerX, playerY, 50, 50)
    playerTrigger = world:newRectangleCollider(playerX, playerY, 100, 100)
    playerTrigger:setType('static')
    playerTrigger:setSensor(true)
    playerTrigger:setCollisionClass('PlayerTrigger')
end

function spawner.spawnBoss(world)
    -- Example difficulty-based random logic:
    -- 1) Random Type
    -- 2) AttackDamage & Durability scale with difficulty
    -- 3) Possibly random AttackInterval & Speed

    local bossTypes = {"switcher", "brute"}
    local chosenType = bossTypes[math.random(#bossTypes)]

    -- Scale AttackDamage with difficulty, plus random range
    local randomAttackDamage = 10 * difficulty + math.random(0, 10)  
    -- Scale Durability with difficulty
    local randomDurability   = 200 * difficulty + math.random(0, 50)

    -- Maybe random AttackInterval & Speed within some range
    local randomInterval = math.random(1, 3) / difficulty  
    local randomSpeed    = 80 + math.random(0, 40) * difficulty

    boss = Boss:new(world, 500, 300, {
        Type           = chosenType,
        Difficulty     = difficulty,
        AttackSpeed    = 0.2,  -- or scale with difficulty if you want
        AttackDamage   = randomAttackDamage,
        AttackInterval = randomInterval,
        Durability     = randomDurability,
        Speed          = randomSpeed,
        JumpForce      = 500
    })
end

return spawner
