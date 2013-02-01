define('xmlhttprequest', {XMLHttpRequest})

define (require, exports) ->
  {View, renderInPlace} = require 'backbone.viewdsl'
  {extend, uniqueId} = require 'underscore'
  soundManager = require 'soundmanager2'
  youtubeManager = require 'youtubemanager'
  {ResolverSet} = require 'songlocator-base'
  YouTubeResolver = require('songlocator-youtube').Resolver
  SoundCloudResolver = require('songlocator-tomahawk-soundcloud').Resolver
  ExfmResolver = require('songlocator-tomahawk-exfm').Resolver

  exports.resolver = new ResolverSet(
    new YouTubeResolver(),
    new ExfmResolver())

  class exports.App extends View
    className: 'app'
    parameterizable: true
    template: """
      <article>
        <view name="app:SearchBox"></view>
        <view name="app:ResultList"></view>
      </article>

      <footer>
        <div>
          <h3>SongLocator</h3>
          <p class="feedback">
            Have any feedback? Send me a <a
                target="_blank"
                href="https://twitter.com/share?related=SongLocatorWeb&text=@SongLocatorWeb"
                class="twitter-share-button"
                data-lang="en">tweet</a> or an
            <a href="mailto:8mayday+songlocator@gmail.com">email</a> message
          </p>
        </div>
      </footer>
      """

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

      app.on 'songlocator:search songlocator:resolve', (qid) =>
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
        <a target="_blank" attr-href="model.linkUrl">{{model.source}}</a>
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
        <div class="controls-wrapper">
          <i class="icon-play"></i>
          <i class="icon-pause"></i>
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

      'click .controls-wrapper': (e) ->
        e.stopPropagation()
        this.togglePause()

    initialize: ->
      app.on 'songlocator:play', (sound) =>
        this.stop() if sound != this.sound

    play: ->
      this.isPlaying = true
      this.$el.addClass('playing')
      this.$el.addClass('openned')
      this.sound = this.createSound() unless this.sound
      this.sound.play()
      app.trigger 'songlocator:play', this.sound

    stop: ->
      this.$progress.width(0)
      this.$el.removeClass('playing')
      this.$el.removeClass('openned')
      this.isPlaying = false
      this.sound.stop() if this.sound

    resume: ->
      this.isPlaying = true
      this.$el.addClass('playing')
      this.sound.resume()

    pause: ->
      this.isPlaying = false
      this.$el.removeClass('playing')
      this.sound.pause()

    togglePause: ->
      if this.isPlaying then this.pause() else this.resume()

    onPlaying: ->
      totalWidth = this.$el.width()
      soFar = (this.sound.position / this.sound.durationEstimate)
      this.$progress.width(soFar * totalWidth)

    createSound: ->
      player.createSound
        id: uniqueId('sound')

        playerId: this.playerId
        width: 200
        height: 200

        url: this.model.url or this.model.linkUrl
        whileplaying: => this.onPlaying()
        onstop: => this.stop()
        onfinish: => this.stop()

    remove: ->
      super
      this.sound.destruct() if this.sound?

    render: ->
      super.then =>
        this.playerId = uniqueId('cover')
        this.$cover.attr('id', this.playerId)

  exports.search = (searchString) ->
    qid = uniqueId('search')
    app.trigger 'songlocator:search', qid, searchString
    resolver.search(qid, searchString)

  exports.resolve = (track, artist, album) ->
    qid = uniqueId('resolve')
    app.trigger 'songlocator:resolve', qid, artist, track, album
    resolver.resolve(qid, track, artist, album)

  exports.player =

    createSound: (options) ->
      if /youtube.com/.test options.url
        youtubeManager.createSound(options)
      else
        soundManager.createSound(options)

  $ ->
    soundManager.setup(url: 'swf', debugMode: false)
    youtubeManager.setup()
    exports.app = app = new exports.App()
    app.render()
    document.body.appendChild(app.el)

  extend(window, exports)
  exports
