local Boss = {}
Boss.__index = Boss

local anim8 = require 'libraries.anim8'

-- Load sprites and animations

-- Default rock sprite (for non-hit rocks)
local rockSprite = love.graphics.newImage("source/Sprites/Boss/Attack/rock001.png")

-- Rock hit animation spritesheet (4 frames)
local rockAnimImage = love.graphics.newImage("source/Sprites/Boss/Attack/rock_anim.png")
local numRockFrames = 4
local frameWidthRock = rockAnimImage:getWidth() / numRockFrames
local frameHeightRock = rockAnimImage:getHeight()
local gridRockAnim = anim8.newGrid(frameWidthRock, frameHeightRock, rockAnimImage:getWidth(), rockAnimImage:getHeight())
local rockAnim = anim8.newAnimation(gridRockAnim('1-' .. numRockFrames, 1), 0.1, "pauseAtEnd")

-- Boss walking spritesheet and walk animation
local bossWalkImage = love.graphics.newImage("source/Sprites/Boss/Walk/boss_walk_def.png")
local numWalkFrames = 4
local frameWidthWalk = bossWalkImage:getWidth() / numWalkFrames
local frameHeightWalk = bossWalkImage:getHeight()
local gridWalk = anim8.newGrid(frameWidthWalk, frameHeightWalk, bossWalkImage:getWidth(), bossWalkImage:getHeight())
local walkAnim = anim8.newAnimation(gridWalk('1-' .. numWalkFrames, 1), 0.2)

-- Quake animation spritesheet for brute mode
local quakeImage = love.graphics.newImage("source/Sprites/Boss/Quake/boss_quake_def.png")
local numQuakeFrames = 3
local frameWidthQuake = quakeImage:getWidth() / numQuakeFrames
local frameHeightQuake = quakeImage:getHeight()
local gridQuake = anim8.newGrid(frameWidthQuake, frameHeightQuake, quakeImage:getWidth(), quakeImage:getHeight())
local quakeAnim = anim8.newAnimation(gridQuake('1-' .. numQuakeFrames, 1), 0.15)

-- Load sound effects
local howlSound = love.audio.newSource("source/SFX/bossHowl.wav", "static")
local quakeSound = love.audio.newSource("source/SFX/quakeAttack.mp3", "static")

-- Define howling intervals (in seconds)
local howlIntervalMin = 10
local howlIntervalMax = 20

function Boss:new(world, x, y, settings)
    local instance = setmetatable({}, Boss)
    instance.world = world
    -- Create a collider that starts 20 pixels lower and covers 80 pixels in height (removing the head)
    instance.collider = world:newRectangleCollider(x, y + 20, 100, 80)
    instance.collider:setType("dynamic")
    instance.collider:setCollisionClass("Boss")
    
    -- Fix rotation and increase mass/damping to prevent flying when player stands on the boss
    instance.collider:setFixedRotation(true)
    instance.collider:setMass(1000)
    instance.collider:setLinearDamping(5)
    
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
    
    -- Boss facing factor: 1 for right, -1 for left
    instance.bossFlipX = 1
    
    -- Clone animations for this boss instance
    instance.walkAnim = walkAnim:clone()
    instance.quakeAnim = quakeAnim:clone()
    
    -- Quake mode variables (for brute type)
    instance.quakeActive = false       -- Whether currently in quake mode
    instance.quakeTimer = 0            -- Time accumulator for quake mode
    instance.quakeInterval = 5         -- Interval between quake modes
    instance.quakeDuration = 2         -- Duration of quake mode
    instance.quakeTimeLeft = 0         -- Time left in current quake mode
    
    -- Set initial howling time for this boss instance
    instance.nextHowlTime = love.timer.getTime() + math.random(howlIntervalMin, howlIntervalMax)
    
    return instance
end

function Boss:update(dt, player)
    self.attackTimer = self.attackTimer + dt

    -- Check if it's time to howl randomly
    local currentTime = love.timer.getTime()
    if currentTime >= self.nextHowlTime then
        love.audio.play(howlSound)
        self.nextHowlTime = currentTime + math.random(howlIntervalMin, howlIntervalMax)
    end

    -- Update boss facing based on player's position
    local bx, by = self.collider:getPosition()
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
    local bx, by = self.collider:getPosition()
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

    if not self.quakeActive and self.walkAnim then
        self.walkAnim:update(dt)
    end
end

