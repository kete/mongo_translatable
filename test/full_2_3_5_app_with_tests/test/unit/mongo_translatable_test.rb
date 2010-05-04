# -*- coding: utf-8 -*-
require 'test_helper'

class MongodbTranslatableTest < ActiveSupport::TestCase
  context "A translation" do
    setup do
      @item = Factory.create(:item)
      I18n.locale = I18n.default_locale
      item_hash = Hash.new
      item_hash[:label] = @item.attributes['label']
      item_hash[:locale] = :fr
      item_hash[@item.class.as_foreign_key_sym] = @item.id
      @translation = @item.class::Translation.create(item_hash)
    end

    should "have a locale" do
      if assert(@translation.respond_to?(:locale))
        assert @translation.locale
      end
    end

    should "have a translated object's translated attributes" do
      assert @translation.attributes[Item.translatable_attributes.first]
    end

    should "be accessable from its item" do
      if assert(@item.respond_to?(:translations))
        assert @item.translation_for(I18n.locale)
      end
    end

    should "be able to retrieve just the translated attribute" do
      if assert(@item.respond_to?(:translations) && @item.respond_to?(:label_translation_for))
        assert @item.label_translation_for(I18n.locale)
      end
    end

    should "be able to retrieve its item from the item's persistence" do
      assert @translation.translatable
    end
  end

  context "When there is an Item needing translating" do
    setup do
      @item = Factory.create(:item, { :label => LOCALE_LABELS[:en] })
    end

    should "create translation" do
      translate_item_for_locales(@item, :zh)
      assert @item.translations.count == 1
    end

    should "not create translation if no translated text submitted" do
      # arabic
      I18n.locale = :ar
      @item.translate
      assert @item.translations.count == 0
    end

    should "not create translation if item's original_locale is same as translation locale" do
      # arabic
      I18n.locale = :en
      @item.translate(:label => LOCALE_LABELS[:en])
      assert @item.translations.count == 0
    end

    should "create translation and it should reflect current locale" do
      # french
      translate_item_for_locales(@item, :fr)
      assert @item.translation_for(:fr)
    end

    should "find item with the proper translation for current locale" do
      translate_item_for_locales(@item, :fi)

      # reloading item should detect current locale and pass back translated version of object
      @item = Item.find(@item.id)

      assert_equal @item.label, LOCALE_LABELS[:fi]
    end

    should "find item with the proper translation for current locale when there is more than one translation" do
      # add a couple translations
      translate_item_for_locales(@item, [:fi, :fr])

      # then back to finnish
      I18n.locale = :fi

      # reloading item should detect current locale and pass back translated version of object
      @item = Item.find(@item.id)

      assert_equal @item.label, LOCALE_LABELS[:fi]
    end

    # test dynamic finder
    should "find item with the proper translation for current locale when there is more than one translation and finding using dynamic finder" do
      @item = Factory.create(:item, {:value => "a value"})

      # add a couple translations
      translate_item_for_locales(@item, [:fi, :fr])

      # then back to finnish
      I18n.locale = :fi

      # reloading item should detect current locale and pass back translated version of object
      @item = Item.find_by_value(@item.value)

      assert_equal @item.label, LOCALE_LABELS[:fi]
    end

    should "after creating translations, if the item is destroyed, the translations are destroyed" do
      # add a couple translations
      translate_item_for_locales(@item, [:fi, :fr])

      translations_ids = @item.translations.collect { |translation| translation.id }

      @item.destroy

      remaining_translations = Item::Translation.find(translations_ids)

      assert_equal 0, remaining_translations.size
    end

    should "when the item is destroyed, when it has no translations, it should succeed in being destroyed" do
      assert_equal 0, @item.translations.size
      assert @it
em.destroy
    end

    teardown do
      I18n.locale = @original_locale
    end
  end

  context "When there are many items being translated" do
    setup do
      # TODO: pull out this locale, not sure why before_save filter is not being called
      @original_locale = I18n.locale
    end

    should "find items with the proper translation for current locale" do
      ids = many_setup

      # reloading item should detect current locale and pass back translated version of object
      @items = Item.find(ids)

      many_tests
    end

    should "find items with the proper translation for current locale using dynamic finder" do
      value = "a value"
      many_setup({:value => value})

      # reloading item should detect current locale and pass back translated version of object
      @items = Item.find_all_by_value(value)

      many_tests(:fi => 10)
    end

    teardown do
      I18n.locale = @original_locale
    end
  end

  context "translations for an item" do
    setup do
      I18n.locale = I18n.default_locale
      @item = Factory.create(:item)
      @translation_keys = LOCALE_LABELS.keys - [:en]
      translate_item_for_locales(@item, @translation_keys)
    end

    should "be retrievable from translations method" do
      assert_equal @translation_keys.size, @item.translations.size
    end

    should "hae just locales be retrievable from translations_locales method" do
      # these should be partial objects and not have any values for other attributes
      locale_keys = @item.translations_locales.collect { |translation| translation.locale.to_sym if translation.label.nil? }.compact

      assert_equal 0, (@translation_keys - locale_keys).size
    end

    should "have translation locales plus original local be retrievable as available_in_these_locales" do
      locale_keys = @item.available_in_these_locales.collect { |locale| locale.to_sym }

      assert_equal 0, ( ([:en] + @translation_keys) - locale_keys ).size
    end

    should "have needed_in_these_locales method that returns locales that haven't been translated yet" do
      Item::Translation.first(:item_id => @item.id, :locale => "zh").destroy
      assert_equal [:zh], @item.needed_in_these_locales.collect { |locale| locale.to_sym }
    end
  end

  private

  # see many_tests for what it expects
  def many_setup(item_spec = nil)
    ids = Array.new
    5.times do
      I18n.locale = @original_locale
      item = item_spec ? Factory.create(:item, item_spec) : Factory.create(:item)
      translate_item_for_locales(item, [:ar, :fr])
      ids << item.id
    end

    5.times do
      I18n.locale = @original_locale
      item = item_spec ? Factory.create(:item, item_spec) : Factory.create(:item)
      translate_item_for_locales(item, [:zh, :fi])
      ids << item.id
    end

    # excluding these from ids searched
    5.times do
      I18n.locale = @original_locale
      item = item_spec ? Factory.create(:item, item_spec) : Factory.create(:item)
      translate_item_for_locales(item, [:fr, :fi])
    end

    I18n.locale = :fi
    ids
  end

  # expect 5 en, 5 finnish, and none in french, chinese, or arabic
  def many_tests(passed_amounts = { })
    results_number_for = { :fi => 5, :en => 5, :fr => 0, :ar => 0, :zh => 0}
    results_number_for.merge!(passed_amounts)

    assert_equal results_number_for[:fi], @items.select { |i| i.locale.to_sym == :fi }.size
    assert_equal results_number_for[:en], @items.select { |i| i.locale.to_sym == :en }.size
    assert_equal results_number_for[:fr], @items.select { |i| i.locale.to_sym == :fr }.size
    assert_equal results_number_for[:ar], @items.select { |i| i.locale.to_sym == :ar }.size
    assert_equal results_number_for[:zh], @items.select { |i| i.locale.to_sym == :zh }.size
  end
end
