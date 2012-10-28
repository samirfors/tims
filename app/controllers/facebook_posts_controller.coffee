Controller = require 'controllers/base/controller'
FacebookPosts = require 'models/facebook_posts'
FacebookPostsView = require 'views/facebook_posts_view'

module.exports = class FacebookPostsController extends Controller
  history: 'facebook-posts'
  title: 'Facebook Wall Posts'

  index: (params) ->
    @posts = new FacebookPosts()
    @view = new FacebookPostsView collection: @posts
