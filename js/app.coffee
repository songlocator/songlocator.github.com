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
    template: """
      <span class="source">
        <a target="_blank" attr-href="{model.linkUrl}">{{model.source}}</a>
      </span>
      <span class="track">{{model.track}}</span>
      <span class="artist">{{model.artist}}</span>
      <div element-id="$progress" class="progress"></div>
      """

    events:
      click: ->
        this.play()

    play: ->
      if not this.sound
        totalWidth = this.$el.width()
        this.sound = soundManager.createSound
          id: uniqueId('sound')
          url: this.model.url
          whileplaying: =>
            soFar = (this.sound.position / this.sound.durationEstimate)
            this.$progress.width(soFar * totalWidth)
          onstop: =>
            this.$progress.width(0)
      Events.trigger 'songlocator:play', this.sound

    remove: ->
      super
      this.sound.destruct() if this.sound?

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

  Events.on 'songlocator:play', (sound) =>
    soundManager.stopAll()
    sound.play()

  extend(window, exports)

  $ ->
    renderInPlace(document.body).done()
    soundManager.setup
      debugMode: false
      url: '../components/soundmanager/swf'

  exports
