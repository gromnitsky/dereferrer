class DomainZone
  constructor: (@raw) ->
    throw new Error 'input string is empty' unless @raw?.match /^\S{3,}$/

  size: ->
    (@raw.split '.').length

  match: (url) ->
    throw new Error 'not implemented'

  toString: ->
    @raw

module.exports = DomainZone
