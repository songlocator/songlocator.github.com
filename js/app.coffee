require.config
  baseUrl: "js"
  paths:
    jquery: "../components/jquery/jquery"
    underscore: "../components/underscore/underscore"
    backbone: "../components/backbone/backbone"
    "backbone.viewdsl": "../components/backbone.viewdsl/backbone.viewdsl"
  shim:
    backbone:
      exports: "Backbone"
      deps: ["underscore", "jquery"]
    underscore:
      exports: "_"

define (require, exports) ->
  {View, renderInPlace} = require 'backbone.viewdsl'

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

  renderInPlace(document.body).done()

  exports
