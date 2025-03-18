local spawner = {}
local Boss = require("modules.boss")  -- require the boss module

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
    -- Create a boss instance using our boss module.
    boss = Boss:new(world, 500, 300, {
        Difficulty = 2,
        AttackSpeed = 1,
        AttackDamage = 15,
        AttackInterval = 2,
        Durability = 300,
        Speed = 100,
        JumpForce = 500
    })
end

return spawner
