#!/usr/bin/bash

rm -rf ./openshift-docs && mkdir ./openshift-docs

git clone --single-branch --depth 1 https://github.com/aireilly/openshift-docs.git ./openshift-docs

ASSEMBLIES=$(grep -rlw ./openshift-docs/scalability_and_performance --include=\*.adoc   -e ':_content-type: ASSEMBLY' | sort -u)

for ASSEMBLY in $ASSEMBLIES
  do asciidoctor-reducer $ASSEMBLY -o $ASSEMBLY

    #set product name and version
    PRODUCT_TITLE="OpenShift Container Platform"
    PRODUCT_VERSION="4.11"

    #generate docbook
    DOCBOOK_ASSEMBLY=$(asciidoctor -b docbook -a product-title="$PRODUCT_TITLE" -a product-version="$PRODUCT_VERSION" -o - $ASSEMBLY)

    #get the attribute-resolved page title for the converted .md file, eg., 
    #<title>Topology Aware Lifecycle Manager for cluster updates</title>
    PAGE_TITLE=$(echo "$DOCBOOK_ASSEMBLY" | grep -m 1 -oP "(?<=<title>).*?(?=<\/title>)")

    #generate markdown and adjust for publishing
    asciidoctor -b docbook -a product-title="$PRODUCT_TITLE" -a product-version="$PRODUCT_VERSION" -o - $ASSEMBLY | pandoc  --markdown-headings=atx --shift-heading-level-by=1 --wrap=none -t markdown_strict+backtick_code_blocks+footnotes+grid_tables+implicit_figures+footnotes+inline_notes+compact_definition_lists --lua-filter=admonitions.lua --lua-filter=tables.lua -f docbook - > ./$ASSEMBLY.md

    #gfm can't handle admonitions in tables
    #-t gfm+footnotes+implicit_figures+footnotes
    #-t markdown_strict+backtick_code_blocks+footnotes+grid_tables+implicit_figures+footnotes+inline_notes+compact_definition_lists

    sed -i "1s/^/# $PAGE_TITLE\n\n/" ./$ASSEMBLY.md

    #move to pub folder
    cp -r ./openshift-docs/scalability_and_performance ./docs

    #clean out adoc
    find ./docs/scalability_and_performance -name "*.adoc" -type f -delete

    #remove symlinks
    find ./docs/scalability_and_performance -maxdepth 1 -type l -delete

done

echo "assembly lift and shift complete!"

