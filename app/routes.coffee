module.exports = (match) ->
  match '', 'home#index'
  match 'likes/:id', 'likes#show'
  match 'facebook-posts', 'facebook_posts#index'
  match 'tweets', 'tweets#index'
