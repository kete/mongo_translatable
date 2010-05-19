module TranslationsControllerHelpers
  unless included_modules.include? TranslationsControllerHelpers
    def self.included(klass)
      klass.send :helper_method, :url_for_translated, :target_action, :target_locale
    end

    def target_action(options = {})
      options.delete(:action) || 'show'
    end

    def target_locale(options = {})
      options.delete(:locale) || (@translation.locale if @translation) || I18n.locale
    end

    def target_controller(options = {})
      options.delete(:controller) || options.delete(:translatable_params_name).pluralize
    end

    def target_id(options = {})
      options.delete(:id)
    end

    def url_for_translated(options = { })
      translated = options.delete(:translated) || @translated || @translatable
      translatable_params_name = options.delete(:translatable_params_name) || @translatable_params_name
      options[:translatable_params_name] = translatable_params_name
      options[:id] = translated

      defaults = {
        :locale => target_locale(options),
        :controller => target_controller(options),
        :action => target_action(options),
        :id => target_id
      }

      url_for(defaults.merge(options))
    end
  end
end
