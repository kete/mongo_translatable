# -*- coding: utf-8 -*-
require "active_record"
require "mongo_mapper"

ActionController::Base.send(:include, TranslationsControllerHelpers)
ActionController::Base.send(:helper, TranslatablesHelper)

# load our locales
I18n.load_path += Dir[ File.join(File.dirname(__FILE__), '..', 'config', 'locales', '*.{rb,yml}') ]

module MongoTranslatable #:nodoc:
  # MongoTranslatable is for taking advantage of MongoDB for storing translations
  # of ActiveRecord models. Here is how it works in practice:
  #   class Item < ActiveRecord::Base
  #     mongo_translate :label
  #   end
  #
  #   I18n.locale = :en
  #
  #   item = Item.create(:label => "a label")
  #   p item.locale
  #   "en"
  #
  #   item = Item.find(1)
  #   p item.label
  #   "a label"
  #
  #   item.translate(:label => "etiketissä", :locale => :fi).save
  ## or you could have set I18n.locale = :fi in calling env and dropped locale from args
  #
  #   I18n.locale = :fi
  #   item = Item.find(1)
  #   p item.label
  #   "etiketissä"
  #   p item.locale
  #   "fi"
  #
  # If
  # The general approach is inspired by this code in globalize2:
  # http://github.com/joshmh/globalize2/blob/master/lib/globalize/active_record.rb
  # grab what the normal finder would return
  # and look up corresponding translated version of the objects in question
  # swap in corresponding translated attributes of object
  # creates TranslatableClass::Translation when the declaration method is defined
  # ala acts_as_versioned VersionedClass::Version
  # every translatable class gets their own Translation class under it
  #
  # TODO: translations aren't real associations
  # and the translations method is thus not chainable as you would expect
  # currently investigating adding a plugin for mongo_mapper that will do associations declaired
  # from activerecord models
  # in the meantime, you will like want to use the "translation_for(locale)" method
  module Translated
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def mongo_translate(*args)
        # don't allow multiple calls
        return if self.included_modules.include?(MongoTranslatable::Translated::InstanceMethods)

        send :include, MongoTranslatable::Translated::InstanceMethods

        options = args.last.is_a?(Hash) ? args.pop : Hash.new
        redefine_find = !options[:redefine_find].nil? ? options[:redefine_find] : true

        translatable_attributes = args.is_a?(Array) ? args : [args]

        cattr_accessor :translatable_attributes, :as_foreign_key_sym

        # expects a single attribute name symbol or array of attribute names as symbols
        self.translatable_attributes = translatable_attributes
        self.as_foreign_key_sym = self.name.foreign_key.to_sym

        before_save :set_locale_if_necessary
        before_destroy :destroy_translations

        # create the dynamic translation model
        const_set("Translation", Class.new).class_eval do
          include MongoMapper::Document

          cattr_accessor :translatable_class
          self.translatable_class = self.name.split('::').first.constantize

          def self.declare_key_from(spec)
            key_type = String
            key_name = spec

            key_name, key_type = spec if spec.is_a?(Array)

            unless keys.include?(key_name.to_s)
              class_eval do
                key key_name, key_type
              end
            end
          end

          self.translatable_class.translatable_attributes.each { |a| declare_key_from(a) }

          key :locale, String, :required => true

          before_save :locale_to_string

          # for classes that have dynamic translatable_attributes
          # add definition of keys for mongo_translatable Translation class, if not already defined
          # add accessor methods, too, if not already defined
          def self.update_keys_if_necessary_with(new_translatable_attributes)
            attribute_type = String

            new_translatable_attributes.each { |a| declare_key_from(a) }
          end

          # TODO: add validation for locale unique to translatable_class.as_foreign_key_sym scope
          # not implemented in mongo mapper yet

          def translatable
            self.translatable_class.find(self.send(self.translatable_class.as_foreign_key_sym))
          end

          protected
          # always store string version of locale (rather than symbol)
          def locale_to_string
            self.locale = self.locale.to_s
          end
        end

        class_eval do

          # dynamically define translation accessor methods
          def self.define_translation_accessor_method_for(attribute_name)
            # create the template code
            code = Proc.new { |locale|
              translation = translation_for(locale)
              translation.send(attribute_name.to_sym) if translation
            }

            define_method(attribute_name.to_s + "_translation_for", &code)
          end

          # define convenience method for each translatable_attribute
          # uses class method, see class method definitions
          translatable_attributes.each do |attribute|
            define_translation_accessor_method_for(attribute)
          end

          # take a collection of this class
          # and process translations accordingly
          def self.translatable_processing_of(results, *args)
            # at least for now, we skip :select queries
            # as we can't rely on having attributes available that we need
            # to compare against
            # we also return if results are nil
            return results if (args.is_a?(Array) &&
                               args.last.is_a?(Hash) &&
                               args.last.keys.include?(:select) &&
                               !args.last[:select].nil?) || results.nil?

            # handle single record
            if results.is_a?(self)
              result = results
              results = swap_in_translation_for_single(result)
            else
              # handle multiple records
              results = swap_in_translation_for_multiple(results)
            end
          end

          # does the actual swapping of translatable_attributes for a result
          def self.swap_in_translation_for_single(result)
            # only look up translation if the required locale is not the default for the record
            if result.present? && result.locale != I18n.locale.to_s
              # look up translation and swap in its attributes for result
              translated = result.translation_for(I18n.locale)
              if translated.present?
                result.translatable_attributes.each do |translated_attribute|
                  unless translated.attributes[translated_attribute].blank?
                    result.set_translation_for_this(translated_attribute, translated.attributes[translated_attribute])
                  end
                end
                result.locale = translated.locale
              end
            end

            result
          end

          # does the actual swapping of translatable_attributes per result
          # and returns new collection of translated results
          def self.swap_in_translation_for_multiple(results)
            # do second query of translations
            # if item locale is different than current locale
            # swap in attributse from translation for item that is current locale

            # rather than rerun the full query, simply get ids and add locale
            result_ids = results.collect(&:id)

            conditions = {:locale => I18n.locale.to_s}
            conditions[as_foreign_key_sym] = result_ids

            translations = self::Translation.all(conditions)

            translated_results = results
            index = 0
            results.each do |result|
              unless result.locale == I18n.locale.to_s
                matching_translation = translations.select { |t| t[as_foreign_key_sym] == result.id }.first

                if matching_translation
                  result.translatable_attributes.each do |key|
                    unless matching_translation.attributes[key].blank?
                      result.set_translation_for_this(key, matching_translation.attributes[key])
                    end
                  end

                  result.locale = I18n.locale.to_s

                  translated_results[index] = result
                end
              end
              index += 1
            end
            results = translated_results
          end

        end

        if redefine_find

          class_eval do
            # override find, this is called by all the dynamic finders
            # it isn't called by find_by_sql though (may be other exceptions)
            def self.find(*args)
              # get the standard results from find
              # this will throw a RecordNotFound before executing our code
              # if that is the response
              results = super(*args)

              results = translatable_processing_of(results, *args)
            end
          end
        end
      end
    end
    module InstanceMethods
      # for classes that have dynamice translatable attributes, we may need to update
      # accessor methods for a dynamic translatable attribute
      def update_translation_for_methods_if_necessary_with(new_translatable_attributes)
        new_translatable_attributes.each do |attribute|
          unless respond_to?("#{attribute.to_s}_translation_for".to_sym)
            self.class.define_translation_accessor_method_for(attribute)
          end
        end
      end

      # this will replace specified attribute with its translated value
      # taks an attribute name as a string or symbol
      def set_translation_for_this(attribute_name, translated_value)
        send(attribute_name.to_s + "=", translated_value)
      end

      def translations
        self.class::Translation.all(self.class.as_foreign_key_sym => id)
      end

      # sometimes all you need is only the locales of translations
      def translations_locales
        self.class::Translation.all(self.class.as_foreign_key_sym => id, :select => 'locale')
      end

      # get a list of locales as syms for all translations locales, plus object's original locale
      def available_in_these_locales
        [original_locale] + translations_locales.collect(&:locale)
      end

      # list of locales that haven't been translated yet
      def needed_in_these_locales
        TranslationsHelper::available_locales.keys - available_in_these_locales
      end

      # assumes unique locale
      def translation_for(locale)
        self.class::Translation.first(self.class.as_foreign_key_sym => id, :locale => locale)
      end

      # this will create a new translation (but won't save it)
      # with either passed in options
      # note that we don't save the changes to self
      # only the new translation
      # will return nothing if translate to locale
      # is the same as the object to translate's original locale
      def translate(options = {})
        translation_locale = options[:locale] || I18n.locale

        @translation = self.class::Translation.new({
          :locale => translation_locale,
          :translatable_locale => self.locale, # save original locale
          self.class.as_foreign_key_sym => id
        })

        if translation_locale.to_s == original_locale.to_s
          # TODO: locale's emptiness is the reported error
          # when this is triggered, figure out why
          # serving its purpose though to prevent a translation to be added for original_locale
          @translation.errors.replace(:locale, "Cannot add translation the same as the original locale.")
        else
          # work through self and replace attributes
          # with the passed in translations for defined translatable_attributes
          translatable_attributes.each do |translated_attribute|
            translated_value = options[translated_attribute]
            @translation.send("#{translated_attribute.to_sym}=", translated_value) if translated_value.present?
          end
        end

        @translation
      end

      protected
      # always store string version of locale (rather than symbol)
      # if none is specified, use environment's setting
      def set_locale_if_necessary
        self.locale = self.locale.present? ? self.locale : I18n.locale
        self.locale = self.locale.to_s
        self.original_locale = self.locale
      end

      def destroy_translations
        translations = self.class::Translation.all(self.class.as_foreign_key_sym => id)
        translations.each { |translation| translation.destroy }
      end
    end
  end
end

ActiveRecord::Base.class_eval { include MongoTranslatable::Translated }
