# -*- coding: utf-8 -*-
require 'test_helper'
class TranslationTest < ActionController::IntegrationTest
  context "A translatable object" do
    include Webrat::HaveTagMatcher
    setup do
      @item = Factory.create(:item)
    end

    should "have links to locales needing translation on its show page" do
      visit "/en/items/1"
      assert_contain "Needs translating to"
      assert_have_tag "a", :href => "/en/items/1/translations/new?to_locale=zh", :content => "中文"
    end

    should "have passed in locale as hidden input on its new page" do
      visit "/en/items/1/translations/new?to_locale=fr"
      assert_have_tag "input", :type => "hidden", :value => "fr", :name => "item_translation[locale]"
    end

    should "have hidden input for locale with value of current I18n.locale" do
      visit "/fr/items/1/translations/new?to_locale=fr"
      assert_have_tag "input", :type => "hidden", :value => "fr", :name => "item_translation[locale]"
    end

    should "be able to create a new locale following links from its show page" do
      visit "/en/items/1"
      click_link "Français"
      fill_in "item_translation_label", :with => LOCALE_LABELS[:fr]
      click_button "Create"
      assert_contain "Available in"
      # redirected show translated object in locale of translation added
      assert_have_tag "li", :content => "Français"
    end

    context "that has been previously translated" do 

      setup do
        translate_item_for_locales(@item, [:fr, :zh])
      end

      should "have locales that have been translated on its show page" do
        visit "/en/items/1"
        assert_have_tag "a", :href => "/fr/items/1", :content => "Français"
        assert_have_tag "a", :href => "/zh/items/1", :content => "中文"
      end

      should "have links to translated locales on its show page, which when followed change locale for object" do
        visit "/en/items/1"
        click_link "中文"
        assert_equal "zh", I18n.locale.to_s
        assert_contain "標籤"
      end

      should "be able to edit translation" do 
        visit "/en/items/1/translations/fr/edit"
        fill_in "item_translation_label", :with => "#{LOCALE_LABELS[:fr]} 2"
        click_button "Update"
      end
    end
  end
end
