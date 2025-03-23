local Boss = {}
local utility = require 'modules.utility'
Boss.__index = Boss

local anim8 = require 'libraries.anim8'

--------------------------------------------------
-- 1) LOAD ALL SPRITES AND ANIMATIONS
--------------------------------------------------

-- Rock: default sprite and hit animation
local rockSprite = love.graphics.newImage("source/Sprites/Boss/Attack/rock001.png")
local rockAnimImage = love.graphics.newImage("source/Sprites/Boss/Attack/rock_anim.png")
local numRockFrames = 4
local frameWidthRock = rockAnimImage:getWidth() / numRockFrames
local frameHeightRock = rockAnimImage:getHeight()
local gridRockAnim = anim8.newGrid(frameWidthRock, frameHeightRock, rockAnimImage:getWidth(), rockAnimImage:getHeight())
local rockAnim = anim8.newAnimation(gridRockAnim('1-' .. numRockFrames, 1), 0.1, "pauseAtEnd")

-- Boss walking animation
local bossWalkImage = love.graphics.newImage("source/Sprites/Boss/Walk/boss_walk_def.png")
local numWalkFrames = 4
local frameWidthWalk = bossWalkImage:getWidth() / numWalkFrames
local frameHeightWalk = bossWalkImage:getHeight()
local gridWalk = anim8.newGrid(frameWidthWalk, frameHeightWalk, bossWalkImage:getWidth(), bossWalkImage:getHeight())
local walkAnim = anim8.newAnimation(gridWalk('1-' .. numWalkFrames, 1), 0.2)

-- Boss idle animation
local bossIdleImage = love.graphics.newImage("source/Sprites/Boss/Idle/boss_idle_def.png")
local numIdleFrames = 2  -- assuming 2 frames horizontally; first frame is default
local frameWidthIdle = bossIdleImage:getWidth() / numIdleFrames
local frameHeightIdle = bossIdleImage:getHeight()
local gridIdle = anim8.newGrid(frameWidthIdle, frameHeightIdle, bossIdleImage:getWidth(), bossIdleImage:getHeight())
local idleAnim = anim8.newAnimation(gridIdle('1-' .. numIdleFrames, 1), 0.3)

-- Boss melee attack animation (for switcher)
local bossAttackImage = love.graphics.newImage("source/Sprites/Boss/Attack/boss_attck_def.png")
local numAttackFrames = 3
local frameWidthAttack = bossAttackImage:getWidth() / numAttackFrames
local frameHeightAttack = bossAttackImage:getHeight()
local gridAttack = anim8.newGrid(frameWidthAttack, frameHeightAttack, bossAttackImage:getWidth(), bossAttackImage:getHeight())
local attackAnim = anim8.newAnimation(gridAttack('1-' .. numAttackFrames, 1), 0.1, "pauseAtEnd")

-- Boss quake animation (for brute mode)
local quakeImage = love.graphics.newImage("source/Sprites/Boss/Quake/boss_quake_def.png")
local numQuakeFrames = 2   -- adjust as needed
local frameWidthQuake = quakeImage:getWidth() / numQuakeFrames
local frameHeightQuake = quakeImage:getHeight()
local gridQuake = anim8.newGrid(frameWidthQuake, frameHeightQuake, quakeImage:getWidth(), quakeImage:getHeight())
local quakeAnim = anim8.newAnimation(gridQuake('1-' .. numQuakeFrames, 1), 0.15)

--------------------------------------------------
-- 2) LOAD SOUND EFFECTS
--------------------------------------------------
local howlSound = love.audio.newSource("source/SFX/bossHowl.wav", "static")
local quakeSound = love.audio.newSource("source/SFX/quakeAttack.mp3", "static")

-- Howling intervals (in seconds)
local howlIntervalMin = 10
local howlIntervalMax = 20

