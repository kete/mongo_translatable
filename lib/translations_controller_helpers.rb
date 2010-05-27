module TranslationsControllerHelpers
  unless included_modules.include? TranslationsControllerHelpers
    def self.included(klass)
      klass.send :helper_method, :url_for_translated, :target_action, :target_locale
    end

    def target_locale(options = {})
      translation = options.delete(:translation) || @translation
      options.delete(:locale) || (translation.locale if translation) || I18n.locale
    end

    def target_controller(options = {})
      translatable_params_name = options.delete(:translatable_params_name) || @translatable_params_name
      options.delete(:controller) || translatable_params_name.pluralize || params[:controller]
    end

    def target_action(options = {})
      options.delete(:action) || 'show'
    end

    def target_id(options = {})
      translated = options.delete(:translated) || @translated || options.delete(:translatable) || @translatable
      options.delete(:id) || translated
    end

    def url_for_translated(options = { })
      defaults = {
        :locale => target_locale(options),
        :controller => target_controller(options),
        :action => target_action(options),
        :id => target_id(options)
      }

      url_for(defaults.merge(options))
    end
  end
end
