# -*- coding: utf-8 -*-
require 'test_helper'

class TranslatablesHelperTest < ActionView::TestCase
  context "Helpers for translatables" do
    setup do
      I18n.locale = I18n.default_locale
      @item = Factory.create(:item, :label => "a label")
      @translatable_params_name = "item"

      def url_for_translated(options = { })
        @controller.url_for_translated(options.merge(
          :translated => @item,
          :translatable_params_name => @translatable_params_name
        ))
      end
    end

    # TODO: current request need to be in environment for this to run
    should "have provide available_in_locales_for that returns current translations for passed in item as list" do
      @item.translate(:label => 'une étiquette', :locale => 'fr').save
      html = "<ul><li><a href=\"/fr/items/1\">Français</li></ul>"
      assert_equal html, available_in_locales_for(@item)
    end

    should "have provide needed_in_locales_for that returns current locales that don't have a translation for passed in item as list" do
      locales = LOCALE_LABELS.keys - [:zh, :en]
      translate_item_for_locales(@item, locales)
      html = "<ul style='list-style:none; margin:0; padding:0;'>"
      html += "<li style='float:left;'>Needs translating to:</li>"
      html += "<li style=\"float: left; padding: 0 10px; \"><a href=\"/en/items/1/translations/new?to_locale=zh\">中文</a></li>"
      html += "</ul><div style='clear:both;'></div>"
      I18n.locale = I18n.default_locale
      assert_equal html, needed_in_locales_for(@item)
    end
  end
end
