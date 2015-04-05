{Range, Point, BufferedProcess, BufferedNodeProcess} = require 'atom'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
path = require 'path'
fs = require 'fs'

class LinterFreebasic extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['source.freebasic']

  errorStream: 'stdout'

  linterName: 'fbc'

  lintFile: (filePath, callback) ->
    # NOTE: there is a difference between projectPath and @cwd
    # projectPath is self explanatory, cwd is the path of the file being linted
    # these are NOT the same things!
    projectPath = atom.project.getPaths()[0]

    verbose = atom.config.get 'linter-freebasic.verboseDebug'

    # parse space separated string taking care of quotes
    splitSpaceString = (string) ->
      regex = /[^\s"]+|"([^"]*)"/gi
      stringSplit = []

      loop
        match = regex.exec string
        if match
          newItem = if match[1] then match[1] else match[0]
          if newItem.length > 0
              stringSplit.push(newItem)
        else
          break

      return stringSplit

    @cmd = atom.config.get 'linter-freebasic.fbcCommand'

    {command, args} = @getCmdAndArgs(filePath)

    defaultFlags = splitSpaceString switch @editor.getGrammar().name
        when 'FreeBASIC'           then atom.config.get 'linter-freebasic.fbcDefaultFlags'

    args.push dflag for dflag in defaultFlags

    errorLimit = atom.config.get 'linter-freebasic.fbcErrorLimit'
    if(errorLimit != 0)
      args.push "-maxerr"
      args.push "#{errorLimit}"

    expandMacros = (stringToExpand) =>
      stringToExpand = stringToExpand.replace '%d', @cwd
      stringToExpand = stringToExpand.replace '%p', projectPath
      stringToExpand = stringToExpand.replace '%%', '%'
      return stringToExpand

    includePaths = (base, ipathArray) =>
      for ipath in ipathArray
        if ipath
          pathExpanded = expandMacros(ipath)
          pathResolved = path.resolve(base, pathExpanded)
          console.log "linter-freebasic: including #{ipath}, which expanded to #{pathResolved}" if atom.inDevMode() and verbose
          args.push "-i"
          args.push "#{pathResolved}"

    pathArray =
      splitSpaceString atom.config.get 'linter-freebasic.fbcIncludePaths'

    includePaths @cwd, pathArray

    # this function searches a directory for include path files
    searchDirectory = (base) =>
      try
        list = fs.readdirSync base
      catch err
        return

      for filename in list
        filenameResolved = path.resolve(base, filename)
        try
          stat = fs.statSync filenameResolved
        catch err
          continue

        if stat.isDirectory()
          searchDirectory filenameResolved
        if stat.isFile() and filename is '.linter-freebasic-includes'
          console.log "linter-freebasic: found #{filenameResolved}" if atom.inDevMode()
          content = fs.readFileSync filenameResolved, 'utf8'
          ###
            we have to parse it to enable using quotes and space.
            we treat it as if every line had quotes around it
            example:
              $ cat .linter-freebasic-includes
               path/to/bla
               path/two/bla with spaces
             -> results in:
               content = '"path/to/bla" "path/two/bla with spaces"'
             this will be taken by parseSpaceString appropriatly to:
               content = ['path/to/bla', 'path/two/bla with spaces']
             instead of
               content = ['path/to/bla', 'path/two/bla', 'with', 'spaces'] # WRONG!!!
          ###
          # only use line which contain stuff
          contentLines = (line for line in content.split "\n" when line)
          # Glue them together using quotes
          content = "\"" + (contentLines.join "\" \"") + "\""
          contentSplit = splitSpaceString content
          # dont give base as base parameter but the path of the resolved filename!!!
          # so that all paths inside .linter-freebasic-includes will be relative to the file, not the project path!
          includePaths (path.dirname filenameResolved), contentSplit
        if stat.isFile() and filename is '.linter-freebasic-flags'
          console.log "linter-freebasic: found #{filenameResolved}" if atom.inDevMode()
          content = fs.readFileSync filenameResolved, 'utf8'
          content = (content.split "\n").join " "
          contentSplit = splitSpaceString content
          contentExpanded = expandMacros flag for flag in contentSplit
          args.push contentExpanded

    searchDirectory projectPath

    # add file to regex to filter output to this file,
    # need to change filename a bit to fit into regex
    # @regex = filePath.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") +
    #   ':(?<line>\\d+):(?<col>\\d+):(\{(?<lineStart>\\d+):(?<colStart>\\d+)\\-(?<lineEnd>\\d+):(?<colEnd>\\d+)\}.*:)? ' +
    #   '((?<error>(?:fatal )?error)|(?<warning>warning)): (?<message>.*)'
    # @regex = filePath.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") +
    @regex = '(?<file>.*\\.bas)\\((?<line>\\d+)\\) (?<type>warning|error) (?<errnum>\\d+)\\(?(?<col>\\d+)?\\)?: (?<message>.*)'
    #@regex = '(?<file>.*)\\((?<line>\\d+)\\) ((?<warning>warning|?<error>error)) (?:\\d+\\)(?:\\()?(?<col>\\d+)?(?:\\)):(?:\\:) (?<message>.*)'

    if atom.inDevMode()
      console.log 'linter-freebasic: is node executable: ' + @isNodeExecutable

    # use BufferedNodeProcess if the linter is node executable
    if @isNodeExecutable
      Process = BufferedNodeProcess
    else
      Process = BufferedProcess

    # options for BufferedProcess, same syntax with child_process.spawn
    options = {cwd: @cwd}

    stdout = (output) =>
      if atom.inDevMode()
        console.log 'fbc: stdout', output
      if @errorStream == 'stdout'
        @processMessage(output, callback)

    stderr = (output) =>
      if atom.inDevMode()
        console.warn 'fbc: stderr', output
      if @errorStream == 'stderr'
        @processMessage(output, callback)

    if atom.inDevMode()
      console.log "linter-freebasic: command = #{command}, args = #{args}, options = #{options}"

    new Process({command, args, options, stdout, stderr})


  createMessage: (match) ->
    # message might be empty, we have to supply a value
    if match and match.type == 'parse' and not match.message
      message = 'error'

    super(match)

module.exports = LinterFreebasic
