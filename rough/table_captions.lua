if FORMAT:match 'markdown' then
  function Table (elem)
    elem.caption = { pandoc.Raw '**' .. elem.caption .. pandoc.Raw '**' }
    return {elem}
  end
end