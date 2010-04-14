ActionController::Routing::Routes.draw do |map|
  map.filter 'locale' # see routing-filter gem
  map.resources :items, :has_many => :translations
end
