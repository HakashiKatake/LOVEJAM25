local credits = {}
local game = require 'modules.game'
local moonshine = require 'libraries.moonshine'
local effect = moonshine(moonshine.effects.filmgrain)
    .chain(moonshine.effects.vignette)
    .chain(moonshine.effects.scanlines)
    .chain(moonshine.effects.chromasep)

-- Effect settings
effect.filmgrain.size = 3
effect.scanlines.opacity = 0.2

local text = {
    "Spade Knight",
    "a game made with love (literally).",
    "",
    "Developed by:",
    "3 + X = LÖVE",
    "",
    "Art by:",
    "Boony(boony62)",
    "",
    "Coded by:",
    "Hakashi Katake(.hakashikatake),",
    "MemoDev(memorysilver)",
    "",
    "Used:",
    "Font; Jersey10",
    "Libraries; Moonshine, Windfield, Anim8",
    "",
    "Special Thanks to LÖVE Community"
}

local yOffset = love.graphics.getHeight()
local speed = 30
local gameFont

function credits.load()
    -- Load the custom font
    gameFont = love.graphics.newFont("source/fonts/Jersey10.ttf", 45)
    -- Reset yOffset to start from the bottom
    yOffset = love.graphics.getHeight()
end

function credits.update(dt)
    -- Scroll the credits upwards
    yOffset = yOffset - speed * dt
    if yOffset + #text * 40 < 0 then
        yOffset = love.graphics.getHeight()  -- Reset position when credits reach the top
    end
end

function credits.draw()
    effect(function()
        -- Set the custom font
        love.graphics.setFont(gameFont)
        love.graphics.setColor(1, 1, 1)

        -- Draw each line of credits with the custom font
        for i, line in ipairs(text) do
            love.graphics.printf(line, 0, yOffset + (i - 1) * 40, love.graphics.getWidth(), "center")
        end
    end)
end

function credits.keypressed(key)
    game.resetGameState()
    currentState = "menu"
end

return credits
