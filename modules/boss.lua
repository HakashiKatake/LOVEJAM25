local Boss = {}
Boss.__index = Boss

function Boss:new(world, x, y, settings)
    local instance = setmetatable({}, Boss)
    instance.world = world
    instance.collider = world:newRectangleCollider(x, y, 100, 100)
    instance.collider:setType("dynamic")
    instance.collider:setCollisionClass("Boss")

    instance.Difficulty     = settings.Difficulty or 1
    instance.AttackSpeed    = settings.AttackSpeed or 0.2
    instance.AttackDamage   = settings.AttackDamage or 10
    instance.AttackInterval = settings.AttackInterval or 2
    instance.MaxDurability  = settings.Durability or 300
    instance.Durability     = instance.MaxDurability
    instance.Speed          = settings.Speed or 100
    instance.JumpForce      = settings.JumpForce or 500
    instance.Type           = settings.Type or "switcher"

    instance.attackTimer = 0
    instance.state = "idle"
    instance.bossPoison = false

    instance.bullets = {}
    instance.rocks = {}
    return instance
end

function Boss:update(dt, player)
    self.attackTimer = self.attackTimer + dt

    if self.Type == "switcher" then
        self:handleSwitcher(dt, player)
    elseif self.Type == "brute" then
        self:handleBrute(dt, player)
    end

    self:updateBullets(dt, player)
    self:updateRocks(dt, player)
end

---------------------------------
-- SWITCHER MODE LOGIC
---------------------------------
function Boss:handleSwitcher(dt, player)
    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 200 then
        self:moveTowards(player, dt)
        if distance < 40 then
            self:attack(player)
        end
    else
        if self.attackTimer >= self.AttackInterval then
            self.attackTimer = 0
            self:spawnBullet(player)
        end
    end
end

function Boss:spawnBullet(player)
    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
        dx, dy = dx/dist, dy/dist
    end
    local bullet = {
        x = bx,
        y = by,
        speed = 300,
        damage = 2 * self.Difficulty,
        dirX = dx,
        dirY = dy
    }
    table.insert(self.bullets, bullet)
    print("Switcher shoots a bullet for " .. bullet.damage .. " damage!")
end

function Boss:updateBullets(dt, player)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.x = b.x + b.dirX * b.speed * dt
        b.y = b.y + b.dirY * b.speed * dt

        if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
            table.remove(self.bullets, i)
        else
            local px, py = player:getX(), player:getY()
            local d = math.sqrt((px - b.x)^2 + (py - b.y)^2)
            if d < 25 then
                if player.takeDamage then
                    player:takeDamage(b.damage)
                else
                    playerHealth = playerHealth - b.damage
                end
                table.remove(self.bullets, i)
            end
        end
    end
end

---------------------------------
-- BRUTE MODE LOGIC
---------------------------------
function Boss:handleBrute(dt, player)
    self:moveTowards(player, dt)
    if self.attackTimer >= self.AttackInterval then
        self.attackTimer = 0
        self:attackShake()
    end
end

function Boss:attackShake()
    for i = 1, 5 do
        self:spawnRock()
    end
    print("Brute uses Shake!")
end

function Boss:spawnRock()
    local rock = {
        x = math.random(50, love.graphics.getWidth() - 50),
        y = -50,
        speedY = 200,
        damage = 10 * self.Difficulty
    }
    table.insert(self.rocks, rock)
end

function Boss:updateRocks(dt, player)
    for i = #self.rocks, 1, -1 do
        local r = self.rocks[i]
        r.y = r.y + r.speedY * dt
        if r.y > love.graphics.getHeight() + 50 then
            table.remove(self.rocks, i)
        else
            local px, py = player:getX(), player:getY()
            local d = math.sqrt((px - r.x)^2 + (py - r.y)^2)
            if d < 30 then
                if player.takeDamage then
                    player:takeDamage(r.damage)
                else
                    playerHealth = playerHealth - r.damage
                end
                table.remove(self.rocks, i)
            end
        end
    end
end

---------------------------------
-- COMMON FUNCTIONS
---------------------------------
function Boss:moveTowards(player, dt)
    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local distance = math.sqrt(dx * dx + dy * dy)

    if self.bossPoison then
        self.Durability = self.Durability - 0.5
    end

    if distance > 0 then
        dx, dy = dx / distance, dy / distance
    end

    local vx = dx * self.Speed * dt
    local vy = dy * self.Speed * dt
    self.collider:setX(bx + vx)
    self.collider:setY(by + vy)
end

function Boss:jump()
    self.collider:applyLinearImpulse(0, -self.JumpForce)
end

function Boss:attack(player)
    print("Boss attacks for " .. self.AttackDamage .. " damage!")
    if player.takeDamage then
        player:takeDamage(self.AttackDamage)
    else
        playerHealth = playerHealth - self.AttackDamage
    end
end

-- Notice: We do NOT set boss = nil here. We only destroy the collider and let the game code handle the rest.
function Boss:takeDamage(amount)
    self.Durability = self.Durability - amount
    if self.Durability <= 0 then
        print("Boss defeated!")
        self.collider:destroy()
        -- No boss = nil line here, so the game can detect boss.Durability <= 1 and trigger the popup
    end
end

function Boss:draw()
    love.graphics.setColor(1, 0, 0)
    local x, y = self.collider:getPosition()
    love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    love.graphics.setColor(1, 1, 1)

    for _, b in ipairs(self.bullets) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, 5)
    end

    for _, r in ipairs(self.rocks) do
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.circle("fill", r.x, r.y, 15)
    end

    local screenWidth = love.graphics.getWidth()
    local healthBarWidth = 300
    local healthBarHeight = 25
    local healthPercentage = math.max(self.Durability / self.MaxDurability, 0)

    local rColor = math.min(2 * (1 - healthPercentage), 1)
    local gColor = math.min(2 * healthPercentage, 1)

    local barX = (screenWidth / 2) - (healthBarWidth / 2)
    local barY = 17

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", barX - 2, barY - 2, healthBarWidth + 4, healthBarHeight + 4)
    
    love.graphics.setColor(rColor, gColor, 0)
    love.graphics.rectangle("fill", barX, barY, healthBarWidth * healthPercentage, healthBarHeight)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("BOSS", barX, barY, healthBarWidth, "center")
end

return Boss
