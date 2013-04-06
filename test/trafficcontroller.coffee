assert = require 'assert'

require './chrome_storage_mock'

chrome.webRequest = {
  onBeforeSendHeaders: {
    addListener: (details) ->
      # beep
  }
}
chrome.tabs =
  onUpdated:
    addListener: ->
      # boop

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

  test 'RefererSet fail', ->
    assert.equal null, bg.TrafficController.RefererSet()

    bg.TrafficController.RefererSet @webrequest2, ' '
    assert.equal null, bg.TrafficController.RefererFind(@webrequest2.requestHeaders)

  test 'RefererSet', ->
    assert.equal 'http://example.com', @webrequest1.requestHeaders[2].value
    bg.TrafficController.RefererSet @webrequest1, ' f o o '
    assert.equal 'foo', @webrequest1.requestHeaders[2].value

    # remove header
    bg.TrafficController.RefererSet @webrequest1, '  '
    assert.equal null, bg.TrafficController.RefererFind(@webrequest1.requestHeaders)

    # add it again
    bg.TrafficController.RefererSet @webrequest1, 'bar'
    assert.deepEqual {value: 'bar', index: 4 },
      bg.TrafficController.RefererFind(@webrequest1.requestHeaders)

  test 'requestModify fail', ->
    assert.deepEqual {}, bg.tc.requestModify()

    result = bg.tc.requestModify @webrequest2
    assert.equal null, bg.TrafficController.RefererFind(result.requestHeaders)

    @webrequest2.url = 'http://foo.example.com'
    result = bg.tc.requestModify @webrequest2
    assert.equal null, bg.TrafficController.RefererFind(result.requestHeaders)

  test 'requestModify', ->
    @webrequest2.url = 'http://online.wsj.com/article/123.html'
    result = bg.tc.requestModify @webrequest2
    assert.deepEqual {"index":4,"value":"http://news.google.com"},
      bg.TrafficController.RefererFind(result.requestHeaders)
