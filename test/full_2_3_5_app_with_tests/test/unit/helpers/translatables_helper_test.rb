# -*- coding: utf-8 -*-
require 'test_helper'

class TranslatablesHelperTest < ActionView::TestCase
  context "Helpers for translatables" do
    setup do 
      I18n.locale = I18n.default_locale
      @item = Factory.create(:item, :label => "a label")
    end

    # TODO: current request need to be in environment for this to run
    should "have provide available_in_locales_for that returns current translations for passed in item as list" do
      @item.translate(:label => 'une étiquette', :locale => 'fr')
      html = "<ul><li><a href=\"/fr/items/1\">Français</li></ul>"
      assert_equal html, available_in_locales_for(@item)
    end

    should "have provide needed_in_locales_for that returns current locales that don't have a translation for passed in item as list" do
      locales = LOCALE_LABELS.keys - [:zh, :en]
      translate_item_for_locales(@item, locales)
      html = "<ul><li><a href=\"/en/items/1/translations/new?to_locale=zh\">中文</a></li></ul>"
      I18n.locale = I18n.default_locale
      assert_equal html, needed_in_locales_for(@item)
    end
  end
end