--------------------------------------------------
-- 3) BOSS CONSTRUCTOR
--------------------------------------------------
function Boss:new(world, x, y, settings)
    local instance = setmetatable({}, Boss)
    instance.world = world
    -- Create collider: offset down 20px and height 80px to remove head collider
    instance.collider = world:newRectangleCollider(x, y + 20, 100, 80)
    instance.collider:setType("dynamic")
    instance.collider:setCollisionClass("Boss")
    
    -- Prevent boss from spinning and flying
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
    
    instance.attackTimer    = 0
    instance.state          = "idle"
    instance.bossPoison     = false
    instance.bullets        = {}
    instance.rocks          = {}
    
    -- Boss facing: 1 for right, -1 for left
    instance.bossFlipX = 1
    
    -- Clone animations for this boss instance
    instance.walkAnim   = walkAnim:clone()
    instance.idleAnim   = idleAnim:clone()
    instance.attackAnim = attackAnim:clone()
    instance.quakeAnim  = quakeAnim:clone()
    
    -- Quake mode variables (for brute type)
    instance.quakeActive   = false
    instance.quakeTimer    = 0
    instance.quakeInterval = 5
    instance.quakeDuration = 2
    instance.quakeTimeLeft = 0
    
    -- Howling: set next howl time
    instance.nextHowlTime = love.timer.getTime() + math.random(howlIntervalMin, howlIntervalMax)
    
    -- Melee attack state (for switcher)
    instance.isAttacking    = false
    instance.attackDuration = 0.3  -- about 3 frames * 0.1 each
    instance.attackElapsed  = 0
    
    return instance
end

--------------------------------------------------
-- 4) BOSS UPDATE
--------------------------------------------------
function Boss:update(dt, player)
    self.attackTimer = self.attackTimer + dt

    -- Random howling
    local currentTime = love.timer.getTime()
    if currentTime >= self.nextHowlTime then
        howlSound:play()
        self.nextHowlTime = currentTime + math.random(howlIntervalMin, howlIntervalMax)
    end

    -- Update facing based on player's position
    local bx, by = self.collider:getPosition()
    local px, py = player:getX(), player:getY()
    self.bossFlipX = (px < bx) and -1 or 1

    -- If in melee attack state, update its animation
    if self.isAttacking then
        self.attackElapsed = self.attackElapsed + dt
        self.attackAnim:update(dt)
        if self.attackElapsed >= self.attackDuration then
            self.isAttacking = false
            self.attackAnim:gotoFrame(1)
            self.attackAnim:pause()
            self.state = "idle"
        end
    end

    -- Type-specific logic
    if self.Type == "switcher" then
        self:handleSwitcher(dt, player)
    elseif self.Type == "brute" then
        self:handleBrute(dt, player)
    end

    self:updateBullets(dt, player)
    self:updateRocks(dt, player)
end

--------------------------------------------------
-- 5) SWITCHER MODE LOGIC
--------------------------------------------------
function Boss:handleSwitcher(dt, player)
    local bx, by = self.collider:getPosition()
    local px, py = player:getX(), player:getY()
    local dx = px - bx
    local dy = py - by
    local distance = math.sqrt(dx * dx + dy * dy)

    if self.isAttacking then
        self.state = "attack"
        return
    end

    if distance < 40 then
        self:startMeleeAttack(player)
        self.state = "attack"
    elseif distance < 200 then
        self:moveTowards(player, dt)
        self.walkAnim:update(dt)
        self.state = "walk"
    else
        if self.attackTimer >= self.AttackInterval then
            self.attackTimer = 0
            self:spawnBullet(player)
            self.state = "attack"
        else
            self.state = "idle"
            self.idleAnim:update(dt)
        end
    end
end

function Boss:startMeleeAttack(player)
    self.isAttacking = true
    self.attackElapsed = 0
    self.attackAnim:gotoFrame(1)
    self.attackAnim:resume()
    if player.takeDamage then
        player:takeDamage(self.AttackDamage)
    else
        playerHealth = playerHealth - self.AttackDamage
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
        dirY = dy,
        hit = false
    }
    -- Assign the rock hit animation to this bullet; it will be used when it hits the player.
    bullet.rockAnim = rockAnim:clone()
    bullet.rockAnim:gotoFrame(1)
    bullet.rockAnim:pause()
    table.insert(self.bullets, bullet)
    print("Switcher shoots a bullet for " .. bullet.damage .. " damage!")
end

function Boss:updateBullets(dt, player)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        if not b.hit then
            b.x = b.x + b.dirX * b.speed * dt
            b.y = b.y + b.dirY * b.speed * dt
            if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
                table.remove(self.bullets, i)
            else
                local px, py = player:getX(), player:getY()
                local d = math.sqrt((px - b.x)^2 + (py - b.y)^2)
                if d < 35 then
                    if player.takeDamage then
                        player:takeDamage(b.damage)
                    else
                        playerHealth = playerHealth - b.damage
                    end
                    b.hit = true
                    b.rockAnim:gotoFrame(1)
                    b.rockAnim:resume()
                end
            end
        else
            b.rockAnim:update(dt)
            if b.rockAnim.position == #b.rockAnim.frames then
                table.remove(self.bullets, i)
            end
        end
    end
end

