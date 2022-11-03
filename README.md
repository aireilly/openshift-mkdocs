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

1. Fix note formatting:
    ```markdown
    !!! note

        In this case, 10 CPUs are reserved on NUMA node 0 and 10 are reserved on NUMA node 1.
    ```

2. `xrefs`, etc.

3. Build all assemblies

4. Make a sensible navigation, etc.

5. script the asciidoc-reducer + site assembly part...