#!/usr/bin/env python
import os
import sys
import docopt
import py_compile
import pycodestyle
sys.path = [os.path.join(os.path.dirname(__file__), "..", "source")] + sys.path
import devbase


doc_string = """\
Check whether one or more Python modules conform to Python coding standards

Usage:
    {command} <files>...
    {command} -h | --help

Options:
    -h --help   Show this screen
    --version   Show version
    files       A file is either a Python module or a directory to search

The names of modules and directories can be passed in. In the latter case
all modules recursively found in a directory tree are checked. Modules are
identified by comparing the file extension to (.py, .py.in)
""".format(
    command=os.path.basename(sys.argv[0]))


def find_python_modules(
        directory_name):

    module_pathnames = []

    for _, _, pathnames in os.walk(directory_name):
        for pathname in pathnames:
            if os.path.splitext(pathname)[1] in [".py", ".py.in"]:
                module_pathnames.append(pathname)

    return module_pathnames


def check_code_style(
        pathnames):

    style = pycodestyle.StyleGuide(
        ignore=["E402"]
    )
    nr_modules = 0
    nr_succeeding_modules = 0

    for pathname in pathnames:
        if os.path.isdir(pathname):
            check_code_style(find_python_modules(pathname))
        else:
            print("→ {}".format(pathname))

            nr_modules += 1
            status = py_compile.main([pathname])

            if status == 0:
                result = style.check_files([pathname])

                if result.total_errors == 0:
                    nr_succeeding_modules += 1

    if nr_modules > 0:
        print("{}/{} ({}%) of the modules were fine".format(
            nr_succeeding_modules, nr_modules,
            (100.0 * nr_succeeding_modules) / nr_modules))


if __name__ == "__main__":
    arguments = docopt.docopt(doc_string)
    pathnames = arguments["<files>"]

    sys.exit(check_code_style(pathnames))
