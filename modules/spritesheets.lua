local anim8 = require 'libraries.anim8'

local spritesheets = {}

-- Load spritesheets
spritesheets.playerRunSheet = love.graphics.newImage('source/Sprites/Player/Player_Run_Spritesheet.png')
spritesheets.playerIdleSheet = love.graphics.newImage('source/Sprites/Player/Player_Idle_Spritesheet.png')
spritesheets.playerAttackSheet = love.graphics.newImage('source/Sprites/Player/Player_Attack_Spritesheet.png')

-- Define frame size based on the uploaded images
local frameWidth, frameHeight = 39, 39

-- Define grid
local gridRun = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerRunSheet:getWidth(), spritesheets.playerRunSheet:getHeight())
local gridIdle = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerIdleSheet:getWidth(), spritesheets.playerIdleSheet:getHeight())
local gridAttack = anim8.newGrid(frameWidth, frameHeight, spritesheets.playerAttackSheet:getWidth(), spritesheets.playerAttackSheet:getHeight())

-- Define animations (adjusting frame counts based on uploaded images)
spritesheets.runAnim = anim8.newAnimation(gridRun('1-4', 1), 0.1)  -- Run cycle (4 frames)
spritesheets.idleAnim = anim8.newAnimation(gridIdle('1-4', 1), 0.5) -- Idle cycle (4 frames)
spritesheets.attackAnim = anim8.newAnimation(gridAttack('1-3', 1), 0.2) -- Attack cycle (3 frames)

-- Current animation state
spritesheets.currentAnim = spritesheets.idleAnim

return spritesheets
