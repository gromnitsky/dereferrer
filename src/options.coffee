# Detection of browserify, node or browser
getGlobal = -> (_getGlobal = -> this)()
isBrowserify = -> exports? && !require?.extensions
root = if isBrowserify() then getGlobal() else exports ? getGlobal()

$ = require '../vendor/zepto.shim'
Backbone = require 'backbone'

fub = require './funcbag'
DomainZone = require './domainzone'
storage = require './storage'

isUnderTests = -> jasmine?

# Tell bg page to refresh refrefs.
notifyBackgroung = ->
  chrome.runtime.getBackgroundPage (bg) -> bg.tc?.rulesFresh = false

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
          notifyBackgroung()
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message
        .done()

      when 'read'
        throw new Error 'not implemented'

      when 'delete'
        return unless @get('domain')
        storage.rm(model.get('id'))
        .then ->
          fub.puts 1, 'SYNC', '%s: %s: ok', model.id, method
          notifyBackgroung()
        , (e) ->
          fub.puts 0, 'SYNC', '%s: %s: FAIL: %s', model.id, method, e.message
        .done()

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

    if this.$('.refref-destroy').length == 0
      this.$el.html @template()
    else
      # don't redraw the whole thing to preserves focus
      this.$('.refref-domain-edit').value = @model.get('domain')
      this.$('.refref-referer-edit').value = @model.get('referer')

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
      storage.setDefaults()
      .then ->
        storage.load()
      .then (model_data) ->
        self.collection.reset model_data
      .done()

    # a hack to force TrafficController object to reread all data from
    # the storage; this is necessary because callback in
    # onBeforeSendHeaders listener cannot wait for promises to return
    $('#refrefs-save').on 'click', ->
      chrome.runtime.getBackgroundPage (bg) ->
        bg.tc?.rulesGet()
        .then (model_data) ->
          console.log model_data if fub.VERBOSE
        .done()

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
    storage.setDefaults() if bytes == 0
  .then ->
    storage.load()
  .then (model_data) ->
    # create a collection, collection-view and call collection.reset()
    refrefs = new root.Refrefs()
    refrefs_table = new root.RefrefsView({collection: refrefs})
    refrefs.reset model_data
  .done()


# main
$ ->
  root.startHere() unless isUnderTests()
