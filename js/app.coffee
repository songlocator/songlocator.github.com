define('xmlhttprequest', {XMLHttpRequest})

define (require, exports) ->
  {extend, uniqueId} = require 'underscore'

  {Collection} = require 'backbone'
  {View, renderInPlace} = require 'backbone.viewdsl'
  {Record} = require 'backbone.record'

  soundManager = require 'soundmanager2'
  youtubeManager = require 'youtubemanager'

  {ResolverSet, rankSearchResults} = require 'songlocator-base'
  YouTubeResolver = require('songlocator-youtube').Resolver
  SoundCloudResolver = require('songlocator-tomahawk-soundcloud').Resolver
  ExfmResolver = require('songlocator-tomahawk-exfm').Resolver

  class Stream extends Record
    @define 'track', 'artist', 'source', 'audioURL', 'linkURL', 'imageURL', 'rank'

  class Song extends Record
    @define 'track', 'artist', 'streams'

    constructor: ->
      super
      this.streams = this.streams or new Collection()
      this.streams = new Collection(this.streams) if not (this.streams instanceof Collection)

    rank: ->
      Math.min.apply(null, this.streams.map((s) -> s.rank))

    fullTitle: ->
      "#{this.track} - #{this.artist}"

  class Songs extends Collection

    comparator: (song) ->
      song.rank()

    findSong: (track, artist) ->
      this.find (song) ->
        song.artist.toLowerCase() == artist.toLowerCase() \
          and song.track.toLowerCase() == track.toLowerCase()

    addStream: (stream) ->
      song = this.findSong(stream.track, stream.artist)
      if song
        streams = song.streams.where(source: stream.source)
        song.streams.add(stream) if streams.length == 0
      else
        song = new Song(track: stream.track, artist: stream.artist, streams: [stream])
        this.add(song)

  resolver = new ResolverSet(
    new YouTubeResolver(),
    new SoundCloudResolver(),
    new ExfmResolver())

  class App extends View
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

  class SearchBox extends View
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

  class ResultList extends View
    tagName: 'ul'
    className: 'results'

    initialize: ->
      this.collection = this.collection or new Songs()

      this.collection.on 'add', (model) =>
        this.renderSong(model)

      resolver.on 'results', (result) =>
        return unless result.qid == this.query.qid
        if this.query.searchString?
          rankSearchResults(result.results, this.query.searchString)
        this.processResult(r) for r in result.results

      app.on 'songlocator:search songlocator:resolve', (query) =>
        this.reset(query)

    processResult: (result) ->
      return if result.rank > 10

      stream = new Stream
        track: result.track
        artist: result.artist
        source: result.source
        audioURL: result.url
        linkURL: result.linkUrl
        imageURL: undefined
        rank: result.rank

      this.collection.addStream(stream)

    appendAt: (node, idx) ->
      $children = this.$el.children()
      if idx >= $children.size()
        this.$el.append(node)
      else
        $children.eq(idx).before(node)

    renderSong: (song) ->
      ctx = {song}
      this
        .renderTemplate('<li><view name="app:SongView" model="song"></view></li>', {song})
        .then (node) =>
          this.appendAt(node, this.collection.indexOf(song))
        .done()

    reset: (query) ->
      this.query = query
      for v in this.views
        v.remove()
      this.$el.html('')

  class SongView extends View
    className: 'song'
    isPlaying: false
    template: """
      <span class="source" element-id="$sourceLinks">{{sourceLinks}}</span>
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

    initialize: ->
      app.on 'songlocator:play', (sound) =>
        this.stop() if sound != this.sound
      this.model.streams.on 'add', =>
        this.$sourceLinks.html(this.sourceLinks())

    sourceLinks: ->
      this.model.streams.map (stream) ->
        $ """<a target="_blank" href="#{stream.linkURL}">#{stream.source}</a>"""

    events:
      click: ->
        if not this.isPlaying
          this.play()

      'click .controls-wrapper': (e) ->
        e.stopPropagation()
        this.togglePause()

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
      duration = this.sound.durationEstimate or this.sound.duration
      soFar = (this.sound.position / duration)
      this.$progress.width(soFar * totalWidth)

    createSound: ->
      player.createSound
        id: uniqueId('sound')

        playerId: this.playerId
        width: 200
        height: 200

        url: this.model.streams.at(0).audioURL or this.model.streams.at(0).linkURL
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

  search = (searchString) ->
    qid = uniqueId('search')
    app.trigger 'songlocator:search', {qid, searchString}
    resolver.search(qid, searchString)

  resolve = (track, artist, album) ->
    qid = uniqueId('resolve')
    app.trigger 'songlocator:resolve', {qid, artist, track, album}
    resolver.resolve(qid, track, artist, album)

  player =

    createSound: (options) ->
      if /youtube.com/.test options.url
        youtubeManager.createSound(options)
      else
        soundManager.createSound(options)

  $ ->
    soundManager.setup(url: 'swf', debugMode: false)
    youtubeManager.setup()
    exports.app = app = new App()
    app.render()
    document.body.appendChild(app.el)

  extend exports, {
    App, SearchBox, ResultList, SongView,
    resolve, search, player, resolver
  }

  extend window, exports

  exports
