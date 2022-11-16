#remove _{context} strings, not required
sed -i "s/_{context}//g" $ASSEMBLY

#don't need to go up a level for xrefs
sed -i "s/xref:\.\.\//xref:/g" -i $ASSEMBLY

#adjust xrefs > lowercased section title
MODULE_IDS=$(cat $ASSEMBLY | grep '^\[id="[a-zA-Z0-9_-]*"]' | sed 's/\[id="//' | sed 's/"]//')

for MODULE_ID in $MODULE_IDS; do
  #how to escape ampersands in titles for sed???
  #SECTION_TITLE=$(cat $ASSEMBLY | $pcregrep -M '^\[id="'$MODULE_ID'"\]\n=.*' | sed -z 's/\[id=".*]\n=\s//')

  #get the section title that has id=$MODULE_ID
  SECTION_TITLE_ID=$(cat $ASSEMBLY | pcregrep -M '^\[id="'$MODULE_ID'"\]\n=[a-zA-Z0-9_-&]*')
  SECTION_TITLE=$(echo $SECTION_TITLE_ID | grep -m 1 -oP '(?<=\[id="'$MODULE_ID'"\]\s=*\s)(.*)')
  #replace space with underscore
  SECTION_TITLE=${SECTION_TITLE// /-}
  #replace double underscore with underscore
  SECTION_TITLE=${SECTION_TITLE/--/ /-}
  #lowercase
  MKDOCS_ID=${SECTION_TITLE,,}
  #switch the id in the xref
  sed -i "s/\#$MODULE_ID\[/\#$MKDOCS_ID\]/g" $ASSEMBLY
done