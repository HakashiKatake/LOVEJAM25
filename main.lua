local mainmenu = require 'modules.mainmenu'
local game = require 'modules.game'
local credits = require 'modules.credits'  -- Add the credits module

currentState = "menu"  -- Initial state is the main menu

function love.load()
    if currentState == "menu" then
        mainmenu.load()
    elseif currentState == "game" then
        game.load()
    elseif currentState == "credits" then
        credits.load()
    end
end

function love.update(dt)
    if currentState == "menu" then
        mainmenu.update(dt)
    elseif currentState == "game" then
        game.update(dt)
    elseif currentState == "credits" then
        credits.update(dt)
    end
end

function love.draw()
    if currentState == "menu" then
        mainmenu.draw()
    elseif currentState == "game" then
        game.draw()
    elseif currentState == "credits" then
        credits.draw()
    end
end

function love.keypressed(key)
    if currentState == "menu" then
        mainmenu.keypressed(key)
    elseif currentState == "game" then
        game.keypressed(key)
    elseif currentState == "credits" then
        credits.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if currentState == "menu" then
        mainmenu.mousepressed(x, y, button)
    elseif currentState == "game" then
        game.mousepressed(x, y, button)
    end
end