function Boss:spawnBullet(player)
    local bx, by = self.collider:getPosition()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local dist = math.sqrt(dx * dx + dy * dy)
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
            -- Increased hit radius from 25 to 35
            local d = math.sqrt((px - b.x)^2 + (py - b.y)^2)
            if d < 35 then
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
    -- Quake mode logic: accumulate quakeTimer until interval is reached
    if not self.quakeActive then
        self.quakeTimer = self.quakeTimer + dt
        if self.quakeTimer >= self.quakeInterval then
            self.quakeActive = true
            self.quakeTimeLeft = self.quakeDuration
            self.quakeTimer = 0
            print("Brute enters quake mode!")
            self.quakeAnim:gotoFrame(1)
            self.quakeAnim:resume()
            love.audio.play(quakeSound)    -- Play quake sound
            love.system.vibrate(0.1)         -- Trigger haptic feedback (if supported)
        end
    end

    if self.quakeActive then
        -- Update quake animation and spawn rocks at intervals
        self.quakeTimeLeft = self.quakeTimeLeft - dt
        self.quakeAnim:update(dt)
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
        self:moveTowards(player, dt)
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
        damage = 10 * self.Difficulty,
        hit = false
    }
    rock.rockAnim = rockAnim:clone()
    rock.rockAnim:gotoFrame(1)
    rock.rockAnim:pause()  -- Start paused; will resume on hit
    table.insert(self.rocks, rock)
end

function Boss:updateRocks(dt, player)
    for i = #self.rocks, 1, -1 do
        local r = self.rocks[i]
        if r.hit then
            r.rockAnim:update(dt)
            if r.rockAnim.position == #r.rockAnim.frames then
                table.remove(self.rocks, i)
            end
        else
            r.y = r.y + r.speedY * dt
            if r.y > love.graphics.getHeight() + 50 then
                table.remove(self.rocks, i)
            else
                local px, py = player:getX(), player:getY()
                -- Increased rock hit radius from 30 to 40
                local d = math.sqrt((px - r.x)^2 + (py - r.y)^2)
                if d < 40 then
                    if player.takeDamage then
                        player:takeDamage(r.damage)
                    else
                        playerHealth = playerHealth - r.damage
                    end
                    r.hit = true
                    r.rockAnim:gotoFrame(1)
                    r.rockAnim:resume()
                end
            end
        end
    end
end

---------------------------------
-- COMMON FUNCTIONS
---------------------------------
function Boss:moveTowards(player, dt)
    local bx, by = self.collider:getPosition()
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
    -- Calculate boss scale based on difficulty:
    -- Starting at 1.5, increasing by 0.5 per difficulty level, capped at 3
    local scale = math.min(1.5 + (self.Difficulty - 1) * 0.5, 3)
    local scaleX = scale * self.bossFlipX
    local scaleY = scale

    -- Choose which animation to draw:
    local animToDraw, imageToDraw, fw, fh
    if self.Type == "brute" and self.quakeActive then
        animToDraw = self.quakeAnim
        imageToDraw = quakeImage
        fw, fh = frameWidthQuake, frameHeightQuake
    else
        animToDraw = self.walkAnim
        imageToDraw = bossWalkImage
        fw, fh = frameWidthWalk, frameHeightWalk
    end

    if animToDraw then
        love.graphics.setColor(1, 1, 1, 1)
        local ox = fw / 2
        local oy = fh / 2
        -- Adjust drawing position (subtract 10 pixels) for proper alignment with collider
        animToDraw:draw(imageToDraw, x, y - 10, 0, scaleX, scaleY, ox, oy)
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    end

    -- Draw bullets
    for _, b in ipairs(self.bullets) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, 5)
    end

    -- Draw rocks: if a rock has hit, draw its hit animation; otherwise, draw the default rock sprite
    for _, r in ipairs(self.rocks) do
        if r.hit then
            love.graphics.setColor(1, 1, 1, 1)
            local ox = rockAnimImage:getWidth() / (numRockFrames * 2)
            local oy = rockAnimImage:getHeight() / 2
            r.rockAnim:draw(rockAnimImage, r.x, r.y, 0, 1, 1, ox, oy)
        else
            love.graphics.setColor(1, 1, 1, 1)
            local ox = rockSprite:getWidth() / 2
            local oy = rockSprite:getHeight() / 2
            love.graphics.draw(rockSprite, r.x, r.y, 0, 1, 1, ox, oy)
        end
    end

    -- Draw boss health bar at the top-center of the screen
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
