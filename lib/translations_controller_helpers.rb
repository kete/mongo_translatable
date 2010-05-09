module TranslationsControllerHelpers
  unless included_modules.include? TranslationsControllerHelpers
    def self.included(klass)
      klass.send :helper_method, :url_for_translated, :target_action
    end
    
    def target_action(options)
      options.delete(:action) || 'show'
    end

    def url_for_translated(options = { })
      translated = options.delete(:translated) || @translated || @translatable
      translatable_params_name = options.delete(:translatable_params_name) || @translatable_params_name
      target_action = target_action(options)

      defaults = { :id => translated,
        :action => target_action,
        :controller => translatable_params_name.pluralize }
      url_for(defaults.merge(options))
    end
  end
end
