#!/usr/bin/bash

PAGES=$(ls *.adoc)

if [[ -z "$PAGES" ]]; then
  echo "Oop! There are no pages in the current directory..."
else
  for PAGE in $PAGES 
    do PAGE_TITLE=$(grep '^=\s.*$' -m 1 $PAGE | sed 's/=/#/') 
    asciidoctor -b docbook -o - $PAGE | pandoc  --markdown-headings=atx --shift-heading-level-by=1 --wrap=none -t markdown_strict+backtick_code_blocks --lua-filter=admonitions.lua -f docbook - > ./docs/$PAGE.md
    #asciidoctor -b docbook -o - $PAGE | pandoc  --markdown-headings=atx --shift-heading-level-by=1 --wrap=preserve -t markdown_strict+backtick_code_blocks --lua-filter=admonitions.lua --to=native -f docbook - > ./docs/$PAGE.md
    sed -i "1s/^/$PAGE_TITLE\n\n/" ./docs/$PAGE.md
  done
  echo "*.adoc > ./docs/*.md conversion complete!"
fi


