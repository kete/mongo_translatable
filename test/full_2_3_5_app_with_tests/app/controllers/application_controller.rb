# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  # borrowed from kete application (http://github.com/kete/kete)
  # modified to not rely only on mongo_translatable helpers
  before_filter :set_locale
  # first take the locale in the url, then the session[:locale],
  # then the users locale, finally the default site locale
  def set_locale
    if params[:locale] && TranslationsHelper.available_locales.include?(params[:locale])
      I18n.locale = params[:locale]
    elsif session[:locale] && TranslationsHelper.available_locales.include?(session[:locale])
      I18n.locale = session[:locale]
    else
      I18n.locale = I18n.default_locale
    end
    session[:locale] = I18n.locale # need to make sure this persists
  end
end
