Collection = require 'models/base/collection'
FacebookPosts = require 'models/facebook_posts'
FacebookPosts = require 'models/facebook_posts'

describe 'FacebookPosts', ->
  beforeEach ->
    @model = new FacebookPosts()
    @collection = new FacebookPosts()

  afterEach ->
    @model.dispose()
    @collection.dispose()
