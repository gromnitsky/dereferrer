#root = window ? exports ? this
root = exports ? this

$ = require '../vendor/zepto.shim'
_ = require 'underscore'
Backbone = require 'backbone'
ChromeStorage = require './chrome_storage'
storage = new ChromeStorage()

root.VERBOSE = 1


puts = (level, who) ->
  arguments[2] = "#{who}: #{arguments[2]}" if arguments?.length > 2 && who != ""
  msg = (val for val, idx in arguments when idx > 1)
  console.log.apply(console, msg) if level <= root.VERBOSE

class root.Doma
  constructor: (@raw) ->
    throw new Error 'input string is empty' unless @raw?.match /^\S{3,}$/

  size: ->
    (@raw.split '.').length

  match: (url) ->
    throw new Error 'not implemented'

  toString: ->
    @raw

isValidDomain = (domain) ->
  try
    new root.Doma domain
  catch e
    return false
  true

isValidReferer = (referer) ->
  return false unless referer?.match /^\S{3,}$/
  true

root.Refref = Backbone.Model.extend {
  toStorageFormat: ->
    obj = {}
    obj[@get('domain')] = {}
    obj[@get('domain')].referer = @get('referer')
    obj

  # Return promise
  sync: (method, model) ->
    data = model.toStorageFormat()
    puts 1, 'SYNC', '%s: %s: %s', model.cid, method, (JSON.stringify data)
    switch method
      when 'create', 'update'
        # remove previous, then update
        copy = model.clone()
        copy.set(model.previousAttributes(), {silent: true})
        @sync('delete', copy)
        .then ->
          storage.set(data)
        .then ->
          model.id = model.cid
          puts 1, 'SYNC', '%s: %s: ok', model.cid, method
        , (e) ->
          puts 0, 'SYNC', '%s: %s: FAIL: %s', model.cid, method, e.message
      when 'read'
        throw new Error 'not implemented'
      when 'delete'
        storage.rm(model.get('domain'))
        .then ->
          puts 1, 'SYNC', '%s: %s: ok', model.cid, method
        , (e) ->
          puts 0, 'SYNC', '%s: %s: FAIL: %s', model.cid, method, e.message

  validate: (attrs, options) ->
    return "domain is invalid" unless isValidDomain attrs.domain
    return "referer is invalid" unless isValidReferer attrs.referer
    undefined

  initialize: ->
    @on {
      'change': ->
        puts 1, 'change', @cid
        @save()
      'destroy': ->
        puts 1, 'destroy', @cid
        @view.remove()
    }
}

domFlash = (element, funcall) ->
  oldcolor = element.style.backgroundColor
  element.style.backgroundColor = 'red'
  try
    funcall()
  catch e
    alert "Error: #{e.message}"
    throw e
  finally
    element.style.backgroundColor = oldcolor

root.RefrefView = Backbone.View.extend {
  el: ->
    $('#refrefs').append "<tr id='#{@model.cid}'></tr>"
    '#' + @model.cid

  initialize: ->
    @model.view = this
    @listenTo(@model, 'change', @render)

  # can't use _.template() due to chrome policy that is too long to
  # describe here. TODO: find a nice templating library
  template: ->
    "<td class='refref-destroy'>x</td>
<td class='refref-domain-edit'><input value='#{@model.get('domain')}'></td>
<td class='refref-referer-edit'><input value='#{@model.get('referer')}'></td>"

  render: ->
    puts 1, "view render", @model.cid
    this.$el.html @template(@model.attributes)
    this

  # save changes in model from a gui element
  gui2model: (attr, event) ->
    puts 1, 'view dom change', @model.cid
    obj = {}
    obj[attr] = event.target.value
    if !@model.set obj, {validate: true}
      domFlash event.target, -> alert 'Invalid value'
      event.target.focus()

  events: {
    'change .refref-domain-edit': (event) ->
      @gui2model 'domain', event
    'change .refref-referer-edit': (event) ->
      @gui2model 'referer', event
    'click .refref-destroy': (event) ->
      puts 1, 'view destroy', "#{@model.cid}: isNew=#{@model.isNew()}"
      @model.destroy()
  }
}

# Fill google storage area with predefined options for several sites.
# Warning: clears every other data in the storage.
#
# Return a promise
setDefaults = ->
  puts 1, 'storage', 'cleaning & refilling'
  everybody_wants_this =
    'wsj.com':
      referer: 'http://news.google.com'
    'ft.com':
      referer: 'http://news.google.com'

  storage.clean()
  .then ->
    storage.set everybody_wants_this


# main
$ ->
  storage.getSize()
  .then (bytes) ->
    setDefaults() if bytes == 0
  .then ->
    puts 1, 'storage', 'reading'
    storage.get()
  .then (result) ->
    console.log result if root.VERBOSE

    r1 = new root.Refref { domain: 'wsj.com', referer: 'news.google.com' }
    r1_view = new root.RefrefView { model: r1 }
    r1_view.render()

    r2 = new root.Refref { domain: 'ft.com', referer: 'news.google.com' }
    r2_view = new root.RefrefView { model: r2 }
    r2_view.render()

    r1.set {referer: 'http://news.google.com!!!'}
  .done()
