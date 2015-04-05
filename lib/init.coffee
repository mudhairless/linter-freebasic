module.exports =
  configDefaults:
    fbcCommand: 'fbc'
    fbcIncludePaths: '.'
    fbcDefaultFlags: '-w all -pp'
    fbcErrorLimit: 0
    verboseDebug: false

  activate: ->
    console.log 'activate linter-freebasic' if atom.inDevMode()
