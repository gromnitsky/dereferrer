# Detection of browserify, node or browser
getGlobal = -> (_getGlobal = -> this)()
isBrowserify = -> exports? && !require?.extensions
root = if isBrowserify() then getGlobal() else exports ? getGlobal()

$ = require '../vendor/zepto.shim'
Backbone = require 'backbone'

fub = require './funcbag'
DomainZone = require './domainzone'
storage = new (require './chrome_storage')()

isUnderTests = -> jasmine?

# For having not only Refref models in the storage. Reserved for the
# future. For example, __options__
storage.isValidHiddenKey = (name) ->
  name.match /^__[0-9A-Za-z_]+__$/

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
    return "referer is invalid" unless root.Refref.IsValidReferer attrs.referer
    return "id is invalid" unless attrs?.id
    undefined

  initialize: ->
    @on {
      'change': ->
        fub.puts 1, 'model change', @id
        @save()

      'destroy': ->
        fub.puts 1, 'model destroy', @id
        @view.remove()
    }

}, {
  # Class methods

  # Empty string is valid too.
  IsValidReferer: (referer) ->
    return false unless referer.match
    return false if referer.match /^\s+$/
    true

  Storage2arr: (raw_data) ->
    ((val.id = key; val) for key,val of raw_data when !storage.isValidHiddenKey(key))

  # Fill google storage area with predefined options for several sites.
  # Warning: clears every other data in the storage.
  #
  # Return a promise.
  SetDefaults: ->
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

  # Load all models form the storage.
  # Return a promise.
  Load: ->
    fub.puts 1, 'storage', 'reading'
    storage.get()
    .then (result) ->
      # an array of jsonified models
      return root.Refref.Storage2arr(result)
}

root.RefrefView = Backbone.View.extend {
  el: ->
    $('#refrefs').append "<tr id='#{@model.id}'></tr>"
    '#' + @model.id

  initialize: ->
    throw new Error 'no model linked' unless @model
    @model.view = this
    @listenTo @model, 'change', @render

  # can't use _.template() due to chrome policy that is too long to
  # describe here. TODO: find a nice templating library
  template: ->
    "<td class='refref-destroy'>&empty;</td>
<td class='refref-domain-edit'><input value='#{@model.get('domain')}'></td>
<td class='refref-referer-edit'><input value='#{@model.get('referer')}'></td>"

  render: ->
    fub.puts 1, 'model view', 'render: %s', @model.id
    this.$el.html @template()
    this

  # save changes in model from a gui element
  gui2model: (attr, event) ->
    fub.puts 1, 'model view', 'dom change: %s', @model.id
    obj = {}
    obj[attr] = event.target.value
    if !@model.set obj, {validate: true}
      fub.domFlash event.target.parentNode.parentNode, -> alert 'Invalid value'
      event.target.focus()

  events: {
    'change .refref-domain-edit': (event) ->
      if @model.collection?.filterByDomain(event.target.value, @model.id).length > 0
        fub.domFlash event.target.parentNode.parentNode, -> alert 'Domain must be unique'
        event.target.focus()
      else
        @gui2model 'domain', event

    'change .refref-referer-edit': (event) ->
      @gui2model 'referer', event

    'click .refref-destroy': (event) ->
      # removes itself from the linked collection too
      fub.puts 1, 'model view', 'destroy: %s: isNew=%s', @model.id, @model.isNew()
      collection = @model.collection
      @model.destroy()
      fub.puts 1, 'collection size', collection.length if collection
  }
}

root.Refrefs = Backbone.Collection.extend {
  model: root.Refref,

  filterByDomain: (domain, id) ->
    @filter (idx) ->
      domain == idx.get('domain') && id != idx.id
}

root.RefrefsView = Backbone.View.extend {
  el: '#refrefs'

  # just a table header
  template: '<tr><th>&equiv;</th><th>Domain</th><th>Referrer</th></tr>'

  initialize: ->
    throw new Error 'no collection linked' unless @collection
    @listenTo @collection, 'reset', @render
    @listenTo @collection, 'add', @addRefref

    $('#refrefs-add').on 'click', =>
      # model that won't pass its validation
      @collection.create {
        domain: ''
        referer: ''
        id: fub.uuid()
      }

    self = this
    $('#refrefs-reset').on 'click', ->
      return unless confirm 'Are you sure? \n\nAll your customizations will be lost without an ability to undo.'
      root.Refref.SetDefaults()
      .then ->
        root.Refref.Load()
      .then (model_data) ->
        self.collection.reset model_data

  render: ->
    fub.puts 1, 'collection view', 'render'
    this.$el.html @template

    @collection.each (idx) ->
      mview = new root.RefrefView { model: idx }
      mview.render()
    this

  addRefref: (model) ->
    fub.puts 1, 'collection view', 'cur size: %s; addRefref: %s', @collection.length, model.id
    mview = new root.RefrefView { model: model }
    mview.render()

    mview.$('input')[0].focus()
    mview
}

root.startHere = ->
  storage.getSize()
  .then (bytes) ->
    root.Refref.SetDefaults() if bytes == 0
  .then ->
    root.Refref.Load()
  .then (model_data) ->
    # create a collection, collection-view and call collection.reset()
    refrefs = new root.Refrefs()
    refrefs_table = new root.RefrefsView({collection: refrefs})
    refrefs.reset model_data
  .done()


# main
$ ->
  root.startHere() unless isUnderTests()
