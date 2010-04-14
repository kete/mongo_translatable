# -*- coding: utf-8 -*-
require 'test_helper'

class TranslationsHelperTest < ActionView::TestCase
  I18n.backend.store_translations :'en', {
    :items => {
      :form => {
        :label => "Label"
      }
    }
  }

  context "Helpers for translation" do
    setup do 
      @translatable = Factory.create(:item, :label => "a label")
      @translatable_class = Item
    end

    should "have avalailable_locales_for_options" do
      locale_options = [["Français", "fr"],
                        ["中文", "zh"],
                        ["Suomi", "fi"],
                        ["العربية", "ar"],
                        ["English", "en"]]
      assert_equal locale_options, available_locales_for_options
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
