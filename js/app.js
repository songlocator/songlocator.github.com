// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define('xmlhttprequest', {
  XMLHttpRequest: XMLHttpRequest
});

define(function(require, exports) {
  var ExfmResolver, ResolverSet, SoundCloudResolver, View, YouTubeResolver, extend, renderInPlace, soundManager, uniqueId, youtubeManager, _ref, _ref1;
  _ref = require('backbone.viewdsl'), View = _ref.View, renderInPlace = _ref.renderInPlace;
  _ref1 = require('underscore'), extend = _ref1.extend, uniqueId = _ref1.uniqueId;
  soundManager = require('soundmanager2');
  youtubeManager = require('youtubemanager');
  ResolverSet = require('songlocator-base').ResolverSet;
  YouTubeResolver = require('songlocator-youtube').Resolver;
  SoundCloudResolver = require('songlocator-tomahawk-soundcloud').Resolver;
  ExfmResolver = require('songlocator-tomahawk-exfm').Resolver;
  exports.resolver = new ResolverSet(new YouTubeResolver(), new SoundCloudResolver(), new ExfmResolver());
  exports.App = (function(_super) {

    __extends(App, _super);

    function App() {
      return App.__super__.constructor.apply(this, arguments);
    }

    App.prototype.className = 'app';

    App.prototype.parameterizable = true;

    App.prototype.template = "<article>\n  <view name=\"app:SearchBox\"></view>\n  <view name=\"app:ResultList\"></view>\n</article>\n\n<footer>\n  <div>\n    <h3>SongLocator</h3>\n    <p class=\"feedback\">\n      Have any feedback? Send me a <a\n          target=\"_blank\"\n          href=\"https://twitter.com/share?related=SongLocatorWeb&text=@SongLocatorWeb\"\n          class=\"twitter-share-button\"\n          data-lang=\"en\">tweet</a> or an\n      <a href=\"mailto:8mayday+songlocator@gmail.com\">email</a> message\n    </p>\n  </div>\n</footer>";

    return App;

  })(View);
  exports.SearchBox = (function(_super) {

    __extends(SearchBox, _super);

    function SearchBox() {
      return SearchBox.__super__.constructor.apply(this, arguments);
    }

    SearchBox.prototype.tagName = 'input';

    SearchBox.prototype.className = 'search-box';

    SearchBox.prototype.attributes = {
      name: 'query',
      type: 'text',
      placeholder: 'Search a song...'
    };

    SearchBox.prototype.events = {
      keypress: function(e) {
        var searchString;
        if (e.keyCode !== 13) {
          return;
        }
        searchString = this.$el.val().trim();
        if (!searchString) {
          return;
        }
        return search(searchString);
      }
    };

    return SearchBox;

  })(View);
  exports.ResultList = (function(_super) {

    __extends(ResultList, _super);

    function ResultList() {
      return ResultList.__super__.constructor.apply(this, arguments);
    }

    ResultList.prototype.tagName = 'ul';

    ResultList.prototype.className = 'results';

    ResultList.prototype.initialize = function() {
      var _this = this;
      resolver.on('results', function(result) {
        var r, _i, _len, _ref2, _results;
        if (result.qid !== _this.qid) {
          return;
        }
        _ref2 = result.results;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          r = _ref2[_i];
          _results.push(_this.renderResult(r));
        }
        return _results;
      });
      return app.on('songlocator:search songlocator:resolve', function(qid) {
        return _this.reset(qid);
      });
    };

    ResultList.prototype.renderResult = function(result) {
      return this.renderDOM("<li>\n  <view name=\"app:SongView\" model=\"result\"></view>\n</li>", {
        result: result
      });
    };

    ResultList.prototype.reset = function(qid) {
      var v, _i, _len, _ref2;
      this.qid = qid;
      _ref2 = this.views;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        v = _ref2[_i];
        v.remove();
      }
      return this.$el.html('');
    };

    return ResultList;

  })(View);
  exports.SongView = (function(_super) {

    __extends(SongView, _super);

    function SongView() {
      return SongView.__super__.constructor.apply(this, arguments);
    }

    SongView.prototype.className = 'song';

    SongView.prototype.isPlaying = false;

    SongView.prototype.template = "<span class=\"source\">\n  <a target=\"_blank\" attr-href=\"model.linkUrl\">{{model.source}}</a>\n</span>\n<div class=\"metadata-line\">\n  <span class=\"track\">{{model.track}}</span>\n  <span class=\"artist\">{{model.artist}}</span>\n</div>\n<div element-id=\"$progress\" class=\"progress\"></div>\n<div element-id=\"$box\" class=\"box\">\n  <div class=\"cover-wrapper\">\n    <div element-id=\"$cover\"></div>\n  </div>\n  <div class=\"controls-wrapper\">\n    <i class=\"icon-play\"></i>\n    <i class=\"icon-pause\"></i>\n  </div>\n  <div class=\"metadata-wrapper\">\n    <div class=\"track\">{{model.track}}</div>\n    <div class=\"artist\">{{model.artist}}</div>\n  </div>\n</div>";

    SongView.prototype.events = {
      click: function() {
        if (!this.isPlaying) {
          return this.play();
        }
      },
      'click .controls-wrapper': function(e) {
        e.stopPropagation();
        return this.togglePause();
      }
    };

    SongView.prototype.initialize = function() {
      var _this = this;
      return app.on('songlocator:play', function(sound) {
        if (sound !== _this.sound) {
          return _this.stop();
        }
      });
    };

    SongView.prototype.play = function() {
      this.isPlaying = true;
      this.$el.addClass('playing');
      this.$el.addClass('openned');
      if (!this.sound) {
        this.sound = this.createSound();
      }
      this.sound.play();
      return app.trigger('songlocator:play', this.sound);
    };

    SongView.prototype.stop = function() {
      this.$progress.width(0);
      this.$el.removeClass('playing');
      this.$el.removeClass('openned');
      this.isPlaying = false;
      if (this.sound) {
        return this.sound.stop();
      }
    };

    SongView.prototype.resume = function() {
      this.isPlaying = true;
      this.$el.addClass('playing');
      return this.sound.resume();
    };

    SongView.prototype.pause = function() {
      this.isPlaying = false;
      this.$el.removeClass('playing');
      return this.sound.pause();
    };

    SongView.prototype.togglePause = function() {
      if (this.isPlaying) {
        return this.pause();
      } else {
        return this.resume();
      }
    };

    SongView.prototype.onPlaying = function() {
      var duration, soFar, totalWidth;
      totalWidth = this.$el.width();
      duration = this.sound.durationEstimate || this.sound.duration;
      soFar = this.sound.position / duration;
      return this.$progress.width(soFar * totalWidth);
    };

    SongView.prototype.createSound = function() {
      var _this = this;
      return player.createSound({
        id: uniqueId('sound'),
        playerId: this.playerId,
        width: 200,
        height: 200,
        url: this.model.url || this.model.linkUrl,
        whileplaying: function() {
          return _this.onPlaying();
        },
        onstop: function() {
          return _this.stop();
        },
        onfinish: function() {
          return _this.stop();
        }
      });
    };

    SongView.prototype.remove = function() {
      SongView.__super__.remove.apply(this, arguments);
      if (this.sound != null) {
        return this.sound.destruct();
      }
    };

    SongView.prototype.render = function() {
      var _this = this;
      return SongView.__super__.render.apply(this, arguments).then(function() {
        _this.playerId = uniqueId('cover');
        return _this.$cover.attr('id', _this.playerId);
      });
    };

    return SongView;

  })(View);
  exports.search = function(searchString) {
    var qid;
    qid = uniqueId('search');
    app.trigger('songlocator:search', qid, searchString);
    return resolver.search(qid, searchString);
  };
  exports.resolve = function(track, artist, album) {
    var qid;
    qid = uniqueId('resolve');
    app.trigger('songlocator:resolve', qid, artist, track, album);
    return resolver.resolve(qid, track, artist, album);
  };
  exports.player = {
    createSound: function(options) {
      if (/youtube.com/.test(options.url)) {
        return youtubeManager.createSound(options);
      } else {
        return soundManager.createSound(options);
      }
    }
  };
  $(function() {
    var app;
    soundManager.setup({
      url: 'swf',
      debugMode: false
    });
    youtubeManager.setup();
    exports.app = app = new exports.App();
    app.render();
    return document.body.appendChild(app.el);
  });
  extend(window, exports);
  return exports;
});
