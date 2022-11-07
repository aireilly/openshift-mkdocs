local stringify = (require 'pandoc.utils').stringify

local admonitions = {
  warning   = {pandoc.Str("!!! warning")},
  note      = {pandoc.Str("!!! note")},
  tip       = {pandoc.Str("!!! tip")},
  important = {pandoc.Str("!!! important")},
  caution   = {pandoc.Str("!!! caution")}
  }

function Div (el)
  local admonition_text = admonitions[el.classes[1]]
  if admonition_text then
    for i, el in ipairs(el.content) do
        print(i .. " " .. el.tag .. "(" .. stringify(el) .. ")")
      end
    local content = 'derp' .. table.concat(el)
    return {
      pandoc.Para{ pandoc.Str(stringify(admonition_text)) },
      pandoc.RawBlock('markdown', '</div>' .. content),
      el
    }
  else
    return el
  end
end



