assert = require 'assert'

require './chrome_storage_mock'

chrome.webRequest = {
  onBeforeSendHeaders: {
    addListener: (details) ->
      # boo
  }
}

fub = require '../src/funcbag'
bg = require '../src/background'

fub.VERBOSE = -1

suite 'TrafficController', ->
  setup ->
    # with referer
    @webrequest1 =
      requestHeaders: [
        {
          name: "Accept",
          value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        },
        {
          name: "User-Agent",
          value: "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.152 Safari/537.22"
        },
        {
          name: "Referer",
          value: "http://example.com"
        },
        {
          name: "Accept-Encoding",
          value: "gzip,deflate,sdch"
        },
        {
          name: "Accept-Language",
          value: "en-US,en;q=0.8,ru;q=0.6"
        }
      ]

    # w/o referer
    @webrequest2 =
      requestHeaders: [
        {
          name: "Accept",
          value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        },
        {
          name: "User-Agent",
          value: "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.152 Safari/537.22"
        },
        {
          name: "Accept-Encoding",
          value: "gzip,deflate,sdch"
        },
        {
          name: "Accept-Language",
          value: "en-US,en;q=0.8,ru;q=0.6"
        }
      ]

  test 'default rules', ->
    assert.equal 2, bg.tc.size()

  test 'RefererFind', ->
    assert.equal null, bg.TrafficController.RefererFind()

    assert.deepEqual {value: 'http://example.com', index: 2 },
      bg.TrafficController.RefererFind(@webrequest1.requestHeaders)
    assert.equal null, bg.TrafficController.RefererFind(@webrequest2.requestHeaders)
