local Boss = {}
Boss.__index = Boss

-- Create a new boss instance.
-- world: the physics world (from windfield)
-- x, y: starting coordinates
-- settings: a table containing boss variables
function Boss:new(world, x, y, settings)
    local instance = setmetatable({}, Boss)
    instance.world = world
    instance.collider = world:newRectangleCollider(x, y, 100, 100)
    instance.collider:setType("dynamic")
    instance.collider:setCollisionClass("Boss")
    
    -- Boss AI variables:
    instance.Difficulty     = settings.Difficulty or 1         -- e.g. multiplier for other stats
    instance.AttackSpeed    = settings.AttackSpeed or 0.2        -- can affect animation timing
    instance.AttackDamage   = settings.AttackDamage or 10      -- damage per attack
    instance.AttackInterval = settings.AttackInterval or 2     -- seconds between attacks
    instance.MaxDurability  = settings.Durability or 300       -- max boss health
    instance.Durability     = instance.MaxDurability           -- current health
    instance.Speed          = settings.Speed or 100            -- movement speed
    instance.JumpForce      = settings.JumpForce or 500        -- jump impulse force

    instance.attackTimer = 0  -- counts time between attacks
    instance.state = "idle"   -- can be expanded for more states
    return instance
end

-- Update the boss AI.
-- dt: delta time
-- player: the player object (assumed to have getX, getY, and optionally a takeDamage function)
function Boss:update(dt, player)
    self.attackTimer = self.attackTimer + dt

    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local distance = math.sqrt(dx * dx + dy * dy)

    -- If the player is close and the timer allows, attack.
    if distance < 200 and self.attackTimer >= self.AttackInterval then
        self:attack(player)
        self.attackTimer = 0
    -- Otherwise, move toward the player.
    elseif distance >= 200 then
        self:moveTowards(player, dt)
    end
end

-- Boss attacks the player.
function Boss:attack(player)
    print("Boss attacks for " .. self.AttackDamage .. " damage!")
    if player.takeDamage then
        player:takeDamage(self.AttackDamage)
    end
    -- You can add animations, sound effects, etc. here.
end

-- Moves the boss toward the player.
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
        dx = dx / distance
        dy = dy / distance
    end

    local vx = dx * self.Speed * dt
    local vy = dy * self.Speed * dt
    self.collider:setX(bx + vx)
    self.collider:setY(by + vy)
end

-- Makes the boss jump.
function Boss:jump()
    self.collider:applyLinearImpulse(0, -self.JumpForce)
end

-- Draw the boss and a boss health bar at the top center of the screen.
function Boss:draw()
    -- Draw the boss
    love.graphics.setColor(1, 0, 0)
    local x, y = self.collider:getPosition()
    love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    love.graphics.setColor(1, 1, 1)

    -- Health bar variables
    local screenWidth = love.graphics.getWidth()
    local healthBarWidth = 300
    local healthBarHeight = 25
    local healthPercentage = math.max(self.Durability / self.MaxDurability, 0)
    
    -- Dynamic color transition (Green -> Yellow -> Red)
    local r = math.min(2 * (1 - healthPercentage), 1)
    local g = math.min(2 * healthPercentage, 1)

    -- Health bar position (Top center of the screen)
    local barX = (screenWidth / 2) - (healthBarWidth / 2)
    local barY = 17  -- Position from top of the screen

    -- Health bar background (black border)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", barX - 2, barY - 2, healthBarWidth + 4, healthBarHeight + 4)

    -- Health bar foreground (dynamic color)
    love.graphics.setColor(r, g, 0)
    love.graphics.rectangle("fill", barX, barY, healthBarWidth * healthPercentage, healthBarHeight)

    -- Boss name above health bar
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("BOSS", barX, barY, healthBarWidth, "center")
end

return Boss
