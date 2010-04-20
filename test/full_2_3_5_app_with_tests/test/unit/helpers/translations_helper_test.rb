# -*- coding: utf-8 -*-
require 'test_helper'

class TranslationsHelperTest < ActionView::TestCase
  context "Helpers for translation" do
    setup do 
      I18n.locale = I18n.default_locale
      @translatable = Factory.create(:item, :label => "a label")
      @translatable_class = Item
      @translatable_key = :item_id
      @translatable_params_name = "item"
    end

    should "have avalailable_locales_for_options" do
      locale_options = [["Français", "fr"],
                        ["中文", "zh"],
                        ["Suomi", "fi"],
                        ["العربية", "ar"],
                        ["English", "en"]]
      assert_equal locale_options, available_locales_for_options
    end

    should "have provide available_in_locales that returns current translations for @translatable as list" do
      @translatable.translate(:label => 'une étiquette', :locale => 'fr')
      html = "<ul><li><a href=\"/fr/items/1\">Français</li></ul>"
      assert_equal html, available_in_locales
    end

    should "have provide needed_in_locales that returns current locales that don't have a translation for @translatable as list" do
      locales = LOCALE_LABELS.keys - [:zh, :en]
      translate_item_for_locales(@translatable, locales)
      html = "<ul><li><a href=\"/en/items/1/translations/new?to_locale=zh\">中文</a></li></ul>"
      I18n.locale = I18n.default_locale
      assert_equal html, needed_in_locales
    end

    # this method is defined in the controller
    # and made available to views via a helper_method :url_for_translated
    # see top of lib/mongo_translatable.rb
    should "take instance variables and create a url_for translated object's show action" do
      assert_equal "/en/items/1", url_for_translated
    end

    should "take attribute_key and give localized label" do
      assert_equal "Label", localized_label_for(:label)
    end

    should "take translatable and output internationalized html to display the original text of the attributes" do
      array_with_hashes_of_translatable_attributes_with_internationalized_names = [{:localized_label => "Label", :value => "a label"}]
      assert_equal array_with_hashes_of_translatable_attributes_with_internationalized_names, untranslated_values_with_localized_labels
    end

    should "take translation and output internationalized html to display the translated text of the attributes" do
      @translatable.translate(:label => 'une étiquette', :locale => 'fr')
      @translation = @translatable.translation_for(:fr)
      array_with_hashes_of_translated_attributes_with_internationalized_names = [{:localized_label => "Label", :value => "une étiquette"}]
      assert_equal array_with_hashes_of_translated_attributes_with_internationalized_names, translated_values_with_localized_labels
    end
  end
end
