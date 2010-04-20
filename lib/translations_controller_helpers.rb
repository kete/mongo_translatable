module TranslationsControllerHelpers
  unless included_modules.include? TranslationsControllerHelpers
    def self.included(klass)
      klass.send :helper_method, :url_for_translated
    end
    def url_for_translated(options = { })
      translated = @translated || @translatable
      defaults = { :id => translated,
        :action => 'show',
        :controller => @translatable_params_name.pluralize }
      url_for(defaults.merge(options))
    end
  end
end
