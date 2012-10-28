Model = require 'models/base/model'

module.exports = class Header extends Model
  defaults:
    items: [
      {href: './test/', title: 'App Tests'},
      {href: '/', title: 'Home'},
      {href: '/facebook-posts', title: 'Your Facebook Posts', requiresLogin: true},
      {href: '/tweets', title: 'Your Tweets', requiresLogin: true}
    ]
