utils = require 'lib/utils'
Chaplin = require 'chaplin'
ServiceProvider = require './service_provider'

# Shortcut to the mediator
mediator = Chaplin.mediator

module.exports = class Facebook extends ServiceProvider

  # Note: This is the ID for the TIMStest app. Change it later.
  facebookAppId = '361776557246197'

  scope = 'read_stream'

  name: 'facebook'

  # Login status at Facebook
  status: null

  # The current session API access token
  accessToken: null

  constructor: ->
    super

    utils.deferMethods
      deferred: this
      methods: [
        'parse', 'subscribe', 'postToGraph', 'getAccumulatedInfo', 'getInfo'
      ]
      onDeferral: @load

    # Bundle comment count calls into one request
    utils.wrapAccumulators this, ['getAccumulatedInfo']

    @subscribeEvent 'logout', @logout

  # Load the JavaScript library asynchronously
  load: ->
    return if @state() is 'resolved' or @loading
    @loading = true

    # Register load handler
    window.fbAsyncInit = @loadHandler

    # No success callback, there’s fbAsyncInit
    utils.loadLib '//connect.facebook.net/en_US/all.js', null, @reject

  # The main callback for the Facebook library
  loadHandler: =>
    @loading = false
    try
      # IE 8 throws an exception
      delete window.fbAsyncInit
    catch error
      window.fbAsyncInit = undefined

    @registerHandlers()

    FB.init
      appId:  facebookAppId
      status: true
      cookie: true
      xfbml:  false

    # Resolve the Deferred
    @resolve()

  # Register handlers for several events
  registerHandlers: ->
    @subscribe 'auth.logout', @facebookLogout # Logout on the Facebook side
    @subscribe 'edge.create', @processLike # Creating of likes
    @subscribe 'comment.create', @processComment # Creating of comments

  unregisterHandlers: ->
    @unsubscribe 'auth.logout', @facebookLogout
    @unsubscribe 'edge.create', @processLike
    @unsubscribe 'comment.create', @processComment

  # Check whether the Facebook library has been loaded
  isLoaded: ->
    Boolean window.FB and FB.login

  # Save the current login status and the access token
  # (if logged in and connected with app)
  saveAuthResponse: (response) =>
    @status = response.status
    authResponse = response.authResponse
    if authResponse
      @accessToken = authResponse.accessToken
    else
      @accessToken = null

  # Get the Facebook login status, delegates to FB.getLoginStatus
  #
  # This actually determines a) whether the user is logged in at Facebook
  # and b) whether the user has authorized the app
  getLoginStatus: (callback = @loginStatusHandler, force = false) =>
    FB.getLoginStatus callback, force

  # Callback for the initial FB.getLoginStatus call
  loginStatusHandler: (response) =>
    @saveAuthResponse response
    authResponse = response.authResponse
    if authResponse
      @publishSession authResponse
      @getUserData()
    else
      # TODO: Don’t do this if several providers are used
      # This is only necessary if Facebook is he only provider
      mediator.publish 'logout'

  # Open the Facebook login popup
  # loginContext: object with context information where the
  # user triggered the login
  #   Attributes:
  #   description - string
  #   model - optional model e.g. a topic the user wants to subscribe to
  triggerLogin: (loginContext) =>
    FB.login _(@loginHandler).bind(this, loginContext), {scope}

  # Callback for FB.login
  loginHandler: (loginContext, response) =>
    @saveAuthResponse response
    authResponse = response.authResponse

    eventPayload = {provider: this, loginContext}
    if authResponse
      mediator.publish 'loginSuccessful', eventPayload
      @publishSession authResponse
      @getUserData()

    else
      mediator.publish 'loginAbort', eventPayload

      # Get the login status again (forced) because the user might be
      # logged in anyway. This might happen when the user grants access
      # to the app but closes the second page of the auth dialog which
      # asks for Extended Permissions.
      loginStatusHandler = _(@loginStatusAfterAbort).bind this, loginContext
      @getLoginStatus loginStatusHandler, true

  # After abort, check login status and publish success or failure
  loginStatusAfterAbort: (loginContext, response) =>
    @saveAuthResponse response
    authResponse = response.authResponse

    eventPayload = {provider: this, loginContext}
    if authResponse
      mediator.publish 'loginSuccessful', eventPayload
      @publishSession authResponse

    else
      # Login failed ultimately
      mediator.publish 'loginFail', eventPayload

  # Publish the Facebook session
  publishSession: (authResponse) ->
    mediator.publish 'serviceProviderSession',
      provider: this
      userId: authResponse.userID
      accessToken: authResponse.accessToken

  # Handler for the FB auth.logout event
  facebookLogout: (response) =>
    # The Facebook library fires bogus auth.logout events even when the user
    # is logged in. So just overwrite the current status.
    @saveAuthResponse response

  # Handler for the global logout event
  logout: ->
    # Clear the status properties
    @status = @accessToken = null

  # Handlers for like and comment events
  # ------------------------------------

  processLike: (url) ->
    mediator.publish 'facebook:like', url

  processComment: (comment) ->
    mediator.publish 'facebook:comment', comment.href

  # Parsing of Facebook social plugins
  # ----------------------------------

  parse: (el) ->
    FB.XFBML.parse el

  # Helper for subscribing to Facebook events
  # -----------------------------------------

  subscribe: (eventType, handler) ->
    FB.Event.subscribe eventType, handler

  unsubscribe: (eventType, handler) ->
    FB.Event.unsubscribe eventType, handler

  # Graph Querying
  # --------------

  # Deferred wrapper for posting to the open graph
  postToGraph: (ogResource, data, callback) ->
    FB.api ogResource, 'post', data, (response) ->
      callback response if callback

  # Get the info for the given URLs
  # Pass a string or an array of strings along with a callback function
  getAccumulatedInfo: (urls, callback) ->
    urls = [urls] if typeof urls == 'string'
    # Reduce to a comma-separated, string to embed into the query string
    urls = _(urls).reduce((memo, url) ->
      memo += ',' if memo
      memo += encodeURIComponent(url)
    , '')
    FB.api "?ids=#{urls}", callback

  # Get information for node in the FB graph
  # `id` might be a FB node ID or a normal URL
  getInfo: (id, callback) ->
    FB.api id, callback

  # Fetch additional user data from Facebook
  # ----------------------------------------

  getUserData: ->
    @getInfo '/me', @processUserData

  processUserData: (response) =>
    mediator.publish 'userData', response

  # Disposal
  # --------

  dispose: ->
    return if @disposed
    @unregisterHandlers()
    # Clear the status properties
    delete @status
    delete @accessToken
    super
