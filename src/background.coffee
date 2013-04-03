# Detection of browserify, node or browser
getGlobal = -> (_getGlobal = -> this)()
isBrowserify = -> exports? && !require?.extensions
root = if isBrowserify() then getGlobal() else exports ? getGlobal()

Q = require 'q'

fub = require './funcbag'
storage = require './storage'

class root.TrafficController

  constructor: ->
    @rulesFresh = false
    @rules = {}

  # Return a promise.
  rulesGet: ->
    if @rulesFresh
      Q.fcall => @rules
    else
      storage.load()
      .then (model_data) =>
        @rulesFresh = true
        @rules = model_data

  status: ->
    fub.puts 0, 'traffic_controller', '%d rules: fresh: %s',
      Object.keys(@rules).length, @rulesFresh


# main
root.tc = new root.TrafficController()

# hook into chrome's http request
chrome.webRequest.onBeforeSendHeaders.addListener (details) ->
  console.log details.requestHeaders
, { urls: ['<all_urls>'] }, ['blocking', 'requestHeaders']

storage.getSize()
.then (bytes) ->
  fub.puts 1, 'storage', '%s bytes', bytes
  storage.setDefaults() if bytes == 0
.then ->
  root.tc.rulesGet()
.then (model_data) ->
  root.tc.status()
  console.log model_data
.done()
