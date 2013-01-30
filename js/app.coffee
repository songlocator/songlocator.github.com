require.config
  baseUrl: "js"
  paths:
    jquery: "../components/jquery/jquery"
    underscore: "../components/underscore/underscore"
    backbone: "../components/backbone/backbone"
    "backbone.viewdsl": "../components/backbone.viewdsl/backbone.viewdsl"
    soundmanager2: "../components/soundmanager/script/soundmanager2"
    youtubemanager: "../components/youtubemanager/lib/youtubemanager"
    'songlocator-base': "../components/songlocator/lib/amd/songlocator-base"
    'songlocator-youtube': "../components/songlocator/lib/amd/songlocator-youtube"
  shim:
    backbone:
      exports: "Backbone"
      deps: ["underscore", "jquery"]
    underscore:
      exports: "_"
    soundmanager2:
      exports: "soundManager"

define('xmlhttprequest', {XMLHttpRequest})

define (require, exports) ->
  {View, renderInPlace} = require 'backbone.viewdsl'
  {extend, uniqueId} = require 'underscore'
  {Events} = require 'backbone'
  soundManager = require 'soundmanager2'
  youtubeManager = require 'youtubemanager'
  {ResolverSet} = require 'songlocator-base'
  YouTubeResolver = require('songlocator-youtube').Resolver

  exports.resolver = new ResolverSet(new YouTubeResolver())

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
      resolver.on 'results', (result) =>
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
    isPlaying: false
    template: """
      <span class="source">
        <a target="_blank" attr-href="{{model.linkUrl}}">{{model.source}}</a>
      </span>
      <div class="metadata-line">
        <span class="track">{{model.track}}</span>
        <span class="artist">{{model.artist}}</span>
      </div>
      <div element-id="$progress" class="progress"></div>
      <div element-id="$box" class="box">
        <div class="cover-wrapper">
          <div element-id="$cover"></div>
        </div>
        <div class="metadata-wrapper">
          <div class="track">{{model.track}}</div>
          <div class="artist">{{model.artist}}</div>
        </div>
      </div>
      """

    events:
      click: ->
        if not this.isPlaying
          this.play()
        else
          this.stop()

    initialize: ->
      Events.trigger 'songlocator:stop', =>
        this.stop()

    stop: ->
      this.$el.removeClass('playing')
      this.isPlaying = false
      this.sound.stop() if this.sound

    onPlaying: ->
      totalWidth = this.$el.width()
      soFar = (this.sound.position / this.sound.durationEstimate)
      this.$progress.width(soFar * totalWidth)

    createSound: ->
      this.sound = player.createSound
        id: uniqueId('sound')
        playerId: this.playerId
        width: 200
        height: 200
        url: this.model.linkUrl
        whileplaying: => this.onPlaying()
        onstop: => this.$progress.width(0)
        onfinish: => this.$progress.width(0)

    play: ->
      this.isPlaying = true
      this.$el.addClass('playing')
      if not this.sound
        this.createSound()
      Events.trigger 'songlocator:play', this.sound

    remove: ->
      super
      this.sound.destruct() if this.sound?

    render: ->
      super.then =>
        this.playerId = uniqueId('cover')
        this.$cover.attr('id', this.playerId)

  exports.search = (searchString) ->
    qid = uniqueId('search')
    Events.trigger 'songlocator:search', qid, searchString
    resolver.search(qid, searchString)

  exports.resolve = (track, artist, album) ->
    console.log 'resolve'
    qid = uniqueId('resolve')
    Events.trigger 'songlocator:resolve', qid, artist, track, album
    resolver.resolve(qid, track, artist, album)

  exports.player =

    createSound: (options) ->
      if /youtube.com/.test options.url
        youtubeManager.createSound(options)
      else
        soundManager.createSound(options)

  Events.on 'songlocator:play', (sound) =>
    Events.trigger 'songlocator:stop'
    sound.play()

  extend(window, exports)

  $ ->
    renderInPlace(document.body).done()
    soundManager.setup
      debugMode: false
      url: '../components/soundmanager/swf'
    youtubeManager.setup()

  exports
