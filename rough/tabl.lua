tables = 0
function Table(el)
    tables = tables + 1
    local caption = "Table " .. tostring(tables) .. ": " .. pandoc.utils.stringify(el.caption)
    el.caption = caption
    return el
end