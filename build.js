{
  "name": "../components/almond/almond",
  "include": "app",
  "out": "js/app.build.js",
  "insertRequire": ["app"],
  "optimize": "uglify",
  "uglify": {
    "ascii_only": true,
  },
  "baseUrl": "js",
  "paths": {
    "jquery": "../components/jquery/jquery",
    "underscore": "../components/underscore/underscore",
    "backbone": "../components/backbone/backbone",
    "backbone.record": "../components/backbone.record/backbone.record",
    "backbone.viewdsl": "../components/backbone.viewdsl/backbone.viewdsl",
    "soundmanager2": "../components/soundmanager/script/soundmanager2",
    "youtubemanager": "../components/youtubemanager/lib/youtubemanager",
    'songlocator-base': "../components/songlocator/lib/amd/songlocator-base",
    'songlocator-youtube': "../components/songlocator/lib/amd/songlocator-youtube",
    'songlocator-soundcloud': "../components/songlocator/lib/amd/songlocator-soundcloud",
    'songlocator-exfm': "../components/songlocator/lib/amd/songlocator-exfm",
    "songlocator-tomahawk-shim": "../components/songlocator-tomahawk/lib/amd/songlocator-tomahawk-shim"
  },
  "shim": {
    "backbone": {
      "exports": "Backbone",
      "deps": ["underscore", "jquery"]
    },
    "underscore": {
      "exports": "_"
    },
    "soundmanager2": {
      "exports": "soundManager"
    }
  }
}
