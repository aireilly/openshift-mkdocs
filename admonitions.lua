local stringify = (require 'pandoc.utils').stringify

local admonitions = {
  warning   = {pandoc.Str("!!! warning")},
  note      = {pandoc.Str("!!! note")},
  tip       = {pandoc.Str("!!! tip")},
  important = {pandoc.Str("!!! important")},
  caution   = {pandoc.Str("!!! caution")}
  }

function Div(el)
  local admonition_text = admonitions[el.classes[1]]
  if admonition_text then
    table.insert(el.content, 1,
        --pandoc.Para{ pandoc.Str(stringify(admonition_text)) })
        pandoc.Plain{pandoc.Str(stringify(admonition_text) .. "\n" .. "    " .. stringify(el.content)) })
  end
  return el
end

