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
        local md = pandoc.write(pandoc.Pandoc(el.content), 'markdown')
        return pandoc.RawBlock('markdown', md):gsub('\n', '    \n')
      end
    end
  }
  return pandoc.write(doc:walk(filter), 'markdown_strict', opts)
end