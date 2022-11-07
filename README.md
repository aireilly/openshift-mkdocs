# Scratch pad

```cmd
asciidoctor-reducer ~/openshift-docs/scalability_and_performance/cnf-create-performance-profiles.adoc -o ~/openshift-mkdocs/cnf-create-performance-profiles.adoc
```

Then:

```cmd
asciidoctor -b docbook -o - ~/openshift-mkdocs/cnf-create-performance-profiles.adoc | pandoc  --markdown-headings=atx --wrap=preserve -t markdown_strict --shift-heading-level-by=1 -f docbook -s - > ~/openshift-mkdocs/docs/cnf-create-performance-profiles.adoc.md
```


https://stackoverflow.com/questions/42706333/set-html-title-from-the-first-header-with-pandoc

and:

```cmd
mkdocs serve
```

Compare: 

https://docs.openshift.com/container-platform/4.11/scalability_and_performance/cnf-create-performance-profiles.html


## To do 

* `xrefs`:

currently: 

```asciidoc
xref:../cnf-create-performance-profiles.adoc#cnf-about-the-profile-creator-tool_cnf-create-performance-profiles[About the Performance Profile Creator]
```
>>>
```markdown
[About the Performance Profile Creator](../cnf-create-performance-profiles.xml#cnf-about-the-profile-creator-tool_cnf-create-performance-profiles)
```

needs to be: 

```markdown
[About the Performance Profile Creator](../cnf-create-performance-profiles.adoc#cnf-about-the-profile-creator-tool)
```


* Build all assemblies

* Make a sensible navigation, etc.

* script the asciidoc-reducer + site assembly part...

* live reload

### Notes

https://github.com/jgm/pandoc/issues/2610#issuecomment-880624080

https://github.com/rstudio/rmarkdown/blob/main/inst/rmarkdown/lua/latex-div.lua

https://github.com/turtlegraphics/book-test/blob/master/fenced-blocks.lua

https://github.com/jgm/pandocfilters/blob/master/examples/latexdivs.py

https://github.com/sergiocorreia/panflute

https://pypi.org/project/pantable/

https://github.com/jgm/pandoc/wiki/Pandoc-Filters