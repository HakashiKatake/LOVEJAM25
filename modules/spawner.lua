local spawner = {}
local Boss = require("modules.boss")

function spawner.spawnGround(world)
    -- Ground collider
    ground = world:newRectangleCollider(0, 550, 800, 50)
    ground:setType('static')
    ground:setCollisionClass('Ground')

    -- Roof collider
    roof = world:newRectangleCollider(0, 0, 800, 10)
    roof:setType('static')
    roof:setCollisionClass('Ground')

    -- Left wall
    wallLeft = world:newRectangleCollider(0, 0, 10, 600)
    wallLeft:setType('static')
    wallLeft:setCollisionClass('Ground')

    -- Right wall
    wallRight = world:newRectangleCollider(790, 0, 10, 600)
    wallRight:setType('static')
    wallRight:setCollisionClass('Ground')
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
    local bossTypes = {"switcher", "brute"}
    local chosenType = bossTypes[math.random(#bossTypes)]

    -- Scale AttackDamage with difficulty + random
    local randomAttackDamage = 10 * difficulty + math.random(0, 10)
    -- Scale Durability with difficulty + random
    local randomDurability   = 200 * difficulty + math.random(0, 50)

    -- Maybe random AttackInterval & Speed
    local randomInterval = math.random(1, 3) / difficulty
    local randomSpeed    = 80 + math.random(0, 40) * difficulty

    boss = Boss:new(world, 500, 300, {
        Type           = chosenType,
        Difficulty     = difficulty,
        AttackSpeed    = 0.2,
        AttackDamage   = randomAttackDamage,
        AttackInterval = randomInterval,
        Durability     = randomDurability,
        Speed          = randomSpeed,
        JumpForce      = 500
    })
end

return spawner
