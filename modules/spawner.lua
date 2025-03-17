local spawner = {}

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
    boss = world:newRectangleCollider(500, 300, 100, 100)
    boss:setType('dynamic')
    boss:setCollisionClass('Boss')
    boss:setRestitution(0)
end

return spawner
