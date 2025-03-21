local utility = {}

-- Check if a table contains an element with a specific Name
function utility.tableContains(tbl, elementName)
    for _, value in pairs(tbl) do
        if value.Name == elementName then
            return true
        end
    end
    return false
end

-- Remove an element from a table by Name
function utility.tableRemove(tbl, elementName)
    for index, value in pairs(tbl) do
        if value.Name == elementName then
            table.remove(tbl, index)
            return true
        end
    end
    return false
end

-- Function to handle screen fading
function utility.screenFade(imagePath, fadeinDuration, displayDuration, fadeoutDuration)
    local timer = 0
    local alpha = 0
    local image = love.graphics.newImage(imagePath)

    return function(dt)
        timer = timer + dt

        if timer < fadeinDuration then
            alpha = timer / fadeinDuration
        elseif timer < fadeinDuration + displayDuration then
            alpha = 1
        elseif timer < fadeinDuration + displayDuration + fadeoutDuration then
            alpha = 1 - ((timer - fadeinDuration - displayDuration) / fadeoutDuration)
        else
            alpha = 0
        end

        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(image, 0, 0)
    end
end

return utility