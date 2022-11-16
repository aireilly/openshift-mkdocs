# Scratch pad

```cmd
curl -s https://api.github.com/repos/jgm/pandoc/releases/latest | grep "browser_download_url.*linux-amd64.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi -
tar -xvzf *linux-amd64.tar.gz
sudo mv pandoc /usr/local/bin/pandoc
pip install markdown-grid-tables
pip install pymdownx
pip install mkdocs
pip install mkdocs-material
gem install asciidoctor-reducer
```

```cmd
adoc-2md.sh && mkdocs serve
```

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

* codeblock callouts

``` markdown
    \`\`\`
     yaml
      apiVersion: performance.openshift.io/v2
      kind: PerformanceProfile
      metadata:
       name: example-performanceprofile # (1)
      spec:
      ...
        realTimeKernel:
          enabled: true
        nodeSelector:
           node-role.kubernetes.io/worker-rt: ""
        machineConfigPoolSelector:
           machineconfiguration.openshift.io/role: worker-rt
    \`\`\`

    1. Here is the callout thing.
```

Fig titles, "Procedure", 

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