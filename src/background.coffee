Q = require 'q'

fub = require './funcbag'
storage = require './storage'

root = exports ? this

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
tc = new root.TrafficController()

storage.getSize()
.then (bytes) ->
  fub.puts 1, 'storage', '%s bytes', bytes
  storage.setDefaults() if bytes == 0
.then ->
  tc.rulesGet()
.then (model_data) ->
  tc.status()
  console.log model_data
.done()
