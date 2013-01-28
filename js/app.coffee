require.config
  baseUrl: "js"
  paths:
    jquery: "../components/jquery/jquery"
    underscore: "../components/underscore/underscore"
    backbone: "../components/backbone/backbone"
    "backbone.viewdsl": "../components/backbone.viewdsl/backbone.viewdsl"
    soundmanager2: "../components/soundmanager/script/soundmanager2"
  shim:
    backbone:
      exports: "Backbone"
      deps: ["underscore", "jquery"]
    underscore:
      exports: "_"
    soundmanager2:
      exports: "soundManager"

define (require, exports) ->
  {View, renderInPlace} = require 'backbone.viewdsl'
  {extend, uniqueId} = require 'underscore'
  {Events} = require 'backbone'
  soundManager = require 'soundmanager2'


  class exports.SongLocatorClient
    extend this.prototype, Events

    constructor: (options) ->
      this.options = options
      this.sockOpenned = false
      # queue for delayed messages, while socket isn't ready
      this.delayed = []
      this.sock = new WebSocket(options.url or 'ws://localhost:3000')

      this.sock.onopen = =>
        this.log 'ready'
        # process delayed messages
        this.sockOpenned = true
        for msg in this.delayed
          this.sock.send(msg)

      this.sock.onmessage = (e) =>
        r = JSON.parse(e.data)
        this.trigger 'result', r

    send: (msg) ->
      msg = JSON.stringify(msg)
      if this.sockOpenned
        this.sock.send(msg)
      else
        this.delayed.push(msg)

    search: (qid, searchString) ->
      this.send {qid, searchString, method: 'search'}

    resolve: (qid, artist, track, album) ->
      this.send {qid, artist, track, album, method: 'resolve'}

    log: (msg) ->
      if this.options.debug
        console.log 'songlocator: ', msg

  class exports.App extends View
    className: 'app'
    parameterizable: true

    render: (partial) ->
      this.renderDOM(partial)

  class exports.SearchBox extends View
    tagName: 'input'
    className: 'search-box'
    attributes:
      name: 'query'
      type: 'text'
      placeholder: 'Search a song...'
    events:
      keypress: (e) ->
        return unless e.keyCode == 13 # Enter
        searchString = this.$el.val().trim()
        return unless searchString
        search(searchString)

  class exports.ResultList extends View
    tagName: 'ul'
    className: 'results'

    initialize: ->
      songlocator.on 'result', (result) =>
        return unless result.qid == this.qid
        for r in result.results
          this.renderResult(r) 

      Events.on 'songlocator:search songlocator:resolve', (qid) =>
        this.reset(qid)

    renderResult: (result) ->
      this.renderDOM """
        <li>
          <view name="app:SongView" model="result"></view>
        </li>
        """, {result: result}

    reset: (qid) ->
      this.qid = qid
      for v in this.views
        v.remove()
      this.$el.html('')


  class exports.SongView extends View
    className: 'song'
    events:
      click: ->
        Events.trigger 'songlocator:play', this.model

    render: ->
      this.$el.html $ """
        <span class="source">
          <a target="_blank" href="#{this.model.linkUrl or '#'}">#{this.model.source}</a>
        </span>
        <span class="track">#{this.model.track}</span>
        by <span class="artist">#{this.model.artist}</span>
        """

  exports.songlocator = new exports.SongLocatorClient
    url: 'ws://localhost:3000'
    debug: true

  exports.search = (searchString) ->
    qid = uniqueId('search')
    Events.trigger 'songlocator:search', qid, searchString
    songlocator.search(qid, searchString)

  exports.resolve = (artist, track, album) ->
    qid = uniqueId('resolve')
    Events.trigger 'songlocator:resolve', qid, artist, track, album
    songlocator.resolve(qid, artist, track, album)

  Events.on 'songlocator:play', (model) =>
    soundManager.stopAll()
    soundManager.createSound
      id: uniqueId('sound')
      url: model.url
      autoPlay: true
      autoLoad: true

  extend(window, exports)

  $ ->
    renderInPlace(document.body).done()
    soundManager.setup
      debugMode: false
      url: '../components/soundmanager/swf'

  exports
