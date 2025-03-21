local anim8 = require 'libraries.anim8'

local spritesheets = {}

-- Load spritesheets
spritesheets.playerRunSheet = love.graphics.newImage('source/Sprites/Player/Player_Run_Spritesheet.png')
spritesheets.playerIdleSheet = love.graphics.newImage('source/Sprites/Player/Player_Idle_Spritesheet.png')
spritesheets.playerAttackSheet = love.graphics.newImage('source/Sprites/Player/Player_Attack_Spritesheet.png')
spritesheets.playerJumpSheet = love.graphics.newImage('source/Sprites/Player/Player_Jump_Spritesheet.png')

-- Define frame size (adjust if needed)
local frameWidth, frameHeight = 39, 39

-- Define grids for each spritesheet
local gridRun = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerRunSheet:getWidth(), spritesheets.playerRunSheet:getHeight())
local gridIdle = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerIdleSheet:getWidth(), spritesheets.playerIdleSheet:getHeight())
local gridAttack = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerAttackSheet:getWidth(), spritesheets.playerAttackSheet:getHeight())
local gridJump = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerJumpSheet:getWidth(), spritesheets.playerJumpSheet:getHeight())

-- Define animations
spritesheets.runAnim = anim8.newAnimation(gridRun('1-4', 1), 0.1)
spritesheets.idleAnim = anim8.newAnimation(gridIdle('1-4', 1), 0.5)
spritesheets.attackAnim = anim8.newAnimation(gridAttack('1-3', 1), 0.2)
spritesheets.jumpAnim = anim8.newAnimation(gridJump('1-2', 1), 0.2)  -- Assuming jump has 2 frames

-- Current animation state
spritesheets.currentAnim = spritesheets.idleAnim

return spritesheets
