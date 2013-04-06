# Detection of browserify, node or browser
getGlobal = -> (_getGlobal = -> this)()
isBrowserify = -> exports? && !require?.extensions
root = if isBrowserify() then getGlobal() else exports ? getGlobal()

Q = require 'q'

DomainZone = require './domainzone'
fub = require './funcbag'
storage = require './storage'

class root.TrafficController

  constructor: ->
    @rulesFresh = false
    @rules = []

  # Return a promise.
  rulesGet: ->
    if @rulesFresh
      Q.fcall => @rules
    else
      storage.load()
      .then (model_data) =>
        @rulesFresh = true
        @rules = model_data

  size: ->
    Object.keys(@rules).length

  status: ->
    fub.puts 0, 'traffic_controller', '%d rules: fresh: %s', @size(), @rulesFresh

  # headers is an array from details object from onBeforeSendHeaders
  # listener.
  #
  # Return { index: 123, value: 'http://example.com' } or null.
  @RefererFind: (headers) ->
    return null unless headers

    obj = null
    for hdr,idx in headers
      if hdr?.name.match /^referer$/i
        obj = {}
        obj.index = idx
        obj.value = hdr.value
        break

    obj

  # Delete header if value is an empty string or null.
  @RefererSet: (webRequest, value) ->
    return unless webRequest?.requestHeaders
    ref = @RefererFind webRequest.requestHeaders
    value = value.replace /\s*/g, ''

    if value
      if ref
        webRequest.requestHeaders[ref.index].value = value
      else
        webRequest.requestHeaders.push {
          name: 'Referer'
          value: value
        }
    else
      webRequest.requestHeaders.splice ref.index, 1 if ref

  domainMatch: (url) ->
    return null unless url
    (return idx if DomainZone.Match(idx.domain, url)) for idx in @rules
    null

  requestModify: (webRequest) ->
    return {} unless webRequest?.requestHeaders

    dz = @domainMatch webRequest.url
    if dz
      root.TrafficController.RefererSet webRequest, dz.referer
      fub.puts 1, 'onBeforeSendHeaders', '%s: %s', webRequest.url, dz.referer

    {requestHeaders: webRequest.requestHeaders}

showIcon = (tabId, changeInfo, tab) ->
  return unless changeInfo.status == 'complete'
  dz = root.tc.domainMatch tab.url
  if dz
    chrome.pageAction.show(tabId)
    chrome.pageAction.setTitle {tabId: tabId, title: "Referer: #{dz.referer}"}


# main
root.tc = new root.TrafficController()

# hook into chrome's http request
chrome.webRequest.onBeforeSendHeaders.addListener (details) ->
  tc.requestModify details
, { urls: ['<all_urls>'] }, ['blocking', 'requestHeaders']

# listen for any changes to the url of any tab
chrome.tabs.onUpdated.addListener showIcon

storage.getSize()
.then (bytes) ->
  fub.puts 1, 'storage', '%s bytes', bytes
  storage.setDefaults() if bytes == 0
.then ->
  root.tc.rulesGet()
.then (model_data) ->
  root.tc.status()
.done()
