root = exports ? this

$ = require '../vendor/zepto.shim'
_ = require 'underscore'
Backbone = require 'backbone'

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
    sync: (method, model) ->
        puts 1, 'SYNC', '%s: %s: %s', model.cid, method, (JSON.stringify model)
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
        @model.view = this
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

$ ->
    r1 = new root.Refref { domain: 'wsj.com', referer: 'news.google.com' }
    r1_view = new root.RefrefView { model: r1 }
    r1_view.render()
    r1.on 'change', ->
        puts 1, 'change',@cid
        @.save()
    r1.on 'destroy', ->
        puts 1, 'destroy',@cid
        @view.remove()

    r2 = new root.Refref { domain: 'ft.com', referer: 'news.google.com' }
    r2_view = new root.RefrefView { model: r2 }
    r2_view.render()

    r1.set {referer: 'http://news.google.com'}
