local list_to_resources = {
  BulletList = function (el)
    local resources = {}
    local resource_attr = pandoc.Attr('', {'note'}, {})
    for i, item in ipairs(el.content) do
      resources[i] = pandoc.RawBlock("markdown", "\\end{Special}")
      --resources[i] = pandoc.Div(item, resource_attr)
    end
    return resources
  end
}

function Div (el)
  -- return div unaltered unless it is of class "Resources"
  if not el.classes:includes'note' then
    return nil
  end
  return pandoc.walk_block(el, list_to_resources)
end