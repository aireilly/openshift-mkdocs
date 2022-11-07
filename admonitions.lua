-- requires pandoc 2.19+

local admonitions = {
  warning   = '!!! warning',
  note      = '!!! note',
  tip       = '!!! tip',
  important = '!!! important',
  caution   = '!!! caution'
}

local opts = PANDOC_WRITER_OPTIONS -- reuse options to render snippets
opts.columns = opts.columns - 4    -- admons are indented by four spaces
opts.template = nil                -- render a snippet

function Div (div)
  local admonition_text = admonitions[div.classes[1]]
  if not admonition_text then return nil end  -- not an admonition: exit

  local md = admonition_text .. '\n' ..
    pandoc.write(pandoc.Pandoc(div.content), 'markdown', opts)
  return pandoc.RawBlock(
    'markdown',
    md:gsub('\n*$', '')     -- remove trailing newlines
      :gsub('\n', '\n    ') -- indent block
  )
end