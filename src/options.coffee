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
          model.id = model.cid # TODO: make uuid
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
    return "domain is invalid" unless root.Refref.isValidDomain attrs.domain
    return "referer is invalid" unless root.Refref.isValidReferer attrs.referer
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
}, {
  # Model Class methods

  isValidDomain: (domain) ->
    try
      new root.Doma domain
    catch e
      return false
    true

  isValidReferer: (referer) ->
    return false unless referer?.match /^\S{3,}$/
    true

  storage2arr: (raw_data) ->
    console.log raw_data if root.VERBOSE
    ((val.domain = key; val) for key,val of raw_data)

  # Fill google storage area with predefined options for several sites.
  # Warning: clears every other data in the storage.
  #
  # Return a promise.
  setDefaults: ->
    puts 1, 'storage', 'cleaning & refilling'
    everybody_wants_this =
      'wsj.com':
        referer: 'http://news.google.com'
        id: 1
      'ft.com':
        referer: 'http://news.google.com'
        id: 2

    storage.clean()
    .then ->
      storage.set everybody_wants_this
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
    throw new Error 'no model specified' unless @model
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

root.Refrefs = Backbone.Collection.extend {
  model: root.Refref
}

root.RefrefsView = Backbone.View.extend {
  initialize: ->
    throw new Error 'no collection specified' unless @collection
    @listenTo(@collection, 'reset', @render)

  render: ->
    @collection.each (idx) ->
      mview = new root.RefrefView { model: idx }
      mview.render()
}

# main
$ ->
  storage.getSize()
  .then (bytes) ->
    root.Refref.setDefaults() if bytes == 0
  .then ->
    puts 1, 'storage', 'reading'
    storage.get()
  .then (result) ->
    # get an array of jsonified models
    model_data = root.Refref.storage2arr(result)

    # create a collection, collection-view and call collection.reset()
    refrefs = new root.Refrefs()
    refrefs_table = new root.RefrefsView({collection: refrefs})
    refrefs_table.render()
    refrefs.reset model_data
  .done()
