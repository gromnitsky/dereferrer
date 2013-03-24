assert = require 'assert'

o = require '../src/options'

suite 'Options', ->
    setup ->

    test 'invalid attrs for Refref', ->
        assert.equal false, (new o.Refref()).isValid()
        assert.equal false, (new o.Refref({domain: null})).isValid()
        assert.equal false, (new o.Refref({domain: '123', referer: '1'})).isValid()
        assert.equal false, (new o.Refref({domain: '123', referer: ' 123'})).isValid()

    test 'valid attrs for Refref', ->
        assert (new o.Refref({domain: '123', referer: '123'})).isValid()
