# linter-freebasic package

Lint FreeBASIC on the fly using the FreeBASIC compiler.


## Project-specific include paths
If your project has some extra include directories, put them in a file called ".linter-freebasic-includes" and list them line by line.
The linter will open the file and use the specified paths when linting in your project.

You can put your ".linter-freebasic-includes" files in subdirectories, too, the linter will find them and include the paths relative to the file they are specified in.

## Project-specific compiler flags
If your project has some extra compiler flags, put them in a file called ".linter-freebasic-flags" and list all flags.
The linter will open the file and use the specified flags when linting in your project.
You can put your flag file in subdirectories, too, however, no resolving of paths will take place.
For that, you can use macros (see below).

Note: Whenever there is a space in the flag file it will separate the strings before and after
when passing them as arguments to the compiler (like in the command line).
If you have a filename with a space, put it into quotes. Everything between quotes won't
be separated. The quotes will be removed after parsing.
Using quotes is therefore not supported yet (TODO: let the user put a backslash to escape the quote).

## Macros

The linter will expand the following macros in your ".linter-freebasic-includes" and ".linter-freebasic-flags" files:
 * `%d` -> the directory of the file being linted
 * `%p` -> the project path
 * `%%` -> `%`
