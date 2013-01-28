define (require, exports) ->

  {Events} = require 'backbone'
  {extend} = require 'underscore'

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

  exports
