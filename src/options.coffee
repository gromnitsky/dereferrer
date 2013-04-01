# Detection of browserify, node or browser
getGlobal = ->
  _getGlobal = -> this
  _getGlobal()
isUnderTests = -> jasmine?
isBrowserify = -> module?.exports? && !require?.extensions
root = if isBrowserify() then getGlobal() else exports ? getGlobal()

$ = require '../vendor/zepto.shim'
Backbone = require 'backbone'

fub = require './funcbag'
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
# { '123' : {
#     'domain': 'example.com'
#     'referer' : 'http://my.example.net',
#   }
# }
#
# Special storage objects:
#
# { '__my_options__' : {
#     'foo' : 'bar'
#   }
# }
root.Refref = Backbone.Model.extend {
  toStorageFormat: ->
    obj = {}
    obj[@get('id')] =
      domain: @get('domain')
      referer: @get('referer')
    obj

  sync: (method, model) ->
    switch method
      when 'create', 'update'
        storage.set(model.toStorageFormat())
        .then ->
          fub.puts 1, 'SYNC', '%s: %s: ok', model.id, method
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message
      when 'read'
        throw new Error 'not implemented'
      when 'delete'
        return unless @get('domain')

        storage.rm(model.get('id'))
        .then ->
          fub.puts 1, 'SYNC', '%s: %s: ok', model.id, method
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message

  validate: (attrs, options) ->
    return "domain is invalid" unless DomainZone.Validate attrs.domain
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

  # empty string is valid
  isValidReferer: (referer) ->
    return false unless referer.match
    return false if referer.match /^\s+$/
    true

  isValidInternalStorageName: (name) ->
    name.match /^__[0-9A-Za-z_]+__$/

  storage2arr: (raw_data) ->
    console.log raw_data if root.VERBOSE
    ((val.id = key; val) for key,val of raw_data when !root.Refref.isValidInternalStorageName(key))

  # Fill google storage area with predefined options for several sites.
  # Warning: clears every other data in the storage.
  #
  # Return a promise.
  setDefaults: ->
    fub.puts 1, 'storage', 'cleaning & refilling'
    everybody_wants_this =
      '1':
        domain: 'wsj.com'
        referer: 'http://news.google.com'
      '2':
        domain: 'ft.com'
        referer: 'http://news.google.com'

    storage.clean()
    .then ->
      storage.set everybody_wants_this
}

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
      fub.domFlash event.target, -> alert 'Invalid value'
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
    @listenTo(@collection, 'add', @addNew)

    $('#refrefs-add').on 'click', =>
      # model that won't pass its validation
      @collection.create {
        domain: ''
        referer: ''
        id: fub.uuid()
      }

  render: ->
    @collection.each (idx) ->
      mview = new root.RefrefView { model: idx }
      mview.render()
    this

  addNew: (model) ->
    fub.puts 1, 'collection', '(%s) addNew: %s', @collection.length, model.id
    mview = new root.RefrefView { model: model }
    mview.render()

    mview.$('input')[0].focus()
    mview
}

root.startHere = ->
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

#    console.log(document.querySelector('#refrefs'))
  .done()

$ ->
  root.startHere() unless isUnderTests()
