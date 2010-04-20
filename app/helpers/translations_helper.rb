module TranslationsHelper
  # outputs a display of translatable attributes
  # internationalized, assumes translation key is made up of the following
  # @translatable.class.name.tablize (i.e. controller name for routing purposes)
  # .
  # form (i.e. template name used by new and edit actions in most cases for forms)
  # .
  # the_attribute_name (i.e. what the accessor method name is for attribute in question on the model)
  # expects @translatable var or @translated var
  # returns an array with a hash per attribute where the key is the label (internationalized)
  # and the value for the attribute
  mattr_accessor :available_locales
  @@available_locales ||= YAML.load(IO.read(File.join(RAILS_ROOT, 'config/locales.yml')))

  %w{untranslated translated}.each do |term|
    define_method(term + '_values_with_localized_labels') do
      set_original
      raise "No object supplied to translate." if @original.blank?

      raise "No matching translation available." if term == 'translated' && @translation.blank?

      values_with_localized_labels = Array.new

      @original.translatable_attributes.each do |attribute_key|
        value = term == 'untranslated' ? @original[attribute_key] : @translation[attribute_key]
        values_with_localized_labels << { :localized_label => localized_label_for(attribute_key),
          :value => value }
      end

      values_with_localized_labels
    end
  end

  def localized_label_for(attribute_key)
    t(@translatable_class.name.tableize + '.' + 'form' + '.' + attribute_key.to_s)
  end

  def available_locales_for_options
    @@available_locales.collect { |key,value| [value,key] }
  end

  def available_in_locales
    set_original
    list = @original.available_in_these_locales.collect do |locale|
      link_to_unless_current(TranslationsHelper::available_locales[locale], url_for_translated(:locale => locale))
    end
    list = '<ul>' + '<li>' + list.join('</li><li>') + '</li>' + '</ul>'
  end

  def needed_in_locales
    set_original
    list = @original.needed_in_these_locales.collect do |locale|
      link_to(TranslationsHelper::available_locales[locale],
              :action => :new,
              :controller => :translations,
              @translatable_key => @original,
              :to_locale => locale)
    end
    list = '<ul>' + '<li>' + list.join('</li><li>') + '</li>' + '</ul>'
  end
  
  private
  def set_original 
    @original ||= @translatable || @translated
  end
end
