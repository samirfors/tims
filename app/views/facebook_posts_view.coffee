CollectionView = require 'views/base/collection_view'
template = require 'views/templates/facebook_posts'

module.exports = class FacebookPostsView extends CollectionView

  # Save the template string in a prototype property.
  # This is overwritten with the compiled template function.
  # In the end you might want to used precompiled templates.
  template: template

  tagName: 'div' # This is not directly a list but contains a list
  id: 'posts'

  # Automatically append to the DOM on render
  container: '#content-container'

  # Append the item views to this element
  listSelector: 'ol'
  # Fallback content selector
  fallbackSelector: '.fallback'
  # Loading indicator selector
  loadingSelector: '.loading'

  initialize: ->
    super # Will render the list itself and all items
    @subscribeEvent 'loginStatus', @showHideLoginNote

  # The most important method a class derived from CollectionView
  # must overwrite.
  getView: (item) ->
    # Instantiate an item view
    new FacebookPostView model: item
