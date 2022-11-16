#!/usr/bin/env python3
"""
This script patches the output markdown files by fixing the cross reference links based on the parent AsciiDoc assemblies.

1. Get array of xrefs lines from adoc
    1. For each xref ID, calculate the parent assembly
    2. Get the corresponding section title and lowercase it, replace " " with "-", etc.   
2. Open corresponding md file, update cross-refs
"""

import os
import sys
import re

xref_re = re.compile(r"xref:([^[#]+\.adoc)")
id_re = re.compile(r"id=\".*\"")
context_attr_re = re.compile(r"^:context:\s.*")
context_re = re.compile(r"^:context:\s.*")

def patch_file(filepath):
    with open(filepath, 'r') as f:
        contents = f.read()
        print(contents)
    #contents = contents.replace('include::modules/', 'include::ROOT:partial$')
    #contents = contents.replace('include::_attributes/', 'include::ROOT:partial$')
    #contents = contents.replace('include::snippets/', 'include::ROOT:partial$')

    #dirpath = os.path.dirname(filepath) + '/'
    #pages_idx = dirpath.find('/ROOT/pages/')
    #if pages_idx != -1:
        #page_dir = dirpath[pages_idx + len('/ROOT/pages/'):]

        #def to_abs_path(m):
            #return "xref:" + os.path.normpath(page_dir + m.group(1))

        #contents = xref_re.sub(to_abs_path, contents)

    #with open(filepath, 'w') as f:
        #f.write(contents)


for filepath in sys.argv[1:]:
    patch_file(filepath)