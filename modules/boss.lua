local Boss = {}
Boss.__index = Boss

local anim8 = require 'libraries.anim8'

-- Load the rock sprite for brute mode
local rockSprite = love.graphics.newImage("source/Sprites/Boss/Attack/rock001.png")

-- Load the boss walking spritesheet
local bossWalkImage = love.graphics.newImage("source/Sprites/Boss/Walk/boss_walk_def.png")
-- Suppose the sheet has 4 frames in a row, each frame is 100×100 (adjust as needed).
local numWalkFrames = 4
local frameWidthWalk = bossWalkImage:getWidth() / numWalkFrames
local frameHeightWalk = bossWalkImage:getHeight()
local gridWalk = anim8.newGrid(frameWidthWalk, frameHeightWalk,
                               bossWalkImage:getWidth(), bossWalkImage:getHeight())
local walkAnim = anim8.newAnimation(gridWalk('1-'..numWalkFrames, 1), 0.2)

-- Load the quake animation spritesheet for brute "earthquake mode"
local quakeImage = love.graphics.newImage("source/Sprites/Boss/Quake/boss_quake_def.png")
-- Suppose the quake sheet has 3 frames in a row, each frame 100×100 (adjust as needed).
local numQuakeFrames = 2
local frameWidthQuake = quakeImage:getWidth() / numQuakeFrames
local frameHeightQuake = quakeImage:getHeight()
local gridQuake = anim8.newGrid(frameWidthQuake, frameHeightQuake,
                                quakeImage:getWidth(), quakeImage:getHeight())
local quakeAnim = anim8.newAnimation(gridQuake('1-'..numQuakeFrames, 1), 0.15)

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

    -- Boss facing factor: 1 for facing right, -1 for facing left
    instance.bossFlipX = 1

    -- Animations
    instance.walkAnim = walkAnim:clone()    -- normal walk
    instance.quakeAnim = quakeAnim:clone()  -- quake animation

    -- For quake logic
    instance.quakeActive = false       -- are we currently in quake mode?
    instance.quakeTimer = 0           -- accumulates time for next quake
    instance.quakeInterval = 5        -- how often to start quake mode
    instance.quakeDuration = 2        -- how long quake mode lasts
    instance.quakeTimeLeft = 0        -- how much time remains in quake mode

    return instance
end

function Boss:update(dt, player)
    self.attackTimer = self.attackTimer + dt

    -- Determine boss facing based on player position
    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    if px < bx then
        self.bossFlipX = -1
    else
        self.bossFlipX = 1
    end

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
    local distance = math.sqrt((px - bx)^2 + (py - by)^2)

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

    -- Update the normal walk animation if not in quake
    if not self.quakeActive and self.walkAnim then
        self.walkAnim:update(dt)
    end
end

function Boss:spawnBullet(player)
    local bx, by = self.collider:getX(), self.collider:getY()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
        dx, dy = dx / dist, dy / dist
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
    -- If quake not active, accumulate quakeTimer
    if not self.quakeActive then
        self.quakeTimer = self.quakeTimer + dt
        -- If quakeTimer exceeds quakeInterval, enter quake mode
        if self.quakeTimer >= self.quakeInterval then
            self.quakeActive = true
            self.quakeTimeLeft = self.quakeDuration
            self.quakeTimer = 0
            print("Brute enters quake mode!")
        end
    end

    if self.quakeActive then
        -- In quake mode, use quakeAnim, spawn rocks, etc.
        self.quakeTimeLeft = self.quakeTimeLeft - dt
        self.quakeAnim:update(dt)

        -- Continuously spawn rocks? or just once?
        -- Here we do them continuously, or you can do them at intervals.
        -- For demonstration, spawn a rock every second or so:
        self.attackTimer = self.attackTimer + dt
        if self.attackTimer >= 1 then
            self.attackTimer = 0
            self:spawnRock()
        end

        if self.quakeTimeLeft <= 0 then
            self.quakeActive = false
            print("Quake mode ended!")
        end
    else
        -- Normal follow if not in quake
        self:moveTowards(player, dt)
        -- Update normal walk anim if we want it moving
        if self.walkAnim then
            self.walkAnim:update(dt)
        end
    end
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

function Boss:takeDamage(amount)
    self.Durability = self.Durability - amount
    if self.Durability <= 0 then
        print("Boss defeated!")
        self.collider:destroy()
    end
end

function Boss:draw()
    local x, y = self.collider:getPosition()
    local scale = 2
    local scaleX = scale * self.bossFlipX
    local scaleY = scale

    -- Decide which animation to draw: quakeAnim if quakeActive, else walkAnim
    local animToDraw
    local frameWidth, frameHeight

    if self.Type == "brute" and self.quakeActive then
        animToDraw = self.quakeAnim
        frameWidth = frameWidthQuake
        frameHeight = frameHeightQuake
    else
        animToDraw = self.walkAnim
        frameWidth = frameWidthWalk
        frameHeight = frameHeightWalk
    end

    if animToDraw then
        love.graphics.setColor(1, 1, 1, 1)
        local ox = frameWidth / 2
        local oy = frameHeight / 2
        animToDraw:draw(
            (self.quakeActive and quakeImage) or bossWalkImage,
            x, y,
            0,
            scaleX, scaleY,
            ox, oy
        )
    else
        -- fallback
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    end

    -- Bullets
    for _, b in ipairs(self.bullets) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, 5)
    end

    -- Rocks
    for _, r in ipairs(self.rocks) do
        love.graphics.setColor(1, 1, 1, 1)
        local ox = rockSprite:getWidth() / 2
        local oy = rockSprite:getHeight() / 2
        love.graphics.draw(rockSprite, r.x, r.y, 0, 1, 1, ox, oy)
    end

    -- Health bar
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
