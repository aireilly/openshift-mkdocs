function Div(el)
  if el.classes[1] == "note" then
    -- insert element in front
    table.insert(
      el.content, 1,
      pandoc.RawBlock("markdown", "\\begin{Special}"))
    -- insert element at the back
    table.insert(
      el.content,
      pandoc.RawBlock("markdown", "\\end{Special}"))
  end
  return el
end