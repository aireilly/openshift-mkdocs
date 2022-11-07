-- This is a sample custom writer for pandoc, using Layout to
-- produce nicely wrapped output.

local layout = pandoc.layout
local text = pandoc.text
local type = pandoc.utils.type

local l = layout.literal

-- Table to store footnotes, so they can be included at the end.
local notes = pandoc.List()

-- Dispatch table for AST element writers
local dispatch = {}
local function write (elem)
  if type(elem) == 'Block' or type(elem) == 'Inline' then
    return (
      dispatch[elem.t] or dispatch[type(elem)] or
      error(('No function to convert %s (%s)'):format(elem.t, type(elem)))
    )(elem)  -- call dispatch function with element
  elseif type(elem) == 'Inlines' then
    return layout.concat(elem:map(write))
  elseif type(elem) == 'Blocks' then
    return layout.concat(elem:map(write), layout.blankline)
  end
  error('cannot convert unknown type: ' .. type(element))
end

function dispatch.Str(s)
  return layout.literal(s.text:gsub('[%[%]%#%`%\\]', '\\%0'))
end

function dispatch.Space()
  return layout.space
end

function dispatch.SoftBreak()
  return layout.space
end

function dispatch.LineBreak()
  return layout.cr
end

function dispatch.Emph(e)
  return write(e.content):inside('_', '_')
end

function dispatch.Strong(s)
  return write(s.content):inside('**', '**')
end

function dispatch.Subscript(s)
  return "~" .. write(s.content) .. "~"
end

function dispatch.Superscript(s)
  return "^" .. write(s.content) .. "^"
end

function dispatch.SmallCaps(s)
  return text.upper(s)
end

function dispatch.Strikeout(s)
  return '<del>' .. write(s.content) .. '</del>'
end

function dispatch.Link(link)
  local title = link.title == ''
    and ''
    or ' "' .. link.title:gsub('"', '\\"') .. '"'
  return write(link.content):brackets() .. l(link.target .. title):parens()
end

function dispatch.Image(img)
  local title = img.title == ''
    and ''
    or ' ' .. title:gsub('"', '\\"')
  return '!' .. write(pandoc.Inlines(img.content)):brackets() .. l(img.src .. title):parens()
end

function dispatch.Code(code)
  return layout.inside(code.text, '`', '`')
end

function dispatch.Math (m)
  if m.mathtype == 'InlineMath' then
    return l(m.text):inside('$', '$')
  else
    return l(m.text):inside('$$', '$$')
  end
end

function dispatch.Quoted(q)
  if q.quotetype == 'SingleQuote' then
    return write(q.content):quotes()
  else
    return write(q.content):double_quotes()
  end
end

function dispatch.Note(n)
  notes:insert(write(n.content))
  return '[^' .. tostring(#notes) .. ']'
end

function dispatch.Span(s)
  return write(s.content)
end

function dispatch.RawInline(raw)
  return raw.format == "markdown" and raw.text or ''
end

function dispatch.Cite (cite)
  return write(cite.content)
end

function dispatch.Plain(p)
  return write(p.content)
end

function dispatch.Para(p)
  return write(p.content)
end

function dispatch.Header(header)
  return layout.nowrap(string.rep('#', header.level) + write(header.content))
end

function dispatch.BlockQuote(bq)
  return write(bq.content):prefixed('> ')
end

function dispatch.HorizontalRule()
  return string.rep('- ', 7) .. '-'
end

function dispatch.LineBlock(ls)
  return '<div style="white-space: pre-line;">'
    .. layout.concat(ls.content:map(write), layout.cr)
    .. '</div>'
end

function dispatch.CodeBlock(cb)
  return l'```' / cb.text / '```'
end

function dispatch.BulletList(blist)
  local result = pandoc.List()
  for _, item in ipairs(blist.content) do
    result:insert(write(item):hang(2, '- '))
  end
  return layout.concat(result, layout.blankline)
end

function dispatch.OrderedList(olist)
  local result = pandoc.List()
  for i, item in ipairs(olist.content) do
    result:insert(write(item):hang(3, tostring(i) .. '. '))
  end
  return layout.concat(result, layout.blankline)
end

function dispatch.DefinitionList(dlist)
  local result = pandoc.List()
  for i, item in ipairs(dlist.content) do
    local key = write(item[1])
    local value = layout.concat(
      item[2]:map(write),
      layout.blankline
    )
    result:insert(key / value:hang(4, ':   '))
  end
  return layout.concat(result, layout.blankline)
end

function dispatch.Table(tbl)
  return l'TABLE NOT CONVERTED'
end

function dispatch.RawBlock(raw)
  return raw.format == 'markdown' and raw.text or layout.empty
end

function dispatch.Div(div)
  return write(div.content)
end

function Writer(doc, opts)
  local buffer = pandoc.List()
  buffer:insert(write(doc.blocks))
  for i, note in ipairs(notes) do
    buffer:insert(
      layout.blankline ..
      note:hang(6, '[^' .. tostring(i) .. ']: ')
    )
  end
  local body = layout.concat(buffer, layout.cr) .. layout.cr

  return body:render(opts.columns)
end