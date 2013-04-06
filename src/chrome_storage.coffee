Q = require 'q'

# Do you see a pattern here?

class ChromeStorage
  constructor: (localOnly = true) ->
    unless chrome?.storage?
      throw new Error 'no chrome.storage object; set permissions in manifest'

    @storage = if localOnly then chrome.storage.local else chrome.storage.sync

  getSize: (obj = null) ->
    dfr = Q.defer()
    @storage.getBytesInUse obj, (bytes) ->
      if chrome.runtime?.lastError
        dfr.reject chrome.runtime.lastError
      else
        dfr.resolve bytes
    dfr.promise

  get: (obj = null) ->
    dfr = Q.defer()
    @storage.get obj, (items) ->
      if chrome.runtime?.lastError
        dfr.reject chrome.runtime.lastError
      else
        dfr.resolve items
    dfr.promise

  set: (obj) ->
    dfr = Q.defer()
    @storage.set obj, ->
      if chrome.runtime?.lastError
        dfr.reject chrome.runtime.lastError
      else
        dfr.resolve true
    dfr.promise

  rm: (obj) ->
    dfr = Q.defer()
    @storage.remove obj, ->
      if chrome.runtime?.lastError
        dfr.reject chrome.runtime.lastError
      else
        dfr.resolve true
    dfr.promise

  clean: ->
    dfr = Q.defer()
    @storage.clear ->
      if chrome.runtime?.lastError
        dfr.reject chrome.runtime.lastError
      else
        dfr.resolve true
    dfr.promise

module.exports = ChromeStorage
