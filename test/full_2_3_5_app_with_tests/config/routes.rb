ActionController::Routing::Routes.draw do |map|
  map.resources :items, :has_many => :translations
end
