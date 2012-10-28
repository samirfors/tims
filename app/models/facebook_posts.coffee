mediator = require 'mediator'
Chaplin = require 'chaplin'
Collection = require 'models/base/collection'
FacebookPost = require 'models/facebook_post'

module.exports = class FacebookPosts extends Collection
  # Mixin a synchronization state machine
  _(@prototype).extend Chaplin.SyncMachine

  model: FacebookPost

  initialize: ->
    super

    @subscribeEvent 'login', @fetch
    @subscribeEvent 'logout', @logout

    @fetch()

  # Custom fetch function since the Facebook graph is not
  # a REST/JSON API which might be accessed using Ajax
  fetch: =>
    #console.debug 'Posts#fetch'

    user = mediator.user
    return unless user

    facebook = user.get 'provider'
    return unless facebook.name is 'facebook'

    # Switch to syncing state
    @beginSync()

    facebook.getInfo '/me/feed', @processPosts

  processPosts: (response) =>
    #console.debug 'Posts#processPosts', response, response.data
    return if @disposed

    posts = if response and response.data then response.data else []

    # Update the collection
    @reset posts

    # Switch to synced state
    @finishSync()

  # Handler for the global logout event
  logout: =>
    # Empty the collection
    @reset()

    # Return to unsynced state
    @unsync()
