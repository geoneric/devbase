Devbase
=======
This project contains scripts that are useful in multiple development
projects. The project can be used as a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) of another project.

When working on multiple development projects, there are often scripts that are useful in more than one of those projects. Instead of copying these over, these can be collected in a seperate project and shared by the projects that need them. This way these shared scripts can be maintained at a single place.

As an example, consider a CMake script that finds some library `Blah` for which a standard CMake installation does not contain a `FindBlah.cmake` script. We can implement this file ourselves, or copy it from someplace else and store it in the Devbase project. Now all our projects can use this script to let CMake find the `Blah` library.
