root = exports ? this

$ = require 'jquery-browserify'
_ = require 'underscore'
Backbone = require 'backbone'

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
    sync: (method, model) ->
        console.log "SYNC: #{model.cid}: #{method}: #{JSON.stringify model}"
        switch method
            when 'create' then model.id = model.cid
#            when 'delete' then model.id = null


    validate: (attrs, options) ->
        return "domain is invalid" unless isValidDomain attrs.domain
        return "referer is invalid" unless isValidReferer attrs.referer
        undefined
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
        @listenTo(@model, 'change', @render)

    template: _.template "<td class='refref-destroy'>x</td>
<td class='refref-domain-edit'><input value='<%= domain %>' required></td>
<td class='refref-referer-edit'><input value='<%= referer %>' required></td>"

    render: ->
        console.log "view render: #{@model.cid}"
        this.$el.html @template(@model.attributes)
        this

    # save changes in model from a gui element
    gui2model: (attr, event) ->
        console.log "view dom change: #{@model.cid}"
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
            console.log "view destroy: #{@model.cid}: isNew=#{@model.isNew()}"
            @model.destroy()
    }
}

$ ->
    r1 = new root.Refref { domain: 'wsj.com', referer: 'news.google.com' }
    r1_view = new root.RefrefView { model: r1 }
    r1_view.render()
    r1.myview = r1_view
    r1.on 'change', ->
        console.log "change: #{@cid}"
        @.save()
    r1.on 'destroy', ->
        console.log "destroy: #{@cid}"
        @myview.remove()

    r2 = new root.Refref { domain: 'ft.com', referer: 'news.google.com' }
    r2_view = new root.RefrefView { model: r2 }
    r2_view.render()

    r1.set {referer: 'http://news.google.com'}
