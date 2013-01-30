{
  "name": "../components/almond/almond",
  "include": "app",
  "out": "js/app.build.js",
  "insertRequire": ["app"],
  "optimize": "none",
  "baseUrl": "js",
  "paths": {
    "jquery": "../components/jquery/jquery",
    "underscore": "../components/underscore/underscore",
    "backbone": "../components/backbone/backbone",
    "backbone.viewdsl": "../components/backbone.viewdsl/backbone.viewdsl",
    "soundmanager2": "../components/soundmanager/script/soundmanager2",
    "youtubemanager": "../components/youtubemanager/lib/youtubemanager",
    'songlocator-base': "../components/songlocator/lib/amd/songlocator-base",
    'songlocator-youtube': "../components/songlocator/lib/amd/songlocator-youtube"
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
