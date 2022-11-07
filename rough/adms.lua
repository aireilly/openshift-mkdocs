local stringify = (require 'pandoc.utils').stringify

local admonitions = {
  warning   = {pandoc.Str("!!! warning")},
  note      = {pandoc.Str("!!! note")},
  tip       = {pandoc.Str("!!! tip")},
  important = {pandoc.Str("!!! important")},
  caution   = {pandoc.Str("!!! caution")}
  }

function Writer (doc, opts)
  local filter = {
    Div = function (el)
      local admonition_text = admonitions[el.classes[1]]
      if admonition_text then
        table.insert(el.content, 1,
            pandoc.Para{ pandoc.Str(stringify(admonition_text)) })
      end
      local delimited = '```\n' .. el.content .. '\n```'
      return pandoc.RawBlock('markdown', delimited)
    end
  }
  return pandoc.write(doc:walk(filter), 'markdown_strict', opts)
end