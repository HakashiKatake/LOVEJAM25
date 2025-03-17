local utility = {}

function utility.tableContains(tbl, elementName)
    for _, value in pairs(tbl) do
        if value.Name == elementName then
            return true
        end
    end
    return false
end

return utility
