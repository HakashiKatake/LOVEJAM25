local utility = {}

function utility.tableContains(tbl, elementName)
    for _, value in pairs(tbl) do
        if value.Name == elementName then
            return true
        end
    end
    return false
end

function utility.tableRemove(tbl, elementName)
    for index, value in pairs(tbl) do
        if value.Name == elementName then
            table.remove(tbl, index) 
            return true
        end
    end
    return false
end

return utility
