ChromeStorage = require './chrome_storage'

storage = new ChromeStorage()

storage.getSize()
.then (bytes) ->
  console.log "loaded; storage: %d", bytes
.done()
