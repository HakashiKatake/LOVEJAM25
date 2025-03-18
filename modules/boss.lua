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
    instance.AttackSpeed    = settings.AttackSpeed or 1        -- can affect animation timing
    instance.AttackDamage   = settings.AttackDamage or 10      -- damage per attack
    instance.AttackInterval = settings.AttackInterval or 2     -- seconds between attacks
    instance.Durability     = settings.Durability or 300       -- boss health
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
    if distance < 300 and self.attackTimer >= self.AttackInterval then
        self:attack(player)
        self.attackTimer = 0
    -- Otherwise, move toward the player.
    elseif distance >= 300 then
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

-- Draw the boss and a simple health bar.
function Boss:draw()
    love.graphics.setColor(1, 0, 0)
    local x, y = self.collider:getPosition()
    love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    love.graphics.setColor(1, 1, 1)

    -- Simple health bar (assuming max durability of 300)
    local healthBarWidth = 100
    local healthBarHeight = 10
    local healthPercentage = self.Durability / 300
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x - 50, y - 60, healthBarWidth, healthBarHeight)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", x - 50, y - 60, healthBarWidth * healthPercentage, healthBarHeight)
    love.graphics.setColor(1, 1, 1)
end

return Boss
