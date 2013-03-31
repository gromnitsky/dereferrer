assert = require 'assert'

dz = require '../src/domainzone'

suite 'DomainZone', ->
  setup ->

  test 'invalid domains', ->
    assert.throws -> new dz()
    assert.throws -> new dz('')
    assert.throws -> new dz(' 234')
    assert.throws -> new dz('1 2')
    assert.throws -> new dz({})
    assert.throws -> new dz(1234)
    assert.throws -> new dz('1..')
    assert.throws -> new dz('...')
    assert.throws -> new dz('.2.')
    assert.throws -> new dz('12.')

  test 'match ok', ->
    assert dz.Match('localhost', 'https://example.localhost?foo=bar')
    assert dz.Match('localhost', 'https://localhost?foo=bar')
    assert dz.Match('c.net', 'https://b.c.net')
    assert dz.Match('com', 'https://example.com')
    assert dz.Match('co.uk', 'https://example.co.uk')

  test 'match fail', ->
    assert.equal false, dz.Match('example.localhost', 'http://localhost')
    assert.equal false, dz.Match('a.b.c.net', 'http://c.net')
    assert.equal false, dz.Match('c.net', 'http://a.net')
