# Does nothing except checks that all libraries are loaded correctly
# even outside of a browser.

require './chrome_storage_mock'

global.window = document:
  addEventListener : ->

  createElement: ->
    {
      style: {}
    }

  defaultView:
    getComputedStyle: {}

global.navigator =
  userAgent: 'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.152 Safari/537.22'

options = require '../src/options'