--------------------------------------------------
-- 6) BRUTE MODE LOGIC
--------------------------------------------------
function Boss:handleBrute(dt, player)
    if not self.quakeActive then
        self.quakeTimer = self.quakeTimer + dt
        if self.quakeTimer >= self.quakeInterval then
            self.quakeActive = true
            self.quakeTimeLeft = self.quakeDuration
            self.quakeTimer = 0
            print("Brute enters quake mode!")
            self.quakeAnim:gotoFrame(1)
            self.quakeAnim:resume()
            quakeSound:play()
            love.system.vibrate(0.1)
        end
    end

    if self.quakeActive then
        self.quakeTimeLeft = self.quakeTimeLeft - dt
        self.quakeAnim:update(dt)
        self.attackTimer = self.attackTimer + dt
        self.state = "attack"
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
        self.state = "walk"
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
    rock.rockAnim:pause()
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

--------------------------------------------------
-- 7) COMMON FUNCTIONS
--------------------------------------------------
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

--------------------------------------------------
-- 8) DRAW
--------------------------------------------------
function Boss:draw()
    local x, y = self.collider:getPosition()
    -- Boss scale: start at 1.5, increase by 0.5 per difficulty level, cap at 3
    local scale = math.min(1.5 + (self.Difficulty - 1) * 0.5, 3)
    local scaleX = scale * self.bossFlipX
    local scaleY = scale

    local animToDraw, imageToDraw, fw, fh

    if self.Type == "brute" and self.quakeActive then
        animToDraw  = self.quakeAnim
        imageToDraw = quakeImage
        fw, fh      = frameWidthQuake, frameHeightQuake
    elseif self.isAttacking then
        animToDraw  = self.attackAnim
        imageToDraw = bossAttackImage
        fw, fh      = frameWidthAttack, frameHeightAttack
    elseif self.state == "walk" then
        animToDraw  = self.walkAnim
        imageToDraw = bossWalkImage
        fw, fh      = frameWidthWalk, frameHeightWalk
    elseif self.state == "attack" then
        animToDraw  = self.attackAnim
        imageToDraw = bossAttackImage
        fw, fh      = frameWidthAttack, frameHeightAttack
    else
        animToDraw  = self.idleAnim
        imageToDraw = bossIdleImage
        fw, fh      = frameWidthIdle, frameHeightIdle
    end

    love.graphics.setColor(1,1,1,1)
    if animToDraw then
        local ox = fw / 2
        local oy = fh / 2
        animToDraw:draw(imageToDraw, x, y - 10, 0, scaleX, scaleY, ox, oy)
    else
        love.graphics.rectangle("fill", x - 50, y - 50, 100, 100)
    end

    -- Draw bullets
    for _, b in ipairs(self.bullets) do
        if not b.hit then
            local ox = rockSprite:getWidth() / 2
            local oy = rockSprite:getHeight() / 2
            love.graphics.draw(rockSprite, b.x, b.y, 0, 1, 1, ox, oy)
        else
            local ox = rockAnimImage:getWidth() / (numRockFrames * 2)
            local oy = rockAnimImage:getHeight() / 2
            b.rockAnim:draw(rockAnimImage, b.x, b.y, 0, 1, 1, ox, oy)
        end
    end

    -- Draw rocks
    for _, r in ipairs(self.rocks) do
        if r.hit then
            local ox = rockAnimImage:getWidth() / (numRockFrames * 2)
            local oy = rockAnimImage:getHeight() / 2
            r.rockAnim:draw(rockAnimImage, r.x, r.y, 0, 1, 1, ox, oy)
        else
            local ox = rockSprite:getWidth() / 2
            local oy = rockSprite:getHeight() / 2
            love.graphics.draw(rockSprite, r.x, r.y, 0, 1, 1, ox, oy)
        end
    end

    -- Draw boss health bar at the top-center
    local screenWidth = love.graphics.getWidth()
    local healthBarWidth = 300
    local healthBarHeight = 25
    local healthPerc = math.max(self.Durability / self.MaxDurability, 0)
    
    local rColor = math.min(2 * (1 - healthPerc), 1)
    local gColor = math.min(2 * healthPerc, 1)
    
    local barX = (screenWidth / 2) - (healthBarWidth / 2)
    local barY = 17
    
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", barX - 2, barY - 2, healthBarWidth + 4, healthBarHeight + 4)
    love.graphics.setColor(rColor, gColor, 0)
    love.graphics.rectangle("fill", barX, barY, healthBarWidth * healthPerc, healthBarHeight)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("BOSS", barX, barY, healthBarWidth, "center")
end

return Boss
