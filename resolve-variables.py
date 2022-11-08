#!/usr/bin/env python3
"""
$ resolve-variables.py $ASSEMBLY

Resolves all {variables} using the :variable: declaration that is specified at the head of the reduced assembly.adoc.
"""

import os
import sys
import re

#:op-system-first: Red Hat Enterprise Linux CoreOS (RHCOS) > {op-system-first} > Red Hat Enterprise Linux CoreOS (RHCOS)

variable_re = re.compile(r"(?<=^:.*:\s?\s).*")


def patch_file(filepath):
    with open(filepath, 'r') as f:
        contents = f.read()
    contents = contents.replace('include::modules/', 'include::ROOT:partial$')
    contents = contents.replace('include::_attributes/', 'include::ROOT:partial$')
    contents = contents.replace('include::snippets/', 'include::ROOT:partial$')

    dirpath = os.path.dirname(filepath) + '/'
    pages_idx = dirpath.find('/ROOT/pages/')
    if pages_idx != -1:
        page_dir = dirpath[pages_idx + len('/ROOT/pages/'):]

        def to_abs_path(m):
            return "xref:" + os.path.normpath(page_dir + m.group(1))

        contents = xref_re.sub(to_abs_path, contents)

    with open(filepath, 'w') as f:
        f.write(contents)


for filepath in sys.argv[1:]:
    patch_file(filepath)