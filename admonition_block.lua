function Para(para)
  if para.content[1] and para.content[1].text == '!!!' and 
    para.content[2] and para.content[2].tag == 'Space' and 
    para.content[3] and para.content[3].tag == 'Str' then
    local text = para.content[3].text -- default title is tag
    tags = text
    title = string.upper(text)
    i = 4
    -- parse tags
    while para.content[i] and para.content[i].tag ~= 'SoftBreak'
    do
      -- tags can only be string or spaces
      if para.content[i].tag == 'Str' then
        tags = tags .. para.content[i].text
      elseif para.content[i].tag == 'Space' then
        tags = tags .. ' '
      -- Quoted is title
      elseif para.content[i].tag == 'Quoted' then
        title = pandoc.utils.stringify(para.content[i].content)
      end
      i = i + 1
    end
    if para.content[i] and para.content[i].tag == 'SoftBreak' then
      body = pandoc.List({table.unpack(para.content, i+1)})
    else
      body = '' -- no body
    end
    return pandoc.Blocks( -- merge into blocks
      {
        pandoc.RawInline(
          'html','<div class="admonition ' .. tags .. '">' ..
          '<p class="admonition-title">' .. title .. '</p>'
        ),
        pandoc.Plain(body),
        pandoc.RawInline('html', '</div>')
      }
    )
  end
end