module TranslationsControllerHelpers
  unless included_modules.include? TranslationsControllerHelpers
    def self.included(klass)
      klass.send :helper_method, :url_for_translated, :target_action
    end

    def target_action(options = {})
      options.delete(:action) || 'show'
    end

    def target_locale(options = {})
      options.delete(:locale) || (@translation.locale if @translation) || I18n.locale
    end

    def url_for_translated(options = { })
      translated = options.delete(:translated) || @translated || @translatable
      translatable_params_name = options.delete(:translatable_params_name) || @translatable_params_name

      defaults = {
        :locale => target_locale(options),
        :controller => translatable_params_name.pluralize,
        :action => target_action(options),
        :id => translated
      }

      url_for(defaults.merge(options))
    end
  end
end
