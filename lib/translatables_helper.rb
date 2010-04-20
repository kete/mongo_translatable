module TranslatablesHelper
  def available_in_locales_for(translatable)
    list = translatable.available_in_these_locales.collect do |locale|
      link_to_unless_current(TranslationsHelper::available_locales[locale], url_for(:locale => locale))
    end
    list = '<ul>' + '<li>' + list.join('</li><li>') + '</li>' + '</ul>'
  end

  def needed_in_locales_for(translatable)
    translatable_key = translatable.class.name.tableize.singularize + '_id'
    list = translatable.needed_in_these_locales.collect do |locale|
      link_to(TranslationsHelper::available_locales[locale],
              :action => :new,
              :controller => :translations,
              translatable_key => translatable,
              :to_locale => locale)
    end
    list = '<ul>' + '<li>' + list.join('</li><li>') + '</li>' + '</ul>'
  end
end
