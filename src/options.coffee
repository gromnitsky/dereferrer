root = exports ? this

$ = require '../vendor/zepto.shim'
_ = require 'underscore'
Backbone = require 'backbone'

fub = require './funcbug'
DomainZone = require './domainzone'
storage = new (require './chrome_storage')()


# Backbone model:
#
# { 'domain' : 'example.com',
#   'referer' : 'http://my.example.net'
#   'id' : 123 }
#
# In chrome storage:
#
# { 'example.com' : {
#     'referer' : 'http://my.example.net',
#     'id: 123
#   }
# }
#
# Special storage objects:
#
# { '__new_domain__' : {
#     'referer' : '__new_referer__'
#     'id': 'f8bfee95-2773-4427-y1a4-4567e156107e'
#   }
# }
root.Refref = Backbone.Model.extend {
  toStorageFormat: ->
    obj = {}
    obj[@get('domain')] =
      referer: @get('referer')
      id: @get('id')
    obj

  # Return promise
  sync: (method, model) ->
    data = model.toStorageFormat()
    fub.puts 1, 'SYNC', '%s: %s: %s', model.id, method, (JSON.stringify data)

    switch method
      when 'create', 'update'
        # remove previous, then update
        copy = model.clone()
        copy.set(model.previousAttributes(), {silent: true})
        @sync('delete', copy)
        .then ->
          storage.set(data)
        .then ->
          fub.puts 1, 'SYNC', '%s: %s: ok', model.id, method
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message
      when 'read'
        throw new Error 'not implemented'
      when 'delete'
        storage.rm(model.get('domain'))
        .then ->
          fub.puts 1, 'SYNC', '%s: %s: ok', model.id, method
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message

  validate: (attrs, options) ->
    return "domain is invalid" unless root.Refref.isValidDomain attrs.domain
    return "referer is invalid" unless root.Refref.isValidReferer attrs.referer
    return "id is invalid" unless attrs?.id
    undefined

  initialize: ->
    @on {
      'change': ->
        fub.puts 1, 'change', @id
        @save()
      'destroy': ->
        fub.puts 1, 'destroy', @id
        @view.remove()
    }
}, {
  # Model Class methods

  isValidDomain: (domain) ->
    try
      new DomainZone domain
    catch e
      return false
    true

  # empty string is valid
  isValidReferer: (referer) ->
    return false unless referer.match
    return false if referer.match /^\s+$/
    true

  isValidInternalStorageName: (name) ->
    name.match /^__[0-9A-Za-z_]+__$/

  storage2arr: (raw_data) ->
    console.log raw_data if root.VERBOSE
    ((val.domain = key; val) for key,val of raw_data when !root.Refref.isValidInternalStorageName(key))

  # Fill google storage area with predefined options for several sites.
  # Warning: clears every other data in the storage.
  #
  # Return a promise.
  setDefaults: ->
    fub.puts 1, 'storage', 'cleaning & refilling'
    everybody_wants_this =
      'wsj.com':
        referer: 'http://news.google.com'
        id: '1'
      'ft.com':
        referer: 'http://news.google.com'
        id: '2'

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
    $('#refrefs').append "<tr id='#{@model.id}'></tr>"
    '#' + @model.id

  initialize: ->
    throw new Error 'no model specified' unless @model
    @model.view = this
    @listenTo(@model, 'change', @render)

  # can't use _.template() due to chrome policy that is too long to
  # describe here. TODO: find a nice templating library
  template: ->
    "<td class='refref-destroy'>&empty;</td>
<td class='refref-domain-edit'><input value='#{@model.get('domain')}'></td>
<td class='refref-referer-edit'><input value='#{@model.get('referer')}'></td>"

  render: ->
    fub.puts 1, "view render", @model.id
    this.$el.html @template(@model.attributes)
    this

  # save changes in model from a gui element
  gui2model: (attr, event) ->
    fub.puts 1, 'view dom change', @model.id
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
      fub.puts 1, 'view destroy', "#{@model.id}: isNew=#{@model.isNew()}"
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
    @listenTo(@collection, 'add', @renderNewModel)

    $('#refrefs-add').on 'click', =>
      @collection.create {
        domain: '__new_domain__'
        referer: ''
        id: fub.uuid()
      }

  render: ->
    @collection.each (idx) ->
      mview = new root.RefrefView { model: idx }
      mview.render()
    this

  renderNewModel: (model) ->
    fub.puts 1, 'collection renderNewModel', model.id
    mview = new root.RefrefView { model: model }
    mview.render()

    elements = mview.$('input')
    idx.value = '' for idx in elements
    elements[0].focus()

    mview
}


# main
$ ->
  storage.getSize()
  .then (bytes) ->
    root.Refref.setDefaults() if bytes == 0
  .then ->
    fub.puts 1, 'storage', 'reading'
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
