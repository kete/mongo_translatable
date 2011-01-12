# -*- coding: utf-8 -*-
require 'test_helper'

class MongodbTranslatableTest < ActiveSupport::TestCase
  context "A translation" do
    setup do
      I18n.locale = I18n.default_locale

      @item = Factory.create(:item)

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

    should "find item with the proper translation for current locale and fallback to original's value for translatable attribute that hasn't been translated" do
      translate_item_for_locales(@item, :fi)

      original_description = @item.description

      # reloading item should detect current locale and pass back translated version of object
      @item = Item.find(@item.id)

      assert_equal @item.label, LOCALE_LABELS[:fi]
      assert_equal original_description, @item.description
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
      assert @item.destroy
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

  context "A Translatable class that has a plural associated accessors (has_many) in another class through an association" do
    setup do
      I18n.locale = I18n.default_locale

      @person = Factory.create(:person)
      @item1 = Factory.create(:item, :person => @person)
      @item2 = Factory.create(:item, :person => @person)

      translate_item_for_locales(@item1, :fr)
    end

    should "get translated results from plural accessor" do
      I18n.locale = :fr
      results_with_one_translated_labels = [@item1.reload, @item2].collect(&:label)

      assert_equal results_with_one_translated_labels, @person.items.collect(&:label)
    end
  end

  context "A Translatable class that has a singular associated accessor (belongs_to, has_one) in another class through an association" do
    setup do
      I18n.locale = I18n.default_locale

      @item = Factory.create(:item, :person => @person)
      @comment = @item.comments.create(:subject => "usual mallarky")

      translate_item_for_locales(@item, :fr)
    end

    should "get translated results from singular accessor" do
      I18n.locale = :fr
      translated_label = Item.find(@item).label
      assert_equal translated_label, @comment.item.label
    end
  end

  context "A Translatable class that has redefine_find == false" do
    setup do
      I18n.locale = I18n.default_locale
      @record = Factory.create(:not_swapped_in_record)
      record_hash = Hash.new
      record_hash[:name] = @record.attributes['name']
      record_hash[:locale] = :fr
      record_hash[@record.class.as_foreign_key_sym] = @record.id
      @no_find_translation = @record.class::Translation.create(record_hash)
    end

    should "not swap out locale specific translation for record when loaded from a translated locale" do
      I18n.locale = :fr
      @record.reload
      assert_equal 'en', @record.locale
    end
  end

  context "A Translatable class that has some translatable_attributes with key_type specified" do

    should "have String for type of key without key_type specified (default)" do
      assert_equal Recipe::Translation.keys['name'].type, String
    end

    should "have Array for type of key when " do
      assert_equal Recipe::Translation.keys['steps'].type, Array
      assert_equal Recipe::Translation.keys['ingredients'].type, Array
    end
    
    context "can create translations that" do
      setup do
        I18n.locale = I18n.default_locale
        @recipe = Factory.create(:recipe)
      end
      
      should "return value in correct key type for translatable_attribute" do
        assert_equal @recipe.steps, ["steps1 - 1", "steps1 - 2"]
        assert_equal @recipe.ingredients, ["ingredients1 - 1", "ingredients1 - 2"]

        fr_steps = ['fr step 1', 'fr step 2']
        fr_ingredients = ['fr ingredient 1', 'fr ingredient 2']

        @recipe_translation = @recipe.class::Translation.create(:name => @recipe.attributes['name'],
                                                                :steps => fr_steps,
                                                                :ingredients => fr_ingredients,
                                                                :locale => :fr,
                                                                @recipe.class.as_foreign_key_sym => @recipe.id)

        @recipe_translation.reload
        
        assert_equal fr_steps, @recipe_translation.steps
        assert_equal fr_ingredients, @recipe_translation.ingredients
      end

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
